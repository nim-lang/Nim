#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
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
      if p.module.compileToCpp and lfSingleUse in d.flags:
        # do not generate spurious temporaries for C++! For C we're better off
        # with them to prevent undefined behaviour and because the codegen
        # is free to emit expressions multiple times!
        d.k = locCall
        d.r = pl
        excl d.flags, lfSingleUse
      else:
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
        if skipTypes(n.typ, abstractInst).kind == tyVar and
            not compileToCpp(p.module):
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
      if skipTypes(n.typ, abstractInst).kind == tyVar and
            not compileToCpp(p.module):
        result = ropef("(*$1)->data, (*$1)->$2", [a.rdLoc, lenField(p)])
      else:
        result = ropef("$1->data, $1->$2", [a.rdLoc, lenField(p)])
    of tyArray, tyArrayConstr:
      result = ropef("$1, $2", [rdLoc(a), toRope(lengthOrd(a.t))])
    else: internalError("openArrayLoc: " & typeToString(a.t))

proc genArgStringToCString(p: BProc, n: PNode): PRope {.inline.} =
  var a: TLoc
  initLocExpr(p, n.sons[0], a)
  result = ropef("$1->data", [a.rdLoc])

proc genArg(p: BProc, n: PNode, param: PSym; call: PNode): PRope =
  var a: TLoc
  if n.kind == nkStringToCString:
    result = genArgStringToCString(p, n)
  elif skipTypes(param.typ, abstractVar).kind in {tyOpenArray, tyVarargs}:
    var n = if n.kind != nkHiddenAddr: n else: n.sons[0]
    result = openArrayLoc(p, n)
  elif ccgIntroducedPtr(param):
    initLocExpr(p, n, a)
    result = addrLoc(a)
  elif p.module.compileToCpp and param.typ.kind == tyVar and
      n.kind == nkHiddenAddr:
    initLocExprSingleUse(p, n.sons[0], a)
    # if the proc is 'importc'ed but not 'importcpp'ed then 'var T' still
    # means '*T'. See posix.nim for lots of examples that do that in the wild.
    let callee = call.sons[0]
    if callee.kind == nkSym and
        {sfImportC, sfInfixCall, sfCompilerProc} * callee.sym.flags == {sfImportC} and
        {lfHeader, lfNoDecl} * callee.sym.loc.flags != {}:
      result = addrLoc(a)
    else:
      result = rdLoc(a)
  else:
    initLocExprSingleUse(p, n, a)
    result = rdLoc(a)

proc genArgNoParam(p: BProc, n: PNode): PRope =
  var a: TLoc
  if n.kind == nkStringToCString:
    result = genArgStringToCString(p, n)
  else:
    initLocExprSingleUse(p, n, a)
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
      app(params, genArg(p, ri.sons[i], typ.n.sons[i].sym, ri))
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
    if ri.sons[i].typ.isCompileTimeOnly: continue
    if i < sonsLen(typ):
      assert(typ.n.sons[i].kind == nkSym)
      app(pl, genArg(p, ri.sons[i], typ.n.sons[i].sym, ri))
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

proc genOtherArg(p: BProc; ri: PNode; i: int; typ: PType): PRope =
  if ri.sons[i].typ.isCompileTimeOnly:
    result = nil
  elif i < sonsLen(typ):
    # 'var T' is 'T&' in C++. This means we ignore the request of
    # any nkHiddenAddr when it's a 'var T'.
    assert(typ.n.sons[i].kind == nkSym)
    if typ.sons[i].kind == tyVar and ri.sons[i].kind == nkHiddenAddr:
      result = genArgNoParam(p, ri.sons[i][0])
    else:
      result = genArgNoParam(p, ri.sons[i]) #, typ.n.sons[i].sym)
  else:
    result = genArgNoParam(p, ri.sons[i])

