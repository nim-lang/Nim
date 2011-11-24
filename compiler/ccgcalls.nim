#
#
#           The Nimrod Compiler
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

type
  TAfterCallActions = tuple[p: BProc, actions: PRope]

proc fixupCall(p: BProc, t: PNode, d: var TLoc, pl: PRope) =
  var pl = pl
  var typ = t.sons[0].typ # getUniqueType() is too expensive here!
  if typ.sons[0] != nil:
    if isInvalidReturnType(typ.sons[0]):
      if sonsLen(t) > 1: app(pl, ", ")
      # beware of 'result = p(result)'. We always allocate a temporary:
      if d.k in {locTemp, locNone}:
        # We already got a temp. Great, special case it:
        if d.k == locNone: getTemp(p, typ.sons[0], d)
        app(pl, addrLoc(d))
        app(pl, ")")
        app(p.s[cpsStmts], pl)
        appf(p.s[cpsStmts], ";$n")
      else:
        var tmp: TLoc
        getTemp(p, typ.sons[0], tmp)
        app(pl, addrLoc(tmp))
        app(pl, ")")
        app(p.s[cpsStmts], pl)
        appf(p.s[cpsStmts], ";$n")
        genAssignment(p, d, tmp, {}) # no need for deep copying
    else:
      app(pl, ")")
      if d.k == locNone: getTemp(p, typ.sons[0], d)
      assert(d.t != nil)        # generate an assignment to d:
      var list: TLoc
      initLoc(list, locCall, nil, OnUnknown)
      list.r = pl
      genAssignment(p, d, list, {}) # no need for deep copying
  else:
    app(pl, ")")
    app(p.s[cpsStmts], pl)
    appf(p.s[cpsStmts], ";$n")

proc emitAfterCallActions(aca: TAfterCallActions) {.inline.} =
  app(aca.p.s[cpsStmts], aca.actions)

proc isInCurrentFrame(p: BProc, n: PNode): bool =
  # checks if `n` is an expression that refers to the current frame;
  # this does not work reliably because of forwarding + inlining can break it
  case n.kind
  of nkSym:
    if n.sym.kind in {skVar, skResult, skTemp} and p.prc != nil:
      result = p.prc.id == n.sym.owner.id
  of nkDotExpr, nkBracketExpr:
    if skipTypes(n.sons[0].typ, abstractInst).kind notin {tyVar,tyPtr,tyRef}:
      result = isInCurrentFrame(p, n.sons[0])
  of nkHiddenStdConv, nkHiddenSubConv, nkConv:
    result = isInCurrentFrame(p, n.sons[1])
  of nkHiddenDeref, nkDerefExpr:
    # what about: var x = addr(y); callAsOpenArray(x[])?
    # *shrug* ``addr`` is unsafe anyway.
    result = false
  of nkObjUpConv, nkObjDownConv, nkCheckedFieldExpr:
    result = isInCurrentFrame(p, n.sons[0])
  else: nil

proc genKeepAlive(aca: var TAfterCallActions, n: PNode, a: TLoc) {.inline.} =
  if a.s == onStack and optRefcGC in gGlobalOptions:
    aca.p.module.appcg(aca.actions,
                       "#nimKeepAlive((#TGenericSeq*)$1);$n", [a.rdLoc])

proc openArrayLoc(aca: var TAfterCallActions, n: PNode): PRope =
  var a: TLoc
  initLocExpr(aca.p, n, a)
  case skipTypes(a.t, abstractVar).kind
  of tyOpenArray:
    result = ropef("$1, $1Len0", [rdLoc(a)])
  of tyString, tySequence:
    result = ropef("$1->data, $1->$2", [a.rdLoc, lenField()])
    genKeepAlive(aca, n, a)
  of tyArray, tyArrayConstr:
    result = ropef("$1, $2", [rdLoc(a), toRope(lengthOrd(a.t))])
  else: InternalError("openArrayLoc: " & typeToString(a.t))

proc genArgStringToCString(aca: var TAfterCallActions, 
                           n: PNode): PRope {.inline.} =
  var a: TLoc
  initLocExpr(aca.p, n.sons[0], a)
  result = ropef("$1->data", [a.rdLoc])
  # we don't guarantee save string->cstring conversions anyway, so we use
  # an additional check to improve performance:
  if isInCurrentFrame(aca.p, n): genKeepAlive(aca, n, a)
  
proc genArg(aca: var TAfterCallActions, n: PNode, param: PSym): PRope =
  var a: TLoc
  if n.kind == nkStringToCString:
    result = genArgStringToCString(aca, n)
  elif skipTypes(param.typ, abstractVar).kind == tyOpenArray:
    var n = if n.kind != nkHiddenAddr: n else: n.sons[0]
    result = openArrayLoc(aca, n)
  elif ccgIntroducedPtr(param):
    initLocExpr(aca.p, n, a)
    result = addrLoc(a)
  else:
    initLocExpr(aca.p, n, a)
    result = rdLoc(a)

