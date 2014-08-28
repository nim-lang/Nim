#
#
#           The Nim Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
#
# included from cgen.nim

proc leftAppearsOnRightSide(le, ri: PNode): bool =
  if le != nil:
    for i in 1 .. <ri.len:
      let r = ri[i]
      if isPartOf(le, r) != arNo: return true

proc hasNoInit(call: PNode): bool {.inline.} =
  result = call.sons[0].kind == nkSym and sfNoInit in call.sons[0].sym.flags

proc fixupCall(p: BProc, le, ri: PNode, d: var TLoc,
               callee, params: PRope) =
  var pl = con(callee, ~"(", params)
  # getUniqueType() is too expensive here:
  var typ = skipTypes(ri.sons[0].typ, abstractInst)
  if typ.sons[0] != nil:
    if isInvalidReturnType(typ.sons[0]):
      if params != nil: pl.app(~", ")
      # beware of 'result = p(result)'. We may need to allocate a temporary:
      if d.k in {locTemp, locNone} or not leftAppearsOnRightSide(le, ri):
        # Great, we can use 'd':
        if d.k == locNone: getTemp(p, typ.sons[0], d, needsInit=true)
        elif d.k notin {locExpr, locTemp} and not hasNoInit(ri):
          # reset before pass as 'result' var:
          resetLoc(p, d)
        app(pl, addrLoc(d))
        app(pl, ~");$n")
        line(p, cpsStmts, pl)
      else:
        var tmp: TLoc
        getTemp(p, typ.sons[0], tmp, needsInit=true)
        app(pl, addrLoc(tmp))
        app(pl, ~");$n")
        line(p, cpsStmts, pl)
        genAssignment(p, d, tmp, {}) # no need for deep copying
    else:
      app(pl, ~")")
      if d.k == locNone: getTemp(p, typ.sons[0], d)
      assert(d.t != nil)        # generate an assignment to d:
      var list: TLoc
      initLoc(list, locCall, d.t, OnUnknown)
      list.r = pl
      genAssignment(p, d, list, {}) # no need for deep copying
  else:
    app(pl, ~");$n")
    line(p, cpsStmts, pl)

proc isInCurrentFrame(p: BProc, n: PNode): bool =
  # checks if `n` is an expression that refers to the current frame;
  # this does not work reliably because of forwarding + inlining can break it
  case n.kind
  of nkSym:
    if n.sym.kind in {skVar, skResult, skTemp, skLet} and p.prc != nil:
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
  else: discard

proc openArrayLoc(p: BProc, n: PNode): PRope =
  var a: TLoc

  let q = skipConv(n)
  if getMagic(q) == mSlice:
    # magic: pass slice to openArray:
    var b, c: TLoc
    initLocExpr(p, q[1], a)
    initLocExpr(p, q[2], b)
    initLocExpr(p, q[3], c)
    let fmt =
      case skipTypes(a.t, abstractVar+{tyPtr}).kind
      of tyOpenArray, tyVarargs, tyArray, tyArrayConstr:
        "($1)+($2), ($3)-($2)+1"
      of tyString, tySequence:
        if skipTypes(n.typ, abstractInst).kind == tyVar:
          "(*$1)->data+($2), ($3)-($2)+1"
        else:
          "$1->data+($2), ($3)-($2)+1"
      else: (internalError("openArrayLoc: " & typeToString(a.t)); "")
    result = ropef(fmt, [rdLoc(a), rdLoc(b), rdLoc(c)])
  else:
    initLocExpr(p, n, a)
    case skipTypes(a.t, abstractVar).kind
    of tyOpenArray, tyVarargs:
      result = ropef("$1, $1Len0", [rdLoc(a)])
    of tyString, tySequence:
      if skipTypes(n.typ, abstractInst).kind == tyVar:
        result = ropef("(*$1)->data, (*$1)->$2", [a.rdLoc, lenField()])
      else:
        result = ropef("$1->data, $1->$2", [a.rdLoc, lenField()])
    of tyArray, tyArrayConstr:
      result = ropef("$1, $2", [rdLoc(a), toRope(lengthOrd(a.t))])
    else: internalError("openArrayLoc: " & typeToString(a.t))

proc genArgStringToCString(p: BProc, 
                           n: PNode): PRope {.inline.} =
  var a: TLoc
  initLocExpr(p, n.sons[0], a)
  result = ropef("$1->data", [a.rdLoc])
  