discard """
Dot call syntax in C++
======================

so c2nim translates 'this' sometimes to 'T' and sometimes to 'var T'
both of which are wrong, but often more convenient to use.
For manual wrappers it can also be 'ptr T'

Fortunately we know which parameter is the 'this' parameter and so can fix this
mess in the codegen.
now ... if the *argument* is a 'ptr' the codegen shall emit -> and otherwise .
but this only depends on the argument and not on how the 'this' was declared
however how the 'this' was declared affects whether we end up with
wrong 'addr' and '[]' ops...

Since I'm tired I'll enumerate all the cases here:

var
  x: ptr T
  y: T

proc t(x: T)
x[].t()  --> (*x).t()  is correct.
y.t()    --> y.t()  is correct

proc u(x: ptr T)
x.u()          --> needs to become  x->u()
(addr y).u()   --> needs to become  y.u()

proc v(x: var T)
--> first skip the implicit 'nkAddr' node
x[].v()        --> (*x).v()  is correct, but might have been eliminated due
                   to the nkAddr node! So for this case we need to generate '->'
y.v()          --> y.v() is correct

"""

proc genThisArg(p: BProc; ri: PNode; i: int; typ: PType): PRope =
  # for better or worse c2nim translates the 'this' argument to a 'var T'.
  # However manual wrappers may also use 'ptr T'. In any case we support both
  # for convenience.
  internalAssert i < sonsLen(typ)
  assert(typ.n.sons[i].kind == nkSym)
  # if the parameter is lying (tyVar) and thus we required an additional deref,
  # skip the deref:
  var ri = ri[i]
  while ri.kind == nkObjDownConv: ri = ri[0]
  if typ.sons[i].kind == tyVar:
    let x = if ri.kind == nkHiddenAddr: ri[0] else: ri
    if x.typ.kind == tyPtr:
      result = genArgNoParam(p, x)
      result.app("->")
    elif x.kind in {nkHiddenDeref, nkDerefExpr} and x[0].typ.kind == tyPtr:
      result = genArgNoParam(p, x[0])
      result.app("->")
    else:
      result = genArgNoParam(p, x)
      result.app(".")
  elif typ.sons[i].kind == tyPtr:
    if ri.kind in {nkAddr, nkHiddenAddr}:
      result = genArgNoParam(p, ri[0])
      result.app(".")
    else:
      result = genArgNoParam(p, ri)
      result.app("->")
  else:
    result = genArgNoParam(p, ri) #, typ.n.sons[i].sym)
    result.app(".")

proc genPatternCall(p: BProc; ri: PNode; pat: string; typ: PType): PRope =
  var i = 0
  var j = 1
  while i < pat.len:
    case pat[i]
    of '@':
      if j < ri.len:
        result.app genOtherArg(p, ri, j, typ)
        for k in j+1 .. < ri.len:
          result.app(~", ")
          result.app genOtherArg(p, ri, k, typ)
      inc i
    of '#':
      if pat[i+1] in {'+', '@'}:
        let ri = ri[j]
        if ri.kind in nkCallKinds:
          let typ = skipTypes(ri.sons[0].typ, abstractInst)
          if pat[i+1] == '+': result.app genArgNoParam(p, ri.sons[0])
          result.app(~"(")
          if 1 < ri.len:
            result.app genOtherArg(p, ri, 1, typ)
          for k in j+1 .. < ri.len:
            result.app(~", ")
            result.app genOtherArg(p, ri, k, typ)
          result.app(~")")
        else:
          localError(ri.info, "call expression expected for C++ pattern")
        inc i
      elif pat[i+1] == '.':
        result.app genThisArg(p, ri, j, typ)
        inc i
      else:
        result.app genOtherArg(p, ri, j, typ)
      inc j
      inc i
    of '\'':
      inc i
      let stars = i
      while pat[i] == '*': inc i
      if pat[i] in Digits:
        let j = pat[i].ord - '0'.ord
        var t = typ.sons[j]
        for k in 1..i-stars:
          if t != nil and t.len > 0:
            t = if t.kind == tyGenericInst: t.sons[1] else: t.elemType
        if t == nil: result.app(~"void")
        else: result.app(getTypeDesc(p.module, t))
        inc i
    else:
      let start = i
      while i < pat.len:
        if pat[i] notin {'@', '#', '\''}: inc(i)
        else: break
      if i - 1 >= start:
        app(result, substr(pat, start, i - 1))