proc genArgNoParam(aca: var TAfterCallActions, n: PNode): PRope =
  var a: TLoc
  if n.kind == nkStringToCString:
    result = genArgStringToCString(aca, n)
  else:
    initLocExpr(aca.p, n, a)
    result = rdLoc(a)

proc genCall(p: BProc, t: PNode, d: var TLoc) =
  var op: TLoc
  var aca: TAfterCallActions
  aca.p = p
  # this is a hotspot in the compiler
  initLocExpr(p, t.sons[0], op)
  var pl = con(op.r, "(")
  var typ = t.sons[0].typ # getUniqueType() is too expensive here!
  assert(typ.kind == tyProc)
  var length = sonsLen(t)
  for i in countup(1, length - 1):
    assert(sonsLen(typ) == sonsLen(typ.n))
    if i < sonsLen(typ):
      assert(typ.n.sons[i].kind == nkSym)
      app(pl, genArg(aca, t.sons[i], typ.n.sons[i].sym))
    else:
      app(pl, genArgNoParam(aca, t.sons[i]))
    if i < length - 1: app(pl, ", ")
  fixupCall(p, t, d, pl)
  emitAfterCallActions(aca)

proc genInfixCall(p: BProc, t: PNode, d: var TLoc) =
  var op, a: TLoc
  var aca: TAfterCallActions
  aca.p = p
  initLocExpr(p, t.sons[0], op)
  var pl: PRope = nil
  var typ = t.sons[0].typ # getUniqueType() is too expensive here!
  assert(typ.kind == tyProc)
  var length = sonsLen(t)
  assert(sonsLen(typ) == sonsLen(typ.n))
  
  var param = typ.n.sons[1].sym
  app(pl, genArg(aca, t.sons[1], param))
  
  if skipTypes(param.typ, {tyGenericInst}).kind == tyPtr: app(pl, "->")
  else: app(pl, ".")
  app(pl, op.r)
  app(pl, "(")
  for i in countup(2, length - 1):
    assert(sonsLen(typ) == sonsLen(typ.n))
    if i < sonsLen(typ):
      assert(typ.n.sons[i].kind == nkSym)
      app(pl, genArg(aca, t.sons[i], typ.n.sons[i].sym))
    else:
      app(pl, genArgNoParam(aca, t.sons[i]))
    if i < length - 1: app(pl, ", ")
  fixupCall(p, t, d, pl)
  emitAfterCallActions(aca)

proc genNamedParamCall(p: BProc, t: PNode, d: var TLoc) =
  # generates a crappy ObjC call
  var op, a: TLoc
  var aca: TAfterCallActions
  aca.p = p
  initLocExpr(p, t.sons[0], op)
  var pl = toRope"["
  var typ = t.sons[0].typ # getUniqueType() is too expensive here!
  assert(typ.kind == tyProc)
  var length = sonsLen(t)
  assert(sonsLen(typ) == sonsLen(typ.n))
  
  if length > 1:
    app(pl, genArg(aca, t.sons[1], typ.n.sons[1].sym))
    app(pl, " ")
  app(pl, op.r)
  if length > 2:
    app(pl, ": ")
    app(pl, genArg(aca, t.sons[2], typ.n.sons[2].sym))
  for i in countup(3, length-1):
    assert(sonsLen(typ) == sonsLen(typ.n))
    if i >= sonsLen(typ):
      InternalError(t.info, "varargs for objective C method?")
    assert(typ.n.sons[i].kind == nkSym)
    var param = typ.n.sons[i].sym
    app(pl, " ")
    app(pl, param.name.s)
    app(pl, ": ")
    app(pl, genArg(aca, t.sons[i], param))
  if typ.sons[0] != nil:
    if isInvalidReturnType(typ.sons[0]):
      if sonsLen(t) > 1: app(pl, " ")
      # beware of 'result = p(result)'. We always allocate a temporary:
      if d.k in {locTemp, locNone}:
        # We already got a temp. Great, special case it:
        if d.k == locNone: getTemp(p, typ.sons[0], d)
        app(pl, "Result: ")
        app(pl, addrLoc(d))
        app(pl, "]")
        app(p.s[cpsStmts], pl)
        appf(p.s[cpsStmts], ";$n")
      else:
        var tmp: TLoc
        getTemp(p, typ.sons[0], tmp)
        app(pl, addrLoc(tmp))
        app(pl, "]")
        app(p.s[cpsStmts], pl)
        appf(p.s[cpsStmts], ";$n")
        genAssignment(p, d, tmp, {}) # no need for deep copying
    else:
      app(pl, "]")
      if d.k == locNone: getTemp(p, typ.sons[0], d)
      assert(d.t != nil)        # generate an assignment to d:
      var list: TLoc
      initLoc(list, locCall, nil, OnUnknown)
      list.r = pl
      genAssignment(p, d, list, {}) # no need for deep copying
  else:
    app(pl, "]")
    app(p.s[cpsStmts], pl)
    appf(p.s[cpsStmts], ";$n")
  emitAfterCallActions(aca)