proc genArg(p: BProc, n: PNode, param: PSym): PRope =
  var a: TLoc
  if n.kind == nkStringToCString:
    result = genArgStringToCString(p, n)
  elif skipTypes(param.typ, abstractVar).kind in {tyOpenArray, tyVarargs}:
    var n = if n.kind != nkHiddenAddr: n else: n.sons[0]
    result = openArrayLoc(p, n)
  elif ccgIntroducedPtr(param):
    initLocExpr(p, n, a)
    result = addrLoc(a)
  else:
    initLocExpr(p, n, a)
    result = rdLoc(a)

proc genArgNoParam(p: BProc, n: PNode): PRope =
  var a: TLoc
  if n.kind == nkStringToCString:
    result = genArgStringToCString(p, n)
  else:
    initLocExpr(p, n, a)
    result = rdLoc(a)

proc genPrefixCall(p: BProc, le, ri: PNode, d: var TLoc) =
  var op: TLoc
  # this is a hotspot in the compiler
  initLocExpr(p, ri.sons[0], op)
  var params: PRope
  # getUniqueType() is too expensive here:
  var typ = skipTypes(ri.sons[0].typ, abstractInst)
  assert(typ.kind == tyProc)
  assert(sonsLen(typ) == sonsLen(typ.n))
  var length = sonsLen(ri)
  for i in countup(1, length - 1):
    if ri.sons[i].typ.isCompileTimeOnly: continue
    if params != nil: app(params, ~", ")
    if i < sonsLen(typ):
      assert(typ.n.sons[i].kind == nkSym)
      app(params, genArg(p, ri.sons[i], typ.n.sons[i].sym))
    else:
      app(params, genArgNoParam(p, ri.sons[i]))
  fixupCall(p, le, ri, d, op.r, params)

proc genClosureCall(p: BProc, le, ri: PNode, d: var TLoc) =

  proc getRawProcType(p: BProc, t: PType): PRope =
    result = getClosureType(p.module, t, clHalf)

  proc addComma(r: PRope): PRope =
    result = if r == nil: r else: con(r, ~", ")

  const PatProc = "$1.ClEnv? $1.ClPrc($3$1.ClEnv):(($4)($1.ClPrc))($2)"
  const PatIter = "$1.ClPrc($3$1.ClEnv)" # we know the env exists
  var op: TLoc
  initLocExpr(p, ri.sons[0], op)
  var pl: PRope
  
  var typ = skipTypes(ri.sons[0].typ, abstractInst)
  assert(typ.kind == tyProc)
  var length = sonsLen(ri)
  for i in countup(1, length - 1):
    assert(sonsLen(typ) == sonsLen(typ.n))
    if i < sonsLen(typ):
      assert(typ.n.sons[i].kind == nkSym)
      app(pl, genArg(p, ri.sons[i], typ.n.sons[i].sym))
    else:
      app(pl, genArgNoParam(p, ri.sons[i]))
    if i < length - 1: app(pl, ~", ")
  
  template genCallPattern {.dirty.} =
    lineF(p, cpsStmts, callPattern & ";$n", op.r, pl, pl.addComma, rawProc)

  let rawProc = getRawProcType(p, typ)
  let callPattern = if tfIterator in typ.flags: PatIter else: PatProc
  if typ.sons[0] != nil:
    if isInvalidReturnType(typ.sons[0]):
      if sonsLen(ri) > 1: app(pl, ~", ")
      # beware of 'result = p(result)'. We may need to allocate a temporary:
      if d.k in {locTemp, locNone} or not leftAppearsOnRightSide(le, ri):
        # Great, we can use 'd':
        if d.k == locNone:
          getTemp(p, typ.sons[0], d, needsInit=true)
        elif d.k notin {locExpr, locTemp} and not hasNoInit(ri):
          # reset before pass as 'result' var:
          resetLoc(p, d)
        app(pl, addrLoc(d))
        genCallPattern()
      else:
        var tmp: TLoc
        getTemp(p, typ.sons[0], tmp, needsInit=true)
        app(pl, addrLoc(tmp))
        genCallPattern()
        genAssignment(p, d, tmp, {}) # no need for deep copying
    else:
      if d.k == locNone: getTemp(p, typ.sons[0], d)
      assert(d.t != nil)        # generate an assignment to d:
      var list: TLoc
      initLoc(list, locCall, d.t, OnUnknown)
      list.r = ropef(callPattern, op.r, pl, pl.addComma, rawProc)
      genAssignment(p, d, list, {}) # no need for deep copying
  else:
    genCallPattern()
  