proc genInfixCall(p: BProc, le, ri: PNode, d: var TLoc) =
  var op, a: TLoc
  initLocExpr(p, ri.sons[0], op)
  # getUniqueType() is too expensive here:
  var typ = skipTypes(ri.sons[0].typ, abstractInst)
  assert(typ.kind == tyProc)
  var length = sonsLen(ri)
  assert(sonsLen(typ) == sonsLen(typ.n))
  # don't call 'ropeToStr' here for efficiency:
  let pat = ri.sons[0].sym.loc.r.data
  internalAssert pat != nil
  if pat.contains({'#', '(', '@', '\''}):
    var pl = genPatternCall(p, ri, pat, typ)
    # simpler version of 'fixupCall' that works with the pl+params combination:
    var typ = skipTypes(ri.sons[0].typ, abstractInst)
    if typ.sons[0] != nil:
      if p.module.compileToCpp and lfSingleUse in d.flags:
        # do not generate spurious temporaries for C++! For C we're better off
        # with them to prevent undefined behaviour and because the codegen
        # is free to emit expressions multiple times!
        d.k = locCall
        d.r = pl
        excl d.flags, lfSingleUse
      else:
        if d.k == locNone: getTemp(p, typ.sons[0], d)
        assert(d.t != nil)        # generate an assignment to d:
        var list: TLoc
        initLoc(list, locCall, d.t, OnUnknown)
        list.r = pl
        genAssignment(p, d, list, {}) # no need for deep copying
    else:
      app(pl, ~";$n")
      line(p, cpsStmts, pl)
  else:
    var pl: PRope = nil
    #var param = typ.n.sons[1].sym
    if 1 < ri.len:
      app(pl, genThisArg(p, ri, 1, typ))
    app(pl, op.r)
    var params: PRope
    for i in countup(2, length - 1):
      if params != nil: params.app(~", ")
      assert(sonsLen(typ) == sonsLen(typ.n))
      app(params, genOtherArg(p, ri, i, typ))
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

  # don't call 'ropeToStr' here for efficiency:
  let pat = ri.sons[0].sym.loc.r.data
  internalAssert pat != nil
  var start = 3
  if ' ' in pat:
    start = 1
    app(pl, op.r)
    if length > 1:
      app(pl, ~": ")
      app(pl, genArg(p, ri.sons[1], typ.n.sons[1].sym, ri))
      start = 2
  else:
    if length > 1:
      app(pl, genArg(p, ri.sons[1], typ.n.sons[1].sym, ri))
      app(pl, ~" ")
    app(pl, op.r)
    if length > 2:
      app(pl, ~": ")
      app(pl, genArg(p, ri.sons[2], typ.n.sons[2].sym, ri))
  for i in countup(start, length-1):
    assert(sonsLen(typ) == sonsLen(typ.n))
    if i >= sonsLen(typ):
      internalError(ri.info, "varargs for objective C method?")
    assert(typ.n.sons[i].kind == nkSym)
    var param = typ.n.sons[i].sym
    app(pl, ~" ")
    app(pl, param.name.s)
    app(pl, ~": ")
    app(pl, genArg(p, ri.sons[i], param, ri))
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
  elif e.sons[0].kind == nkSym and sfInfixCall in e.sons[0].sym.flags:
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
  elif ri.sons[0].kind == nkSym and sfInfixCall in ri.sons[0].sym.flags:
    genInfixCall(p, le, ri, d)
  elif ri.sons[0].kind == nkSym and sfNamedParamCall in ri.sons[0].sym.flags:
    genNamedParamCall(p, ri, d)
  else:
    genPrefixCall(p, le, ri, d)
  postStmtActions(p)
  when false:
    if d.s == onStack and containsGarbageCollectedRef(d.t): keepAlive(p, d)