proc genInfixCall(p: BProc, le, ri: PNode, d: var TLoc) =
  var op, a: TLoc
  initLocExpr(p, ri.sons[0], op)
  var pl: PRope = nil
  # getUniqueType() is too expensive here:
  var typ = skipTypes(ri.sons[0].typ, abstractInst)
  assert(typ.kind == tyProc)
  var length = sonsLen(ri)
  assert(sonsLen(typ) == sonsLen(typ.n))
  
  var param = typ.n.sons[1].sym
  app(pl, genArg(p, ri.sons[1], param))
  
  if skipTypes(param.typ, {tyGenericInst}).kind == tyPtr: app(pl, ~"->")
  else: app(pl, ~".")
  app(pl, op.r)
  var params: PRope
  for i in countup(2, length - 1):
    if params != nil: params.app(~", ")
    assert(sonsLen(typ) == sonsLen(typ.n))
    if i < sonsLen(typ):
      assert(typ.n.sons[i].kind == nkSym)
      app(params, genArg(p, ri.sons[i], typ.n.sons[i].sym))
    else:
      app(params, genArgNoParam(p, ri.sons[i]))
  fixupCall(p, le, ri, d, pl, params)

proc genNamedParamCall(p: BProc, ri: PNode, d: var TLoc) =
  # generates a crappy ObjC call
  var op, a: TLoc
  initLocExpr(p, ri.sons[0], op)
  var pl = ~"["
  # getUniqueType() is too expensive here:
  var typ = skipTypes(ri.sons[0].typ, abstractInst)
  assert(typ.kind == tyProc)
  var length = sonsLen(ri)
  assert(sonsLen(typ) == sonsLen(typ.n))
  
  if length > 1:
    app(pl, genArg(p, ri.sons[1], typ.n.sons[1].sym))
    app(pl, ~" ")
  app(pl, op.r)
  if length > 2:
    app(pl, ~": ")
    app(pl, genArg(p, ri.sons[2], typ.n.sons[2].sym))
  for i in countup(3, length-1):
    assert(sonsLen(typ) == sonsLen(typ.n))
    if i >= sonsLen(typ):
      internalError(ri.info, "varargs for objective C method?")
    assert(typ.n.sons[i].kind == nkSym)
    var param = typ.n.sons[i].sym
    app(pl, ~" ")
    app(pl, param.name.s)
    app(pl, ~": ")
    app(pl, genArg(p, ri.sons[i], param))
  if typ.sons[0] != nil:
    if isInvalidReturnType(typ.sons[0]):
      if sonsLen(ri) > 1: app(pl, ~" ")
      # beware of 'result = p(result)'. We always allocate a temporary:
      if d.k in {locTemp, locNone}:
        # We already got a temp. Great, special case it:
        if d.k == locNone: getTemp(p, typ.sons[0], d, needsInit=true)
        app(pl, ~"Result: ")
        app(pl, addrLoc(d))
        app(pl, ~"];$n")
        line(p, cpsStmts, pl)
      else:
        var tmp: TLoc
        getTemp(p, typ.sons[0], tmp, needsInit=true)
        app(pl, addrLoc(tmp))
        app(pl, ~"];$n")
        line(p, cpsStmts, pl)
        genAssignment(p, d, tmp, {}) # no need for deep copying
    else:
      app(pl, ~"]")
      if d.k == locNone: getTemp(p, typ.sons[0], d)
      assert(d.t != nil)        # generate an assignment to d:
      var list: TLoc
      initLoc(list, locCall, nil, OnUnknown)
      list.r = pl
      genAssignment(p, d, list, {}) # no need for deep copying
  else:
    app(pl, ~"];$n")
    line(p, cpsStmts, pl)

proc genCall(p: BProc, e: PNode, d: var TLoc) =
  if e.sons[0].typ.callConv == ccClosure:
    genClosureCall(p, nil, e, d)
  elif e.sons[0].kind == nkSym and sfInfixCall in e.sons[0].sym.flags and
      e.len >= 2:
    genInfixCall(p, nil, e, d)
  elif e.sons[0].kind == nkSym and sfNamedParamCall in e.sons[0].sym.flags:
    genNamedParamCall(p, e, d)
  else:
    genPrefixCall(p, nil, e, d)
  postStmtActions(p)
  when false:
    if d.s == onStack and containsGarbageCollectedRef(d.t): keepAlive(p, d)

proc genAsgnCall(p: BProc, le, ri: PNode, d: var TLoc) =
  if ri.sons[0].typ.callConv == ccClosure:
    genClosureCall(p, le, ri, d)
  elif ri.sons[0].kind == nkSym and sfInfixCall in ri.sons[0].sym.flags and
      ri.len >= 2:
    genInfixCall(p, le, ri, d)
  elif ri.sons[0].kind == nkSym and sfNamedParamCall in ri.sons[0].sym.flags:
    genNamedParamCall(p, ri, d)
  else:
    genPrefixCall(p, le, ri, d)
  postStmtActions(p)
  when false:
    if d.s == onStack and containsGarbageCollectedRef(d.t): keepAlive(p, d)

