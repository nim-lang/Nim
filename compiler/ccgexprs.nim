#
#
#           The Nim Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# included from cgen.nim

proc leftAppearsOnRightSide(le, ri: PNode): bool =
  if le != nil:
    for i in 1 ..< ri.len:
      let r = ri[i]
      if isPartOf(le, r) != arNo: return true

proc hasNoInit(call: PNode): bool {.inline.} =
  result = call.sons[0].kind == nkSym and sfNoInit in call.sons[0].sym.flags

proc fixupCall(p: BProc, le, ri: PNode, d: var TLoc,
               callee, params: Rope) =
  var pl = callee & ~"(" & params
  # getUniqueType() is too expensive here:
  var typ = skipTypes(ri.sons[0].typ, abstractInst)
  if typ.sons[0] != nil:
    if isInvalidReturnType(p.config, typ.sons[0]):
      if params != nil: pl.add(~", ")
      # beware of 'result = p(result)'. We may need to allocate a temporary:
      if d.k in {locTemp, locNone} or not leftAppearsOnRightSide(le, ri):
        # Great, we can use 'd':
        if d.k == locNone: getTemp(p, typ.sons[0], d, needsInit=true)
        elif d.k notin {locTemp} and not hasNoInit(ri):
          # reset before pass as 'result' var:
          discard "resetLoc(p, d)"
        add(pl, addrLoc(p.config, d))
        add(pl, ~");$n")
        line(p, cpsStmts, pl)
      else:
        var tmp: TLoc
        getTemp(p, typ.sons[0], tmp, needsInit=true)
        add(pl, addrLoc(p.config, tmp))
        add(pl, ~");$n")
        line(p, cpsStmts, pl)
        genAssignment(p, d, tmp, {}) # no need for deep copying
    else:
      add(pl, ~")")
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
        initLoc(list, locCall, d.lode, OnUnknown)
        list.r = pl
        genAssignment(p, d, list, {}) # no need for deep copying
  else:
    add(pl, ~");$n")
    line(p, cpsStmts, pl)

proc isInCurrentFrame(p: BProc, n: PNode): bool =
  # checks if `n` is an expression that refers to the current frame;
  # this does not work reliably because of forwarding + inlining can break it
  case n.kind
  of nkSym:
    if n.sym.kind in {skVar, skResult, skTemp, skLet} and p.prc != nil:
      result = p.prc.id == n.sym.owner.id
  of nkDotExpr, nkBracketExpr:
    if skipTypes(n.sons[0].typ, abstractInst).kind notin {tyVar,tyLent,tyPtr,tyRef}:
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

proc genBoundsCheck(p: BProc; arr, a, b: TLoc)

proc openArrayLoc(p: BProc, n: PNode): Rope =
  var a: TLoc

  let q = skipConv(n)
  if getMagic(q) == mSlice:
    # magic: pass slice to openArray:
    var b, c: TLoc
    initLocExpr(p, q[1], a)
    initLocExpr(p, q[2], b)
    initLocExpr(p, q[3], c)
    # but first produce the required index checks:
    if optBoundsCheck in p.options:
      genBoundsCheck(p, a, b, c)
    let ty = skipTypes(a.t, abstractVar+{tyPtr})
    case ty.kind
    of tyArray:
      let first = firstOrd(p.config, ty)
      if first == 0:
        result = "($1)+($2), ($3)-($2)+1" % [rdLoc(a), rdLoc(b), rdLoc(c)]
      else:
        result = "($1)+(($2)-($4)), ($3)-($2)+1" % [rdLoc(a), rdLoc(b), rdLoc(c), intLiteral(first)]
    of tyOpenArray, tyVarargs, tyUncheckedArray:
      result = "($1)+($2), ($3)-($2)+1" % [rdLoc(a), rdLoc(b), rdLoc(c)]
    of tyString, tySequence:
      if skipTypes(n.typ, abstractInst).kind == tyVar and
          not compileToCpp(p.module):
        result = "(*$1)$4+($2), ($3)-($2)+1" % [rdLoc(a), rdLoc(b), rdLoc(c), dataField(p)]
      else:
        result = "$1$4+($2), ($3)-($2)+1" % [rdLoc(a), rdLoc(b), rdLoc(c), dataField(p)]
    else:
      internalError(p.config, "openArrayLoc: " & typeToString(a.t))
  else:
    initLocExpr(p, n, a)
    case skipTypes(a.t, abstractVar).kind
    of tyOpenArray, tyVarargs:
      result = "$1, $1Len_0" % [rdLoc(a)]
    of tyString, tySequence:
      if skipTypes(n.typ, abstractInst).kind == tyVar and
            not compileToCpp(p.module):
        var t: TLoc
        t.r = "(*$1)" % [a.rdLoc]
        result = "(*$1)$3, $2" % [a.rdLoc, lenExpr(p, t), dataField(p)]
      else:
        result = "$1$3, $2" % [a.rdLoc, lenExpr(p, a), dataField(p)]
    of tyArray:
      result = "$1, $2" % [rdLoc(a), rope(lengthOrd(p.config, a.t))]
    of tyPtr, tyRef:
      case lastSon(a.t).kind
      of tyString, tySequence:
        var t: TLoc
        t.r = "(*$1)" % [a.rdLoc]
        result = "(*$1)$3, $2" % [a.rdLoc, lenExpr(p, t), dataField(p)]
      of tyArray:
        result = "$1, $2" % [rdLoc(a), rope(lengthOrd(p.config, lastSon(a.t)))]
      else:
        internalError(p.config, "openArrayLoc: " & typeToString(a.t))
    else: internalError(p.config, "openArrayLoc: " & typeToString(a.t))

proc genArgStringToCString(p: BProc, n: PNode): Rope {.inline.} =
  var a: TLoc
  initLocExpr(p, n.sons[0], a)
  result = ropecg(p.module, "#nimToCStringConv($1)", [a.rdLoc])

proc genArg(p: BProc, n: PNode, param: PSym; call: PNode): Rope =
  var a: TLoc
  if n.kind == nkStringToCString:
    result = genArgStringToCString(p, n)
  elif skipTypes(param.typ, abstractVar).kind in {tyOpenArray, tyVarargs}:
    var n = if n.kind != nkHiddenAddr: n else: n.sons[0]
    result = openArrayLoc(p, n)
  elif ccgIntroducedPtr(p.config, param):
    initLocExpr(p, n, a)
    result = addrLoc(p.config, a)
  elif p.module.compileToCpp and param.typ.kind == tyVar and
      n.kind == nkHiddenAddr:
    initLocExprSingleUse(p, n.sons[0], a)
    # if the proc is 'importc'ed but not 'importcpp'ed then 'var T' still
    # means '*T'. See posix.nim for lots of examples that do that in the wild.
    let callee = call.sons[0]
    if callee.kind == nkSym and
        {sfImportC, sfInfixCall, sfCompilerProc} * callee.sym.flags == {sfImportC} and
        {lfHeader, lfNoDecl} * callee.sym.loc.flags != {}:
      result = addrLoc(p.config, a)
    else:
      result = rdLoc(a)
  else:
    initLocExprSingleUse(p, n, a)
    result = rdLoc(a)

proc genArgNoParam(p: BProc, n: PNode): Rope =
  var a: TLoc
  if n.kind == nkStringToCString:
    result = genArgStringToCString(p, n)
  else:
    initLocExprSingleUse(p, n, a)
    result = rdLoc(a)

template genParamLoop(params) {.dirty.} =
  if i < sonsLen(typ):
    assert(typ.n.sons[i].kind == nkSym)
    let paramType = typ.n.sons[i]
    if not paramType.typ.isCompileTimeOnly:
      if params != nil: add(params, ~", ")
      add(params, genArg(p, ri.sons[i], paramType.sym, ri))
  else:
    if params != nil: add(params, ~", ")
    add(params, genArgNoParam(p, ri.sons[i]))

proc genPrefixCall(p: BProc, le, ri: PNode, d: var TLoc) =
  var op: TLoc
  # this is a hotspot in the compiler
  initLocExpr(p, ri.sons[0], op)
  var params: Rope
  # getUniqueType() is too expensive here:
  var typ = skipTypes(ri.sons[0].typ, abstractInst)
  assert(typ.kind == tyProc)
  assert(sonsLen(typ) == sonsLen(typ.n))
  var length = sonsLen(ri)
  for i in countup(1, length - 1):
    genParamLoop(params)
  fixupCall(p, le, ri, d, op.r, params)

proc genClosureCall(p: BProc, le, ri: PNode, d: var TLoc) =

  proc getRawProcType(p: BProc, t: PType): Rope =
    result = getClosureType(p.module, t, clHalf)

  proc addComma(r: Rope): Rope =
    result = if r == nil: r else: r & ~", "

  const PatProc = "$1.ClE_0? $1.ClP_0($3$1.ClE_0):(($4)($1.ClP_0))($2)"
  const PatIter = "$1.ClP_0($3$1.ClE_0)" # we know the env exists
  var op: TLoc
  initLocExpr(p, ri.sons[0], op)
  var pl: Rope

  var typ = skipTypes(ri.sons[0].typ, abstractInst)
  assert(typ.kind == tyProc)
  var length = sonsLen(ri)
  for i in countup(1, length - 1):
    assert(sonsLen(typ) == sonsLen(typ.n))
    genParamLoop(pl)

  template genCallPattern {.dirty.} =
    lineF(p, cpsStmts, callPattern & ";$n", [op.r, pl, pl.addComma, rawProc])

  let rawProc = getRawProcType(p, typ)
  let callPattern = if tfIterator in typ.flags: PatIter else: PatProc
  if typ.sons[0] != nil:
    if isInvalidReturnType(p.config, typ.sons[0]):
      if sonsLen(ri) > 1: add(pl, ~", ")
      # beware of 'result = p(result)'. We may need to allocate a temporary:
      if d.k in {locTemp, locNone} or not leftAppearsOnRightSide(le, ri):
        # Great, we can use 'd':
        if d.k == locNone:
          getTemp(p, typ.sons[0], d, needsInit=true)
        elif d.k notin {locTemp} and not hasNoInit(ri):
          # reset before pass as 'result' var:
          discard "resetLoc(p, d)"
        add(pl, addrLoc(p.config, d))
        genCallPattern()
      else:
        var tmp: TLoc
        getTemp(p, typ.sons[0], tmp, needsInit=true)
        add(pl, addrLoc(p.config, tmp))
        genCallPattern()
        genAssignment(p, d, tmp, {}) # no need for deep copying
    else:
      if d.k == locNone: getTemp(p, typ.sons[0], d)
      assert(d.t != nil)        # generate an assignment to d:
      var list: TLoc
      initLoc(list, locCall, d.lode, OnUnknown)
      list.r = callPattern % [op.r, pl, pl.addComma, rawProc]
      genAssignment(p, d, list, {}) # no need for deep copying
  else:
    genCallPattern()

proc genOtherArg(p: BProc; ri: PNode; i: int; typ: PType): Rope =
  if i < sonsLen(typ):
    # 'var T' is 'T&' in C++. This means we ignore the request of
    # any nkHiddenAddr when it's a 'var T'.
    let paramType = typ.n.sons[i]
    assert(paramType.kind == nkSym)
    if paramType.typ.isCompileTimeOnly:
      result = nil
    elif typ.sons[i].kind == tyVar and ri.sons[i].kind == nkHiddenAddr:
      result = genArgNoParam(p, ri.sons[i][0])
    else:
      result = genArgNoParam(p, ri.sons[i]) #, typ.n.sons[i].sym)
  else:
    if tfVarargs notin typ.flags:
      localError(p.config, ri.info, "wrong argument count")
      result = nil
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

proc skipAddrDeref(node: PNode): PNode =
  var n = node
  var isAddr = false
  case n.kind
  of nkAddr, nkHiddenAddr:
    n = n.sons[0]
    isAddr = true
  of nkDerefExpr, nkHiddenDeref:
    n = n.sons[0]
  else: return n
  if n.kind == nkObjDownConv: n = n.sons[0]
  if isAddr and n.kind in {nkDerefExpr, nkHiddenDeref}:
    result = n.sons[0]
  elif n.kind in {nkAddr, nkHiddenAddr}:
    result = n.sons[0]
  else:
    result = node

proc genThisArg(p: BProc; ri: PNode; i: int; typ: PType): Rope =
  # for better or worse c2nim translates the 'this' argument to a 'var T'.
  # However manual wrappers may also use 'ptr T'. In any case we support both
  # for convenience.
  internalAssert p.config, i < sonsLen(typ)
  assert(typ.n.sons[i].kind == nkSym)
  # if the parameter is lying (tyVar) and thus we required an additional deref,
  # skip the deref:
  var ri = ri[i]
  while ri.kind == nkObjDownConv: ri = ri[0]
  let t = typ.sons[i].skipTypes({tyGenericInst, tyAlias, tySink})
  if t.kind == tyVar:
    let x = if ri.kind == nkHiddenAddr: ri[0] else: ri
    if x.typ.kind == tyPtr:
      result = genArgNoParam(p, x)
      result.add("->")
    elif x.kind in {nkHiddenDeref, nkDerefExpr} and x[0].typ.kind == tyPtr:
      result = genArgNoParam(p, x[0])
      result.add("->")
    else:
      result = genArgNoParam(p, x)
      result.add(".")
  elif t.kind == tyPtr:
    if ri.kind in {nkAddr, nkHiddenAddr}:
      result = genArgNoParam(p, ri[0])
      result.add(".")
    else:
      result = genArgNoParam(p, ri)
      result.add("->")
  else:
    ri = skipAddrDeref(ri)
    if ri.kind in {nkAddr, nkHiddenAddr}: ri = ri[0]
    result = genArgNoParam(p, ri) #, typ.n.sons[i].sym)
    result.add(".")

proc genPatternCall(p: BProc; ri: PNode; pat: string; typ: PType): Rope =
  var i = 0
  var j = 1
  while i < pat.len:
    case pat[i]
    of '@':
      if j < ri.len:
        result.add genOtherArg(p, ri, j, typ)
        for k in j+1 ..< ri.len:
          result.add(~", ")
          result.add genOtherArg(p, ri, k, typ)
      inc i
    of '#':
      if pat[i+1] in {'+', '@'}:
        let ri = ri[j]
        if ri.kind in nkCallKinds:
          let typ = skipTypes(ri.sons[0].typ, abstractInst)
          if pat[i+1] == '+': result.add genArgNoParam(p, ri.sons[0])
          result.add(~"(")
          if 1 < ri.len:
            result.add genOtherArg(p, ri, 1, typ)
          for k in j+1 ..< ri.len:
            result.add(~", ")
            result.add genOtherArg(p, ri, k, typ)
          result.add(~")")
        else:
          localError(p.config, ri.info, "call expression expected for C++ pattern")
        inc i
      elif pat[i+1] == '.':
        result.add genThisArg(p, ri, j, typ)
        inc i
      elif pat[i+1] == '[':
        var arg = ri.sons[j].skipAddrDeref
        while arg.kind in {nkAddr, nkHiddenAddr, nkObjDownConv}: arg = arg[0]
        result.add genArgNoParam(p, arg)
        #result.add debugTree(arg, 0, 10)
      else:
        result.add genOtherArg(p, ri, j, typ)
      inc j
      inc i
    of '\'':
      var idx, stars: int
      if scanCppGenericSlot(pat, i, idx, stars):
        var t = resolveStarsInCppType(typ, idx, stars)
        if t == nil: result.add(~"void")
        else: result.add(getTypeDesc(p.module, t))
    else:
      let start = i
      while i < pat.len:
        if pat[i] notin {'@', '#', '\''}: inc(i)
        else: break
      if i - 1 >= start:
        add(result, substr(pat, start, i - 1))

proc genInfixCall(p: BProc, le, ri: PNode, d: var TLoc) =
  var op: TLoc
  initLocExpr(p, ri.sons[0], op)
  # getUniqueType() is too expensive here:
  var typ = skipTypes(ri.sons[0].typ, abstractInst)
  assert(typ.kind == tyProc)
  var length = sonsLen(ri)
  assert(sonsLen(typ) == sonsLen(typ.n))
  # don't call '$' here for efficiency:
  let pat = ri.sons[0].sym.loc.r.data
  internalAssert p.config, pat.len > 0
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
        initLoc(list, locCall, d.lode, OnUnknown)
        list.r = pl
        genAssignment(p, d, list, {}) # no need for deep copying
    else:
      add(pl, ~";$n")
      line(p, cpsStmts, pl)
  else:
    var pl: Rope = nil
    #var param = typ.n.sons[1].sym
    if 1 < ri.len:
      add(pl, genThisArg(p, ri, 1, typ))
    add(pl, op.r)
    var params: Rope
    for i in countup(2, length - 1):
      if params != nil: params.add(~", ")
      assert(sonsLen(typ) == sonsLen(typ.n))
      add(params, genOtherArg(p, ri, i, typ))
    fixupCall(p, le, ri, d, pl, params)

proc genNamedParamCall(p: BProc, ri: PNode, d: var TLoc) =
  # generates a crappy ObjC call
  var op: TLoc
  initLocExpr(p, ri.sons[0], op)
  var pl = ~"["
  # getUniqueType() is too expensive here:
  var typ = skipTypes(ri.sons[0].typ, abstractInst)
  assert(typ.kind == tyProc)
  var length = sonsLen(ri)
  assert(sonsLen(typ) == sonsLen(typ.n))

  # don't call '$' here for efficiency:
  let pat = ri.sons[0].sym.loc.r.data
  internalAssert p.config, pat.len > 0
  var start = 3
  if ' ' in pat:
    start = 1
    add(pl, op.r)
    if length > 1:
      add(pl, ~": ")
      add(pl, genArg(p, ri.sons[1], typ.n.sons[1].sym, ri))
      start = 2
  else:
    if length > 1:
      add(pl, genArg(p, ri.sons[1], typ.n.sons[1].sym, ri))
      add(pl, ~" ")
    add(pl, op.r)
    if length > 2:
      add(pl, ~": ")
      add(pl, genArg(p, ri.sons[2], typ.n.sons[2].sym, ri))
  for i in countup(start, length-1):
    assert(sonsLen(typ) == sonsLen(typ.n))
    if i >= sonsLen(typ):
      internalError(p.config, ri.info, "varargs for objective C method?")
    assert(typ.n.sons[i].kind == nkSym)
    var param = typ.n.sons[i].sym
    add(pl, ~" ")
    add(pl, param.name.s)
    add(pl, ~": ")
    add(pl, genArg(p, ri.sons[i], param, ri))
  if typ.sons[0] != nil:
    if isInvalidReturnType(p.config, typ.sons[0]):
      if sonsLen(ri) > 1: add(pl, ~" ")
      # beware of 'result = p(result)'. We always allocate a temporary:
      if d.k in {locTemp, locNone}:
        # We already got a temp. Great, special case it:
        if d.k == locNone: getTemp(p, typ.sons[0], d, needsInit=true)
        add(pl, ~"Result: ")
        add(pl, addrLoc(p.config, d))
        add(pl, ~"];$n")
        line(p, cpsStmts, pl)
      else:
        var tmp: TLoc
        getTemp(p, typ.sons[0], tmp, needsInit=true)
        add(pl, addrLoc(p.config, tmp))
        add(pl, ~"];$n")
        line(p, cpsStmts, pl)
        genAssignment(p, d, tmp, {}) # no need for deep copying
    else:
      add(pl, ~"]")
      if d.k == locNone: getTemp(p, typ.sons[0], d)
      assert(d.t != nil)        # generate an assignment to d:
      var list: TLoc
      initLoc(list, locCall, ri, OnUnknown)
      list.r = pl
      genAssignment(p, d, list, {}) # no need for deep copying
  else:
    add(pl, ~"];$n")
    line(p, cpsStmts, pl)

proc genCall(p: BProc, e: PNode, d: var TLoc) =
  if e.sons[0].typ.skipTypes({tyGenericInst, tyAlias, tySink}).callConv == ccClosure:
    genClosureCall(p, nil, e, d)
  elif e.sons[0].kind == nkSym and sfInfixCall in e.sons[0].sym.flags:
    genInfixCall(p, nil, e, d)
  elif e.sons[0].kind == nkSym and sfNamedParamCall in e.sons[0].sym.flags:
    genNamedParamCall(p, e, d)
  else:
    genPrefixCall(p, nil, e, d)
  postStmtActions(p)

proc genAsgnCall(p: BProc, le, ri: PNode, d: var TLoc) =
  if ri.sons[0].typ.skipTypes({tyGenericInst, tyAlias, tySink}).callConv == ccClosure:
    genClosureCall(p, le, ri, d)
  elif ri.sons[0].kind == nkSym and sfInfixCall in ri.sons[0].sym.flags:
    genInfixCall(p, le, ri, d)
  elif ri.sons[0].kind == nkSym and sfNamedParamCall in ri.sons[0].sym.flags:
    genNamedParamCall(p, ri, d)
  else:
    genPrefixCall(p, le, ri, d)
  postStmtActions(p)

const
  RangeExpandLimit = 256      # do not generate ranges
                              # over 'RangeExpandLimit' elements
  stringCaseThreshold = 8
    # above X strings a hash-switch for strings is generated

proc registerGcRoot(p: BProc, v: PSym) =
  if p.config.selectedGC in {gcMarkAndSweep, gcDestructors, gcV2, gcRefc} and
      containsGarbageCollectedRef(v.loc.t):
    # we register a specialized marked proc here; this has the advantage
    # that it works out of the box for thread local storage then :-)
    let prc = genTraverseProcForGlobal(p.module, v, v.info)
    if sfThread in v.flags:
      appcg(p.module, p.module.initProc.procSec(cpsInit),
        "#nimRegisterThreadLocalMarker($1);$n", [prc])
    else:
      appcg(p.module, p.module.initProc.procSec(cpsInit),
        "#nimRegisterGlobalMarker($1);$n", [prc])

proc isAssignedImmediately(conf: ConfigRef; n: PNode): bool {.inline.} =
  if n.kind == nkEmpty: return false
  if isInvalidReturnType(conf, n.typ):
    # var v = f()
    # is transformed into: var v;  f(addr v)
    # where 'f' **does not** initialize the result!
    return false
  result = true

proc inExceptBlockLen(p: BProc): int =
  for x in p.nestedTryStmts:
    if x.inExcept: result.inc

proc genVarTuple(p: BProc, n: PNode) =
  var tup, field: TLoc
  if n.kind != nkVarTuple: internalError(p.config, n.info, "genVarTuple")
  var L = sonsLen(n)

  # if we have a something that's been captured, use the lowering instead:
  for i in countup(0, L-3):
    if n[i].kind != nkSym:
      genStmts(p, lowerTupleUnpacking(p.module.g.graph, n, p.prc))
      return

  genLineDir(p, n)
  initLocExpr(p, n.sons[L-1], tup)
  var t = tup.t.skipTypes(abstractInst)
  for i in countup(0, L-3):
    let vn = n.sons[i]
    let v = vn.sym
    if sfCompileTime in v.flags: continue
    if sfGlobal in v.flags:
      assignGlobalVar(p, vn)
      genObjectInit(p, cpsInit, v.typ, v.loc, true)
      registerGcRoot(p, v)
    else:
      assignLocalVar(p, vn)
      initLocalVar(p, v, immediateAsgn=isAssignedImmediately(p.config, n[L-1]))
    initLoc(field, locExpr, vn, tup.storage)
    if t.kind == tyTuple:
      field.r = "$1.Field$2" % [rdLoc(tup), rope(i)]
    else:
      if t.n.sons[i].kind != nkSym: internalError(p.config, n.info, "genVarTuple")
      field.r = "$1.$2" % [rdLoc(tup), mangleRecFieldName(p.module, t.n.sons[i].sym)]
    putLocIntoDest(p, v.loc, field)

proc genDeref(p: BProc, e: PNode, d: var TLoc; enforceDeref=false)

proc loadInto(p: BProc, le, ri: PNode, a: var TLoc) {.inline.} =
  if ri.kind in nkCallKinds and (ri.sons[0].kind != nkSym or
                                 ri.sons[0].sym.magic == mNone):
    genAsgnCall(p, le, ri, a)
  elif ri.kind in {nkDerefExpr, nkHiddenDeref}:
    # this is a hacky way to fix #1181 (tmissingderef)::
    #
    #  var arr1 = cast[ptr array[4, int8]](addr foo)[]
    #
    # However, fixing this properly really requires modelling 'array' as
    # a 'struct' in C to preserve dereferencing semantics completely. Not
    # worth the effort until version 1.0 is out.
    genDeref(p, ri, a, enforceDeref=true)
  else:
    expr(p, ri, a)

proc startBlock(p: BProc, start: FormatStr = "{$n",
                args: varargs[Rope]): int {.discardable.} =
  lineCg(p, cpsStmts, start, args)
  inc(p.labels)
  result = len(p.blocks)
  setLen(p.blocks, result + 1)
  p.blocks[result].id = p.labels
  p.blocks[result].nestedTryStmts = p.nestedTryStmts.len.int16
  p.blocks[result].nestedExceptStmts = p.inExceptBlockLen.int16

proc assignLabel(b: var TBlock): Rope {.inline.} =
  b.label = "LA" & b.id.rope
  result = b.label

proc blockBody(b: var TBlock): Rope =
  result = b.sections[cpsLocals]
  if b.frameLen > 0:
    result.addf("FR_.len+=$1;$n", [b.frameLen.rope])
  result.add(b.sections[cpsInit])
  result.add(b.sections[cpsStmts])

proc endBlock(p: BProc, blockEnd: Rope) =
  let topBlock = p.blocks.len-1
  # the block is merged into the parent block
  add(p.blocks[topBlock-1].sections[cpsStmts], p.blocks[topBlock].blockBody)
  setLen(p.blocks, topBlock)
  # this is done after the block is popped so $n is
  # properly indented when pretty printing is enabled
  line(p, cpsStmts, blockEnd)

proc endBlock(p: BProc) =
  let topBlock = p.blocks.len - 1
  var blockEnd = if p.blocks[topBlock].label != nil:
      ropecg(p.module, "} $1: ;$n", p.blocks[topBlock].label)
    else:
      ~"}$n"
  let frameLen = p.blocks[topBlock].frameLen
  if frameLen > 0:
    blockEnd.addf("FR_.len-=$1;$n", [frameLen.rope])
  endBlock(p, blockEnd)

proc genSimpleBlock(p: BProc, stmts: PNode) {.inline.} =
  startBlock(p)
  genStmts(p, stmts)
  endBlock(p)

proc exprBlock(p: BProc, n: PNode, d: var TLoc) =
  startBlock(p)
  expr(p, n, d)
  endBlock(p)

template preserveBreakIdx(body: untyped): untyped =
  var oldBreakIdx = p.breakIdx
  body
  p.breakIdx = oldBreakIdx

proc genState(p: BProc, n: PNode) =
  internalAssert p.config, n.len == 1
  let n0 = n[0]
  if n0.kind == nkIntLit:
    let idx = n.sons[0].intVal
    linefmt(p, cpsStmts, "STATE$1: ;$n", idx.rope)
  elif n0.kind == nkStrLit:
    linefmt(p, cpsStmts, "$1: ;$n", n0.strVal.rope)

proc blockLeaveActions(p: BProc, howManyTrys, howManyExcepts: int) =
  # Called by return and break stmts.
  # Deals with issues faced when jumping out of try/except/finally stmts,

  var stack = newSeq[tuple[n: PNode, inExcept: bool]](0)

  for i in countup(1, howManyTrys):
    let tryStmt = p.nestedTryStmts.pop
    if not p.module.compileToCpp or optNoCppExceptions in p.config.globalOptions:
      # Pop safe points generated by try
      if not tryStmt.inExcept:
        linefmt(p, cpsStmts, "#popSafePoint();$n")

    # Pop this try-stmt of the list of nested trys
    # so we don't infinite recurse on it in the next step.
    stack.add(tryStmt)

    # Find finally-stmt for this try-stmt
    # and generate a copy of its sons
    var finallyStmt = lastSon(tryStmt.n)
    if finallyStmt.kind == nkFinally:
      genStmts(p, finallyStmt.sons[0])

  # push old elements again:
  for i in countdown(howManyTrys-1, 0):
    p.nestedTryStmts.add(stack[i])

  if not p.module.compileToCpp or optNoCppExceptions in p.config.globalOptions:
    # Pop exceptions that was handled by the
    # except-blocks we are in
    for i in countdown(howManyExcepts-1, 0):
      linefmt(p, cpsStmts, "#popCurrentException();$n")

proc genGotoState(p: BProc, n: PNode) =
  # we resist the temptation to translate it into duff's device as it later
  # will be translated into computed gotos anyway for GCC at least:
  # switch (x.state) {
  #   case 0: goto STATE0;
  # ...
  var a: TLoc
  initLocExpr(p, n.sons[0], a)
  lineF(p, cpsStmts, "switch ($1) {$n", [rdLoc(a)])
  p.beforeRetNeeded = true
  lineF(p, cpsStmts, "case -1:$n", [])
  blockLeaveActions(p,
    howManyTrys    = p.nestedTryStmts.len,
    howManyExcepts = p.inExceptBlockLen)
  lineF(p, cpsStmts, " goto BeforeRet_;$n", [])
  var statesCounter = lastOrd(p.config, n.sons[0].typ)
  if n.len >= 2 and n[1].kind == nkIntLit:
    statesCounter = n[1].intVal
  let prefix = if n.len == 3 and n[2].kind == nkStrLit: n[2].strVal.rope
               else: rope"STATE"
  for i in 0i64 .. statesCounter:
    lineF(p, cpsStmts, "case $2: goto $1$2;$n", [prefix, rope(i)])
  lineF(p, cpsStmts, "}$n", [])

proc genBreakState(p: BProc, n: PNode, d: var TLoc) =
  var a: TLoc
  initLoc(d, locExpr, n, OnUnknown)

  if n.sons[0].kind == nkClosure:
    initLocExpr(p, n.sons[0].sons[1], a)
    d.r = "(((NI*) $1)[1] < 0)" % [rdLoc(a)]
  else:
    initLocExpr(p, n.sons[0], a)
    # the environment is guaranteed to contain the 'state' field at offset 1:
    d.r = "((((NI*) $1.ClE_0)[1]) < 0)" % [rdLoc(a)]

proc genGotoVar(p: BProc; value: PNode) =
  if value.kind notin {nkCharLit..nkUInt64Lit}:
    localError(p.config, value.info, "'goto' target must be a literal value")
  else:
    lineF(p, cpsStmts, "goto NIMSTATE_$#;$n", [value.intVal.rope])

proc genSingleVar(p: BProc, a: PNode) =
  let vn = a.sons[0]
  let v = vn.sym
  if sfCompileTime in v.flags: return
  if sfGoto in v.flags:
    # translate 'var state {.goto.} = X' into 'goto LX':
    genGotoVar(p, a.sons[2])
    return
  var targetProc = p
  if sfGlobal in v.flags:
    if v.flags * {sfImportc, sfExportc} == {sfImportc} and
        a.sons[2].kind == nkEmpty and
        v.loc.flags * {lfHeader, lfNoDecl} != {}:
      return
    if sfPure in v.flags:
      # v.owner.kind != skModule:
      targetProc = p.module.preInitProc
    assignGlobalVar(targetProc, vn)
    # XXX: be careful here.
    # Global variables should not be zeromem-ed within loops
    # (see bug #20).
    # That's why we are doing the construction inside the preInitProc.
    # genObjectInit relies on the C runtime's guarantees that
    # global variables will be initialized to zero.
    var loc = v.loc

    # When the native TLS is unavailable, a global thread-local variable needs
    # one more layer of indirection in order to access the TLS block.
    # Only do this for complex types that may need a call to `objectInit`
    if sfThread in v.flags and emulatedThreadVars(p.config) and
      isComplexValueType(v.typ):
      initLocExprSingleUse(p.module.preInitProc, vn, loc)
    genObjectInit(p.module.preInitProc, cpsInit, v.typ, loc, true)
    # Alternative construction using default constructor (which may zeromem):
    # if sfImportc notin v.flags: constructLoc(p.module.preInitProc, v.loc)
    if sfExportc in v.flags and p.module.g.generatedHeader != nil:
      genVarPrototype(p.module.g.generatedHeader, vn)
    registerGcRoot(p, v)
  else:
    let value = a.sons[2]
    let imm = isAssignedImmediately(p.config, value)
    if imm and p.module.compileToCpp and p.splitDecls == 0 and
        not containsHiddenPointer(v.typ):
      # C++ really doesn't like things like 'Foo f; f = x' as that invokes a
      # parameterless constructor followed by an assignment operator. So we
      # generate better code here: 'Foo f = x;'
      genLineDir(p, a)
      let decl = localVarDecl(p, vn)
      var tmp: TLoc
      if value.kind in nkCallKinds and value[0].kind == nkSym and
           sfConstructor in value[0].sym.flags:
        var params: Rope
        let typ = skipTypes(value.sons[0].typ, abstractInst)
        assert(typ.kind == tyProc)
        for i in 1..<value.len:
          if params != nil: params.add(~", ")
          assert(sonsLen(typ) == sonsLen(typ.n))
          add(params, genOtherArg(p, value, i, typ))
        if params == nil:
          lineF(p, cpsStmts, "$#;$n", [decl])
        else:
          lineF(p, cpsStmts, "$#($#);$n", [decl, params])
      else:
        initLocExprSingleUse(p, value, tmp)
        lineF(p, cpsStmts, "$# = $#;$n", [decl, tmp.rdLoc])
      return
    assignLocalVar(p, vn)
    initLocalVar(p, v, imm)

  if a.sons[2].kind != nkEmpty:
    genLineDir(targetProc, a)
    loadInto(targetProc, a.sons[0], a.sons[2], v.loc)

proc genClosureVar(p: BProc, a: PNode) =
  var immediateAsgn = a.sons[2].kind != nkEmpty
  if immediateAsgn:
    var v: TLoc
    initLocExpr(p, a.sons[0], v)
    genLineDir(p, a)
    loadInto(p, a.sons[0], a.sons[2], v)

proc genVarStmt(p: BProc, n: PNode) =
  for it in n.sons:
    if it.kind == nkCommentStmt: continue
    if it.kind == nkIdentDefs:
      # can be a lifted var nowadays ...
      if it.sons[0].kind == nkSym:
        genSingleVar(p, it)
      else:
        genClosureVar(p, it)
    else:
      genVarTuple(p, it)

proc genIf(p: BProc, n: PNode, d: var TLoc) =
  #
  #  { if (!expr1) goto L1;
  #   thenPart }
  #  goto LEnd
  #  L1:
  #  { if (!expr2) goto L2;
  #   thenPart2 }
  #  goto LEnd
  #  L2:
  #  { elsePart }
  #  Lend:
  var
    a: TLoc
    lelse: TLabel
  if not isEmptyType(n.typ) and d.k == locNone:
    getTemp(p, n.typ, d)
  genLineDir(p, n)
  let lend = getLabel(p)
  for it in n.sons:
    # bug #4230: avoid false sharing between branches:
    if d.k == locTemp and isEmptyType(n.typ): d.k = locNone
    if it.len == 2:
      startBlock(p)
      initLocExprSingleUse(p, it.sons[0], a)
      lelse = getLabel(p)
      inc(p.labels)
      lineF(p, cpsStmts, "if (!$1) goto $2;$n",
            [rdLoc(a), lelse])
      if p.module.compileToCpp:
        # avoid "jump to label crosses initialization" error:
        add(p.s(cpsStmts), "{")
        expr(p, it.sons[1], d)
        add(p.s(cpsStmts), "}")
      else:
        expr(p, it.sons[1], d)
      endBlock(p)
      if sonsLen(n) > 1:
        lineF(p, cpsStmts, "goto $1;$n", [lend])
      fixLabel(p, lelse)
    elif it.len == 1:
      startBlock(p)
      expr(p, it.sons[0], d)
      endBlock(p)
    else: internalError(p.config, n.info, "genIf()")
  if sonsLen(n) > 1: fixLabel(p, lend)

proc genReturnStmt(p: BProc, t: PNode) =
  if nfPreventCg in t.flags: return
  p.beforeRetNeeded = true
  genLineDir(p, t)
  if (t.sons[0].kind != nkEmpty): genStmts(p, t.sons[0])
  blockLeaveActions(p,
    howManyTrys    = p.nestedTryStmts.len,
    howManyExcepts = p.inExceptBlockLen)
  if (p.finallySafePoints.len > 0):
    # If we're in a finally block, and we came here by exception
    # consume it before we return.
    var safePoint = p.finallySafePoints[p.finallySafePoints.len-1]
    linefmt(p, cpsStmts, "if ($1.status != 0) #popCurrentException();$n", safePoint)
  lineF(p, cpsStmts, "goto BeforeRet_;$n", [])

proc genGotoForCase(p: BProc; caseStmt: PNode) =
  for i in 1 ..< caseStmt.len:
    startBlock(p)
    let it = caseStmt.sons[i]
    for j in 0 .. it.len-2:
      if it.sons[j].kind == nkRange:
        localError(p.config, it.info, "range notation not available for computed goto")
        return
      let val = getOrdValue(it.sons[j])
      lineF(p, cpsStmts, "NIMSTATE_$#:$n", [val.rope])
    genStmts(p, it.lastSon)
    endBlock(p)


iterator fieldValuePairs(n: PNode): tuple[memberSym, valueSym: PNode] =
  assert(n.kind in {nkLetSection, nkVarSection})
  for identDefs in n:
    if identDefs.kind == nkIdentDefs:
      let valueSym = identDefs[^1]
      for i in 0 ..< identDefs.len-2:
        let memberSym = identDefs[i]
        yield((memberSym: memberSym, valueSym: valueSym))

proc genComputedGoto(p: BProc; n: PNode) =
  # first pass: Generate array of computed labels:
  var casePos = -1
  var arraySize: int
  for i in 0 ..< n.len:
    let it = n.sons[i]
    if it.kind == nkCaseStmt:
      if lastSon(it).kind != nkOfBranch:
        localError(p.config, it.info,
            "case statement must be exhaustive for computed goto"); return
      casePos = i
      if enumHasHoles(it.sons[0].typ):
        localError(p.config, it.info,
            "case statement cannot work on enums with holes for computed goto"); return
      let aSize = lengthOrd(p.config, it.sons[0].typ)
      if aSize > 10_000:
        localError(p.config, it.info,
            "case statement has too many cases for computed goto"); return
      arraySize = aSize.int
      if firstOrd(p.config, it.sons[0].typ) != 0:
        localError(p.config, it.info,
            "case statement has to start at 0 for computed goto"); return
  if casePos < 0:
    localError(p.config, n.info, "no case statement found for computed goto"); return
  var id = p.labels+1
  inc p.labels, arraySize+1
  let tmp = "TMP$1_" % [id.rope]
  var gotoArray = "static void* $#[$#] = {" % [tmp, arraySize.rope]
  for i in 1..arraySize-1:
    gotoArray.addf("&&TMP$#_, ", [rope(id+i)])
  gotoArray.addf("&&TMP$#_};$n", [rope(id+arraySize)])
  line(p, cpsLocals, gotoArray)

  for j in 0 ..< casePos:
    genStmts(p, n.sons[j])

  let caseStmt = n.sons[casePos]
  var a: TLoc
  initLocExpr(p, caseStmt.sons[0], a)
  # first goto:
  lineF(p, cpsStmts, "goto *$#[$#];$n", [tmp, a.rdLoc])

  for i in 1 ..< caseStmt.len:
    startBlock(p)
    let it = caseStmt.sons[i]
    for j in 0 .. it.len-2:
      if it.sons[j].kind == nkRange:
        localError(p.config, it.info, "range notation not available for computed goto")
        return

      let val = getOrdValue(it.sons[j])
      lineF(p, cpsStmts, "TMP$#_:$n", [intLiteral(val+id+1)])

    genStmts(p, it.lastSon)

    for j in casePos+1 ..< n.sons.len:
      genStmts(p, n.sons[j])

    for j in 0 ..< casePos:
      # prevent new local declarations
      # compile declarations as assignments
      let it = n.sons[j]
      if it.kind in {nkLetSection, nkVarSection}:
        let asgn = copyNode(it)
        asgn.kind = nkAsgn
        asgn.sons.setLen 2
        for sym, value in it.fieldValuePairs:
          if value.kind != nkEmpty:
            asgn.sons[0] = sym
            asgn.sons[1] = value
            genStmts(p, asgn)
      else:
        genStmts(p, it)

    var a: TLoc
    initLocExpr(p, caseStmt.sons[0], a)
    lineF(p, cpsStmts, "goto *$#[$#];$n", [tmp, a.rdLoc])
    endBlock(p)

  for j in casePos+1 ..< n.sons.len:
    genStmts(p, n.sons[j])


proc genWhileStmt(p: BProc, t: PNode) =
  # we don't generate labels here as for example GCC would produce
  # significantly worse code
  var
    a: TLoc
  assert(sonsLen(t) == 2)
  inc(p.withinLoop)
  genLineDir(p, t)

  preserveBreakIdx:
    var loopBody = t.sons[1]
    if loopBody.stmtsContainPragma(wComputedGoto) and
       hasComputedGoto in CC[p.config.cCompiler].props:
         # for closure support weird loop bodies are generated:
      if loopBody.len == 2 and loopBody.sons[0].kind == nkEmpty:
        loopBody = loopBody.sons[1]
      genComputedGoto(p, loopBody)
    else:
      p.breakIdx = startBlock(p, "while (1) {$n")
      p.blocks[p.breakIdx].isLoop = true
      initLocExpr(p, t.sons[0], a)
      if (t.sons[0].kind != nkIntLit) or (t.sons[0].intVal == 0):
        let label = assignLabel(p.blocks[p.breakIdx])
        lineF(p, cpsStmts, "if (!$1) goto $2;$n", [rdLoc(a), label])
      genStmts(p, loopBody)

      if optProfiler in p.options:
        # invoke at loop body exit:
        linefmt(p, cpsStmts, "#nimProfile();$n")
      endBlock(p)

  dec(p.withinLoop)

proc genBlock(p: BProc, n: PNode, d: var TLoc) =
  # bug #4505: allocate the temp in the outer scope
  # so that it can escape the generated {}:
  if not isEmptyType(n.typ) and d.k == locNone:
    getTemp(p, n.typ, d)
  preserveBreakIdx:
    p.breakIdx = startBlock(p)
    if n.sons[0].kind != nkEmpty:
      # named block?
      assert(n.sons[0].kind == nkSym)
      var sym = n.sons[0].sym
      sym.loc.k = locOther
      sym.position = p.breakIdx+1
    expr(p, n.sons[1], d)
    endBlock(p)

proc genParForStmt(p: BProc, t: PNode) =
  assert(sonsLen(t) == 3)
  inc(p.withinLoop)
  genLineDir(p, t)

  preserveBreakIdx:
    let forLoopVar = t.sons[0].sym
    var rangeA, rangeB: TLoc
    assignLocalVar(p, t.sons[0])
    #initLoc(forLoopVar.loc, locLocalVar, forLoopVar.typ, onStack)
    #discard mangleName(forLoopVar)
    let call = t.sons[1]
    initLocExpr(p, call.sons[1], rangeA)
    initLocExpr(p, call.sons[2], rangeB)

    lineF(p, cpsStmts, "#pragma omp $4$n" &
                        "for ($1 = $2; $1 <= $3; ++$1)",
                        [forLoopVar.loc.rdLoc,
                        rangeA.rdLoc, rangeB.rdLoc,
                        call.sons[3].getStr.rope])

    p.breakIdx = startBlock(p)
    p.blocks[p.breakIdx].isLoop = true
    genStmts(p, t.sons[2])
    endBlock(p)

  dec(p.withinLoop)

proc genBreakStmt(p: BProc, t: PNode) =
  var idx = p.breakIdx
  if t.sons[0].kind != nkEmpty:
    # named break?
    assert(t.sons[0].kind == nkSym)
    var sym = t.sons[0].sym
    doAssert(sym.loc.k == locOther)
    idx = sym.position-1
  else:
    # an unnamed 'break' can only break a loop after 'transf' pass:
    while idx >= 0 and not p.blocks[idx].isLoop: dec idx
    if idx < 0 or not p.blocks[idx].isLoop:
      internalError(p.config, t.info, "no loop to break")
  let label = assignLabel(p.blocks[idx])
  blockLeaveActions(p,
    p.nestedTryStmts.len - p.blocks[idx].nestedTryStmts,
    p.inExceptBlockLen - p.blocks[idx].nestedExceptStmts)
  genLineDir(p, t)
  lineF(p, cpsStmts, "goto $1;$n", [label])

proc genRaiseStmt(p: BProc, t: PNode) =
  if p.module.compileToCpp:
    discard cgsym(p.module, "popCurrentExceptionEx")
  if p.nestedTryStmts.len > 0 and p.nestedTryStmts[^1].inExcept:
    # if the current try stmt have a finally block,
    # we must execute it before reraising
    var finallyBlock = p.nestedTryStmts[^1].n[^1]
    if finallyBlock.kind == nkFinally:
      genSimpleBlock(p, finallyBlock[0])
  if t[0].kind != nkEmpty:
    var a: TLoc
    initLocExprSingleUse(p, t[0], a)
    var e = rdLoc(a)
    var typ = skipTypes(t[0].typ, abstractPtrs)
    genLineDir(p, t)
    if isImportedException(typ, p.config):
      lineF(p, cpsStmts, "throw $1;$n", [e])
    else:
      lineCg(p, cpsStmts, "#raiseExceptionEx((#Exception*)$1, $2, $3, $4, $5);$n",
          [e, makeCString(typ.sym.name.s),
          makeCString(if p.prc != nil: p.prc.name.s else: p.module.module.name.s),
          makeCString(toFileName(p.config, t.info)), rope(toLinenumber(t.info))])
  else:
    genLineDir(p, t)
    # reraise the last exception:
    if p.module.compileToCpp and optNoCppExceptions notin p.config.globalOptions:
      line(p, cpsStmts, ~"throw;$n")
    else:
      linefmt(p, cpsStmts, "#reraiseException();$n")

proc genCaseGenericBranch(p: BProc, b: PNode, e: TLoc,
                          rangeFormat, eqFormat: FormatStr, labl: TLabel) =
  var
    x, y: TLoc
  var length = sonsLen(b)
  for i in countup(0, length - 2):
    if b.sons[i].kind == nkRange:
      initLocExpr(p, b.sons[i].sons[0], x)
      initLocExpr(p, b.sons[i].sons[1], y)
      lineCg(p, cpsStmts, rangeFormat,
           [rdCharLoc(e), rdCharLoc(x), rdCharLoc(y), labl])
    else:
      initLocExpr(p, b.sons[i], x)
      lineCg(p, cpsStmts, eqFormat, [rdCharLoc(e), rdCharLoc(x), labl])

proc genCaseSecondPass(p: BProc, t: PNode, d: var TLoc,
                       labId, until: int): TLabel =
  var lend = getLabel(p)
  for i in 1..until:
    # bug #4230: avoid false sharing between branches:
    if d.k == locTemp and isEmptyType(t.typ): d.k = locNone
    lineF(p, cpsStmts, "LA$1_: ;$n", [rope(labId + i)])
    if t.sons[i].kind == nkOfBranch:
      var length = sonsLen(t.sons[i])
      exprBlock(p, t.sons[i].sons[length - 1], d)
      lineF(p, cpsStmts, "goto $1;$n", [lend])
    else:
      exprBlock(p, t.sons[i].sons[0], d)
  result = lend

proc genIfForCaseUntil(p: BProc, t: PNode, d: var TLoc,
                       rangeFormat, eqFormat: FormatStr,
                       until: int, a: TLoc): TLabel =
  # generate a C-if statement for a Nim case statement
  var labId = p.labels
  for i in 1..until:
    inc(p.labels)
    if t.sons[i].kind == nkOfBranch: # else statement
      genCaseGenericBranch(p, t.sons[i], a, rangeFormat, eqFormat,
                           "LA" & rope(p.labels) & "_")
    else:
      lineF(p, cpsStmts, "goto LA$1_;$n", [rope(p.labels)])
  if until < t.len-1:
    inc(p.labels)
    var gotoTarget = p.labels
    lineF(p, cpsStmts, "goto LA$1_;$n", [rope(gotoTarget)])
    result = genCaseSecondPass(p, t, d, labId, until)
    lineF(p, cpsStmts, "LA$1_: ;$n", [rope(gotoTarget)])
  else:
    result = genCaseSecondPass(p, t, d, labId, until)

proc genCaseGeneric(p: BProc, t: PNode, d: var TLoc,
                    rangeFormat, eqFormat: FormatStr) =
  var a: TLoc
  initLocExpr(p, t.sons[0], a)
  var lend = genIfForCaseUntil(p, t, d, rangeFormat, eqFormat, sonsLen(t)-1, a)
  fixLabel(p, lend)

proc genCaseStringBranch(p: BProc, b: PNode, e: TLoc, labl: TLabel,
                         branches: var openArray[Rope]) =
  var x: TLoc
  var length = sonsLen(b)
  for i in countup(0, length - 2):
    assert(b.sons[i].kind != nkRange)
    initLocExpr(p, b.sons[i], x)
    assert(b.sons[i].kind in {nkStrLit..nkTripleStrLit})
    var j = int(hashString(p.config, b.sons[i].strVal) and high(branches))
    appcg(p.module, branches[j], "if (#eqStrings($1, $2)) goto $3;$n",
         [rdLoc(e), rdLoc(x), labl])

proc genStringCase(p: BProc, t: PNode, d: var TLoc) =
  # count how many constant strings there are in the case:
  var strings = 0
  for i in countup(1, sonsLen(t) - 1):
    if t.sons[i].kind == nkOfBranch: inc(strings, sonsLen(t.sons[i]) - 1)
  if strings > stringCaseThreshold:
    var bitMask = math.nextPowerOfTwo(strings) - 1
    var branches: seq[Rope]
    newSeq(branches, bitMask + 1)
    var a: TLoc
    initLocExpr(p, t.sons[0], a) # fist pass: gnerate ifs+goto:
    var labId = p.labels
    for i in countup(1, sonsLen(t) - 1):
      inc(p.labels)
      if t.sons[i].kind == nkOfBranch:
        genCaseStringBranch(p, t.sons[i], a, "LA" & rope(p.labels) & "_",
                            branches)
      else:
        # else statement: nothing to do yet
        # but we reserved a label, which we use later
        discard
    linefmt(p, cpsStmts, "switch (#hashString($1) & $2) {$n",
            rdLoc(a), rope(bitMask))
    for j in countup(0, high(branches)):
      if branches[j] != nil:
        lineF(p, cpsStmts, "case $1: $n$2break;$n",
             [intLiteral(j), branches[j]])
    lineF(p, cpsStmts, "}$n", []) # else statement:
    if t.sons[sonsLen(t)-1].kind != nkOfBranch:
      lineF(p, cpsStmts, "goto LA$1_;$n", [rope(p.labels)])
    # third pass: generate statements
    var lend = genCaseSecondPass(p, t, d, labId, sonsLen(t)-1)
    fixLabel(p, lend)
  else:
    genCaseGeneric(p, t, d, "", "if (#eqStrings($1, $2)) goto $3;$n")

proc branchHasTooBigRange(b: PNode): bool =
  for i in countup(0, sonsLen(b)-2):
    # last son is block
    if (b.sons[i].kind == nkRange) and
        b.sons[i].sons[1].intVal - b.sons[i].sons[0].intVal > RangeExpandLimit:
      return true

proc ifSwitchSplitPoint(p: BProc, n: PNode): int =
  for i in 1..n.len-1:
    var branch = n[i]
    var stmtBlock = lastSon(branch)
    if stmtBlock.stmtsContainPragma(wLinearScanEnd):
      result = i
    elif hasSwitchRange notin CC[p.config.cCompiler].props:
      if branch.kind == nkOfBranch and branchHasTooBigRange(branch):
        result = i

proc genCaseRange(p: BProc, branch: PNode) =
  var length = branch.len
  for j in 0 .. length-2:
    if branch[j].kind == nkRange:
      if hasSwitchRange in CC[p.config.cCompiler].props:
        lineF(p, cpsStmts, "case $1 ... $2:$n", [
            genLiteral(p, branch[j][0]),
            genLiteral(p, branch[j][1])])
      else:
        var v = copyNode(branch[j][0])
        while v.intVal <= branch[j][1].intVal:
          lineF(p, cpsStmts, "case $1:$n", [genLiteral(p, v)])
          inc(v.intVal)
    else:
      lineF(p, cpsStmts, "case $1:$n", [genLiteral(p, branch[j])])

proc genOrdinalCase(p: BProc, n: PNode, d: var TLoc) =
  # analyse 'case' statement:
  var splitPoint = ifSwitchSplitPoint(p, n)

  # generate if part (might be empty):
  var a: TLoc
  initLocExpr(p, n.sons[0], a)
  var lend = if splitPoint > 0: genIfForCaseUntil(p, n, d,
                    rangeFormat = "if ($1 >= $2 && $1 <= $3) goto $4;$n",
                    eqFormat = "if ($1 == $2) goto $3;$n",
                    splitPoint, a) else: nil

  # generate switch part (might be empty):
  if splitPoint+1 < n.len:
    lineF(p, cpsStmts, "switch ($1) {$n", [rdCharLoc(a)])
    var hasDefault = false
    for i in splitPoint+1 ..< n.len:
      # bug #4230: avoid false sharing between branches:
      if d.k == locTemp and isEmptyType(n.typ): d.k = locNone
      var branch = n[i]
      if branch.kind == nkOfBranch:
        genCaseRange(p, branch)
      else:
        # else part of case statement:
        lineF(p, cpsStmts, "default:$n", [])
        hasDefault = true
      exprBlock(p, branch.lastSon, d)
      lineF(p, cpsStmts, "break;$n", [])
    if (hasAssume in CC[p.config.cCompiler].props) and not hasDefault:
      lineF(p, cpsStmts, "default: __assume(0);$n", [])
    lineF(p, cpsStmts, "}$n", [])
  if lend != nil: fixLabel(p, lend)

proc genCase(p: BProc, t: PNode, d: var TLoc) =
  genLineDir(p, t)
  if not isEmptyType(t.typ) and d.k == locNone:
    getTemp(p, t.typ, d)
  case skipTypes(t.sons[0].typ, abstractVarRange).kind
  of tyString:
    genStringCase(p, t, d)
  of tyFloat..tyFloat128:
    genCaseGeneric(p, t, d, "if ($1 >= $2 && $1 <= $3) goto $4;$n",
                            "if ($1 == $2) goto $3;$n")
  else:
    if t.sons[0].kind == nkSym and sfGoto in t.sons[0].sym.flags:
      genGotoForCase(p, t)
    else:
      genOrdinalCase(p, t, d)

proc genRestoreFrameAfterException(p: BProc) =
  if optStackTrace in p.module.config.options:
    if not p.hasCurFramePointer:
      p.hasCurFramePointer = true
      p.procSec(cpsLocals).add(ropecg(p.module, "\tTFrame* _nimCurFrame;$n", []))
      p.procSec(cpsInit).add(ropecg(p.module, "\t_nimCurFrame = #getFrame();$n", []))
    linefmt(p, cpsStmts, "#setFrame(_nimCurFrame);$n")

proc genTryCpp(p: BProc, t: PNode, d: var TLoc) =
  # code to generate:
  #
  #   try
  #   {
  #      myDiv(4, 9);
  #   } catch (NimExceptionType1&) {
  #      body
  #   } catch (NimExceptionType2&) {
  #      finallyPart()
  #      raise;
  #   }
  #   catch(...) {
  #     general_handler_body
  #   }
  #   finallyPart();

  template genExceptBranchBody(body: PNode) {.dirty.} =
    genRestoreFrameAfterException(p)
    expr(p, body, d)

  if not isEmptyType(t.typ) and d.k == locNone:
    getTemp(p, t.typ, d)
  genLineDir(p, t)
  discard cgsym(p.module, "popCurrentExceptionEx")
  add(p.nestedTryStmts, (t, false))
  startBlock(p, "try {$n")
  expr(p, t[0], d)
  endBlock(p)

  var catchAllPresent = false

  p.nestedTryStmts[^1].inExcept = true
  for i in 1..<t.len:
    if t[i].kind != nkExceptBranch: break

    # bug #4230: avoid false sharing between branches:
    if d.k == locTemp and isEmptyType(t.typ): d.k = locNone

    if t[i].len == 1:
      # general except section:
      catchAllPresent = true
      startBlock(p, "catch (...) {$n")
      genExceptBranchBody(t[i][0])
      endBlock(p)
    else:
      for j in 0..t[i].len-2:
        if t[i][j].isInfixAs():
          let exvar = t[i][j][2] # ex1 in `except ExceptType as ex1:`
          fillLoc(exvar.sym.loc, locTemp, exvar, mangleLocalName(p, exvar.sym), OnUnknown)
          startBlock(p, "catch ($1& $2) {$n", getTypeDesc(p.module, t[i][j][1].typ), rdLoc(exvar.sym.loc))
        else:
          startBlock(p, "catch ($1&) {$n", getTypeDesc(p.module, t[i][j].typ))
        genExceptBranchBody(t[i][^1])  # exception handler body will duplicated for every type
        endBlock(p)

  discard pop(p.nestedTryStmts)

  if t[^1].kind == nkFinally:
    # c++ does not have finally, therefore code needs to be generated twice
    if not catchAllPresent:
      # finally requires catch all presence
      startBlock(p, "catch (...) {$n")
      genStmts(p, t[^1][0])
      line(p, cpsStmts, ~"throw;$n")
      endBlock(p)

    genSimpleBlock(p, t[^1][0])

proc genTry(p: BProc, t: PNode, d: var TLoc) =
  # code to generate:
  #
  # XXX: There should be a standard dispatch algorithm
  # that's used both here and with multi-methods
  #
  #  TSafePoint sp;
  #  pushSafePoint(&sp);
  #  sp.status = setjmp(sp.context);
  #  if (sp.status == 0) {
  #    myDiv(4, 9);
  #    popSafePoint();
  #  } else {
  #    popSafePoint();
  #    /* except DivisionByZero: */
  #    if (sp.status == DivisionByZero) {
  #      printf('Division by Zero\n');
  #      clearException();
  #    } else {
  #      clearException();
  #    }
  #  }
  #  {
  #    /* finally: */
  #    printf('fin!\n');
  #  }
  #  if (exception not cleared)
  #    propagateCurrentException();
  #
  if not isEmptyType(t.typ) and d.k == locNone:
    getTemp(p, t.typ, d)
  p.module.includeHeader("<setjmp.h>")
  genLineDir(p, t)
  var safePoint = getTempName(p.module)
  discard cgsym(p.module, "Exception")
  linefmt(p, cpsLocals, "#TSafePoint $1;$n", safePoint)
  linefmt(p, cpsStmts, "#pushSafePoint(&$1);$n", safePoint)
  if isDefined(p.config, "nimStdSetjmp"):
    linefmt(p, cpsStmts, "$1.status = setjmp($1.context);$n", safePoint)
  elif isDefined(p.config, "nimSigSetjmp"):
    linefmt(p, cpsStmts, "$1.status = sigsetjmp($1.context, 0);$n", safePoint)
  elif isDefined(p.config, "nimRawSetjmp"):
    linefmt(p, cpsStmts, "$1.status = _setjmp($1.context);$n", safePoint)
  else:
    linefmt(p, cpsStmts, "$1.status = setjmp($1.context);$n", safePoint)
  startBlock(p, "if ($1.status == 0) {$n", [safePoint])
  var length = sonsLen(t)
  add(p.nestedTryStmts, (t, false))
  expr(p, t.sons[0], d)
  linefmt(p, cpsStmts, "#popSafePoint();$n")
  endBlock(p)
  startBlock(p, "else {$n")
  linefmt(p, cpsStmts, "#popSafePoint();$n")
  genRestoreFrameAfterException(p)
  p.nestedTryStmts[^1].inExcept = true
  var i = 1
  while (i < length) and (t.sons[i].kind == nkExceptBranch):
    # bug #4230: avoid false sharing between branches:
    if d.k == locTemp and isEmptyType(t.typ): d.k = locNone
    var blen = sonsLen(t.sons[i])
    if blen == 1:
      # general except section:
      if i > 1: lineF(p, cpsStmts, "else", [])
      startBlock(p)
      linefmt(p, cpsStmts, "$1.status = 0;$n", safePoint)
      expr(p, t.sons[i].sons[0], d)
      linefmt(p, cpsStmts, "#popCurrentException();$n")
      endBlock(p)
    else:
      var orExpr: Rope = nil
      for j in countup(0, blen - 2):
        assert(t.sons[i].sons[j].kind == nkType)
        if orExpr != nil: add(orExpr, "||")
        let isObjFormat = if not p.module.compileToCpp:
          "#isObj(#getCurrentException()->Sup.m_type, $1)"
          else: "#isObj(#getCurrentException()->m_type, $1)"
        appcg(p.module, orExpr, isObjFormat,
              [genTypeInfo(p.module, t[i][j].typ, t[i][j].info)])
      if i > 1: line(p, cpsStmts, "else ")
      startBlock(p, "if ($1) {$n", [orExpr])
      linefmt(p, cpsStmts, "$1.status = 0;$n", safePoint)
      expr(p, t.sons[i].sons[blen-1], d)
      linefmt(p, cpsStmts, "#popCurrentException();$n")
      endBlock(p)
    inc(i)
  discard pop(p.nestedTryStmts)
  endBlock(p) # end of else block
  if i < length and t.sons[i].kind == nkFinally:
    p.finallySafePoints.add(safePoint)
    genSimpleBlock(p, t.sons[i].sons[0])
    discard pop(p.finallySafePoints)
  linefmt(p, cpsStmts, "if ($1.status != 0) #reraiseException();$n", safePoint)

proc genAsmOrEmitStmt(p: BProc, t: PNode, isAsmStmt=false): Rope =
  var res = ""
  for it in t.sons:
    case it.kind
    of nkStrLit..nkTripleStrLit:
      res.add(it.strVal)
    of nkSym:
      var sym = it.sym
      if sym.kind in {skProc, skFunc, skIterator, skMethod}:
        var a: TLoc
        initLocExpr(p, it, a)
        res.add($rdLoc(a))
      elif sym.kind == skType:
        res.add($getTypeDesc(p.module, sym.typ))
      else:
        discard getTypeDesc(p.module, skipTypes(sym.typ, abstractPtrs))
        var r = sym.loc.r
        if r == nil:
          # if no name has already been given,
          # it doesn't matter much:
          r = mangleName(p.module, sym)
          sym.loc.r = r       # but be consequent!
        res.add($r)
    of nkTypeOfExpr:
      res.add($getTypeDesc(p.module, it.typ))
    else:
      discard getTypeDesc(p.module, skipTypes(it.typ, abstractPtrs))
      var a: TLoc
      initLocExpr(p, it, a)
      res.add($a.rdLoc)

  if isAsmStmt and hasGnuAsm in CC[p.config.cCompiler].props:
    for x in splitLines(res):
      var j = 0
      while j < x.len and x[j] in {' ', '\t'}: inc(j)
      if j < x.len:
        if x[j] in {'"', ':'}:
          # don't modify the line if already in quotes or
          # some clobber register list:
          add(result, x); add(result, "\L")
        else:
          # ignore empty lines
          add(result, "\"")
          add(result, x)
          add(result, "\\n\"\n")
  else:
    res.add("\L")
    result = res.rope

proc genAsmStmt(p: BProc, t: PNode) =
  assert(t.kind == nkAsmStmt)
  genLineDir(p, t)
  var s = genAsmOrEmitStmt(p, t, isAsmStmt=true)
  # see bug #2362, "top level asm statements" seem to be a mis-feature
  # but even if we don't do this, the example in #2362 cannot possibly
  # work:
  if p.prc == nil:
    # top level asm statement?
    addf(p.module.s[cfsProcHeaders], CC[p.config.cCompiler].asmStmtFrmt, [s])
  else:
    lineF(p, cpsStmts, CC[p.config.cCompiler].asmStmtFrmt, [s])

proc determineSection(n: PNode): TCFileSection =
  result = cfsProcHeaders
  if n.len >= 1 and n.sons[0].kind in {nkStrLit..nkTripleStrLit}:
    let sec = n.sons[0].strVal
    if sec.startsWith("/*TYPESECTION*/"): result = cfsTypes
    elif sec.startsWith("/*VARSECTION*/"): result = cfsVars
    elif sec.startsWith("/*INCLUDESECTION*/"): result = cfsHeaders

proc genEmit(p: BProc, t: PNode) =
  var s = genAsmOrEmitStmt(p, t.sons[1])
  if p.prc == nil:
    # top level emit pragma?
    let section = determineSection(t[1])
    genCLineDir(p.module.s[section], t.info, p.config)
    add(p.module.s[section], s)
  else:
    genLineDir(p, t)
    line(p, cpsStmts, s)

proc genBreakPoint(p: BProc, t: PNode) =
  var name: string
  if optEndb in p.options:
    if t.kind == nkExprColonExpr:
      assert(t.sons[1].kind in {nkStrLit..nkTripleStrLit})
      name = normalize(t.sons[1].strVal)
    else:
      inc(p.module.g.breakPointId)
      name = "bp" & $p.module.g.breakPointId
    genLineDir(p, t)          # BUGFIX
    appcg(p.module, p.module.g.breakpoints,
         "#dbgRegisterBreakpoint($1, (NCSTRING)$2, (NCSTRING)$3);$n", [
        rope(toLinenumber(t.info)), makeCString(toFilename(p.config, t.info)),
        makeCString(name)])

proc genWatchpoint(p: BProc, n: PNode) =
  if optEndb notin p.options: return
  var a: TLoc
  initLocExpr(p, n.sons[1], a)
  let typ = skipTypes(n.sons[1].typ, abstractVarRange)
  lineCg(p, cpsStmts, "#dbgRegisterWatchpoint($1, (NCSTRING)$2, $3);$n",
        [addrLoc(p.config, a), makeCString(renderTree(n.sons[1])),
        genTypeInfo(p.module, typ, n.info)])

proc genPragma(p: BProc, n: PNode) =
  for it in n.sons:
    case whichPragma(it)
    of wEmit: genEmit(p, it)
    of wBreakpoint: genBreakPoint(p, it)
    of wWatchPoint: genWatchpoint(p, it)
    of wInjectStmt:
      var p = newProc(nil, p.module)
      p.options = p.options - {optLineTrace, optStackTrace}
      genStmts(p, it.sons[1])
      p.module.injectStmt = p.s(cpsStmts)
    else: discard

proc fieldDiscriminantCheckNeeded(p: BProc, asgn: PNode): bool =
  if optFieldCheck in p.options:
    var le = asgn.sons[0]
    if le.kind == nkCheckedFieldExpr:
      var field = le.sons[0].sons[1].sym
      result = sfDiscriminant in field.flags
    elif le.kind == nkDotExpr:
      var field = le.sons[1].sym
      result = sfDiscriminant in field.flags

proc genDiscriminantCheck(p: BProc, a, tmp: TLoc, objtype: PType,
                          field: PSym) =
  var t = skipTypes(objtype, abstractVar)
  assert t.kind == tyObject
  discard genTypeInfo(p.module, t, a.lode.info)
  var L = lengthOrd(p.config, field.typ)
  if not containsOrIncl(p.module.declaredThings, field.id):
    appcg(p.module, cfsVars, "extern $1",
          discriminatorTableDecl(p.module, t, field))
  lineCg(p, cpsStmts,
        "#FieldDiscriminantCheck((NI)(NU)($1), (NI)(NU)($2), $3, $4);$n",
        [rdLoc(a), rdLoc(tmp), discriminatorTableName(p.module, t, field),
         intLiteral(L+1)])

proc asgnFieldDiscriminant(p: BProc, e: PNode) =
  var a, tmp: TLoc
  var dotExpr = e.sons[0]
  if dotExpr.kind == nkCheckedFieldExpr: dotExpr = dotExpr.sons[0]
  initLocExpr(p, e.sons[0], a)
  getTemp(p, a.t, tmp)
  expr(p, e.sons[1], tmp)
  genDiscriminantCheck(p, a, tmp, dotExpr.sons[0].typ, dotExpr.sons[1].sym)
  genAssignment(p, a, tmp, {})

proc patchAsgnStmtListExpr(father, orig, n: PNode) =
  case n.kind
  of nkDerefExpr, nkHiddenDeref:
    let asgn = copyNode(orig)
    asgn.add orig[0]
    asgn.add n
    father.add asgn
  of nkStmtList, nkStmtListExpr:
    for x in n:
      patchAsgnStmtListExpr(father, orig, x)
  else:
    father.add n

proc genAsgn(p: BProc, e: PNode, fastAsgn: bool) =
  if e.sons[0].kind == nkSym and sfGoto in e.sons[0].sym.flags:
    genLineDir(p, e)
    genGotoVar(p, e.sons[1])
  elif not fieldDiscriminantCheckNeeded(p, e):
    # this fixes bug #6422 but we really need to change the representation of
    # arrays in the backend...
    let le = e[0]
    let ri = e[1]
    var needsRepair = false
    var it = ri
    while it.kind in {nkStmtList, nkStmtListExpr}:
      it = it.lastSon
      needsRepair = true
    if it.kind in {nkDerefExpr, nkHiddenDeref} and needsRepair:
      var patchedTree = newNodeI(nkStmtList, e.info)
      patchAsgnStmtListExpr(patchedTree, e, ri)
      genStmts(p, patchedTree)
      return
    var a: TLoc
    discard getTypeDesc(p.module, le.typ.skipTypes(skipPtrs))
    if le.kind in {nkDerefExpr, nkHiddenDeref}:
      genDeref(p, le, a, enforceDeref=true)
    else:
      initLocExpr(p, le, a)
    if fastAsgn: incl(a.flags, lfNoDeepCopy)
    assert(a.t != nil)
    genLineDir(p, ri)
    loadInto(p, e.sons[0], ri, a)
  else:
    genLineDir(p, e)
    asgnFieldDiscriminant(p, e)

proc genStmts(p: BProc, t: PNode) =
  var a: TLoc

  let isPush = hintExtendedContext in p.config.notes
  if isPush: pushInfoContext(p.config, t.info)
  expr(p, t, a)
  if isPush: popInfoContext(p.config)
  internalAssert p.config, a.k in {locNone, locTemp, locLocalVar, locExpr}

# - String constants --------------------------------------------------------
# The code here is responsible that
# ``const x = ["a", "b"]`` works without hidden runtime creation code.
# The price is that seqs and strings are not purely a library
# implementation.

# ----- Version 1: GC'ed strings and seqs --------------------------------

proc genStringLiteralDataOnlyV1(m: BModule, s: string): Rope =
  discard cgsym(m, "TGenericSeq")
  result = getTempName(m)
  addf(m.s[cfsData], "STRING_LITERAL($1, $2, $3);$n",
       [result, makeCString(s), rope(len(s))])

proc genStringLiteralV1(m: BModule; n: PNode): Rope =
  if s.isNil:
    result = ropecg(m, "((#NimStringDesc*) NIM_NIL)", [])
  else:
    let id = nodeTableTestOrSet(m.dataCache, n, m.labels)
    if id == m.labels:
      # string literal not found in the cache:
      result = ropecg(m, "((#NimStringDesc*) &$1)",
                      [genStringLiteralDataOnlyV1(m, n.strVal)])
    else:
      result = ropecg(m, "((#NimStringDesc*) &$1$2)",
                      [m.tmpBase, rope(id)])

# ------ Version 2: destructor based strings and seqs -----------------------

proc genStringLiteralDataOnlyV2(m: BModule, s: string): Rope =
  result = getTempName(m)
  addf(m.s[cfsData], "static const struct {$n" &
       "  NI cap; void* allocator; NIM_CHAR data[$2];$n" &
       "} $1 = { $2, NIM_NIL, $3 };$n",
       [result, rope(len(s)), makeCString(s)])

proc genStringLiteralV2(m: BModule; n: PNode): Rope =
  let id = nodeTableTestOrSet(m.dataCache, n, m.labels)
  if id == m.labels:
    discard cgsym(m, "NimStrPayload")
    discard cgsym(m, "NimStringV2")
    # string literal not found in the cache:
    let pureLit = genStringLiteralDataOnlyV2(m, n.strVal)
    result = getTempName(m)
    addf(m.s[cfsData], "static const NimStringV2 $1 = {$2, (NimStrPayload*)&$3};$n",
          [result, rope(len(n.strVal)), pureLit])
  else:
    result = m.tmpBase & rope(id)

proc genStringLiteralV2Const(m: BModule; n: PNode): Rope =
  let id = nodeTableTestOrSet(m.dataCache, n, m.labels)
  var pureLit: Rope
  if id == m.labels:
    discard cgsym(m, "NimStrPayload")
    discard cgsym(m, "NimStringV2")
    # string literal not found in the cache:
    pureLit = genStringLiteralDataOnlyV2(m, n.strVal)
  else:
    pureLit = m.tmpBase & rope(id)
  result = "{$1, (NimStrPayload*)&$2}" % [rope(len(n.strVal)), pureLit]

# ------ Version selector ---------------------------------------------------

proc genStringLiteralDataOnly(m: BModule; s: string; info: TLineInfo): Rope =
  case detectStrVersion(m)
  of 0, 1: result = genStringLiteralDataOnlyV1(m, s)
  of 2: result = genStringLiteralDataOnlyV2(m, s)
  else:
    localError(m.config, info, "cannot determine how to produce code for string literal")

proc genStringLiteralFromData(m: BModule; data: Rope; info: TLineInfo): Rope =
  result = ropecg(m, "((#NimStringDesc*) &$1)",
                [data])

proc genNilStringLiteral(m: BModule; info: TLineInfo): Rope =
  result = ropecg(m, "((#NimStringDesc*) NIM_NIL)", [])

proc genStringLiteral(m: BModule; n: PNode): Rope =
  case detectStrVersion(m)
  of 0, 1: result = genStringLiteralV1(m, n)
  of 2: result = genStringLiteralV2(m, n)
  else:
    localError(m.config, n.info, "cannot determine how to produce code for string literal")


# -------------------------- constant expressions ------------------------

proc int64Literal(i: BiggestInt): Rope =
  if i > low(int64):
    result = "IL64($1)" % [rope(i)]
  else:
    result = ~"(IL64(-9223372036854775807) - IL64(1))"

proc uint64Literal(i: uint64): Rope = rope($i & "ULL")

proc intLiteral(i: BiggestInt): Rope =
  if i > low(int32) and i <= high(int32):
    result = rope(i)
  elif i == low(int32):
    # Nim has the same bug for the same reasons :-)
    result = ~"(-2147483647 -1)"
  elif i > low(int64):
    result = "IL64($1)" % [rope(i)]
  else:
    result = ~"(IL64(-9223372036854775807) - IL64(1))"

proc genLiteral(p: BProc, n: PNode, ty: PType): Rope =
  if ty == nil: internalError(p.config, n.info, "genLiteral: ty is nil")
  case n.kind
  of nkCharLit..nkUInt64Lit:
    case skipTypes(ty, abstractVarRange).kind
    of tyChar, tyNil:
      result = intLiteral(n.intVal)
    of tyBool:
      if n.intVal != 0: result = ~"NIM_TRUE"
      else: result = ~"NIM_FALSE"
    of tyInt64: result = int64Literal(n.intVal)
    of tyUInt64: result = uint64Literal(uint64(n.intVal))
    else:
      result = "(($1) $2)" % [getTypeDesc(p.module,
          ty), intLiteral(n.intVal)]
  of nkNilLit:
    let t = skipTypes(ty, abstractVarRange)
    if t.kind == tyProc and t.callConv == ccClosure:
      let id = nodeTableTestOrSet(p.module.dataCache, n, p.module.labels)
      result = p.module.tmpBase & rope(id)
      if id == p.module.labels:
        # not found in cache:
        inc(p.module.labels)
        addf(p.module.s[cfsData],
             "static NIM_CONST $1 $2 = {NIM_NIL,NIM_NIL};$n",
             [getTypeDesc(p.module, ty), result])
    else:
      result = rope("NIM_NIL")
  of nkStrLit..nkTripleStrLit:
    case skipTypes(ty, abstractVarRange + {tyStatic, tyUserTypeClass, tyUserTypeClassInst}).kind
    of tyNil:
      result = genNilStringLiteral(p.module, n.info)
    of tyString:
      # with the new semantics for 'nil' strings, we can map "" to nil and
      # save tons of allocations:
      if n.strVal.len == 0 and optNilSeqs notin p.options and
          p.config.selectedGc != gcDestructors:
        result = genNilStringLiteral(p.module, n.info)
      else:
        result = genStringLiteral(p.module, n)
    else:
      result = makeCString(n.strVal)
  of nkFloatLit, nkFloat64Lit:
    result = rope(n.floatVal.toStrMaxPrecision)
  of nkFloat32Lit:
    result = rope(n.floatVal.toStrMaxPrecision("f"))
  else:
    internalError(p.config, n.info, "genLiteral(" & $n.kind & ')')
    result = nil

proc genLiteral(p: BProc, n: PNode): Rope =
  result = genLiteral(p, n, n.typ)

proc bitSetToWord(s: TBitSet, size: int): BiggestInt =
  result = 0
  when true:
    for j in countup(0, size - 1):
      if j < len(s): result = result or `shl`(ze64(s[j]), j * 8)
  else:
    # not needed, too complex thinking:
    if CPU[platform.hostCPU].endian == CPU[targetCPU].endian:
      for j in countup(0, size - 1):
        if j < len(s): result = result or `shl`(Ze64(s[j]), j * 8)
    else:
      for j in countup(0, size - 1):
        if j < len(s): result = result or `shl`(Ze64(s[j]), (Size - 1 - j) * 8)

proc genRawSetData(cs: TBitSet, size: int): Rope =
  var frmt: FormatStr
  if size > 8:
    result = "{$n" % []
    for i in countup(0, size - 1):
      if i < size - 1:
        # not last iteration?
        if (i + 1) mod 8 == 0: frmt = "0x$1,$n"
        else: frmt = "0x$1, "
      else:
        frmt = "0x$1}$n"
      addf(result, frmt, [rope(toHex(ze64(cs[i]), 2))])
  else:
    result = intLiteral(bitSetToWord(cs, size))
    #  result := rope('0x' + ToHex(bitSetToWord(cs, size), size * 2))

proc genSetNode(p: BProc, n: PNode): Rope =
  var cs: TBitSet
  var size = int(getSize(p.config, n.typ))
  toBitSet(p.config, n, cs)
  if size > 8:
    let id = nodeTableTestOrSet(p.module.dataCache, n, p.module.labels)
    result = p.module.tmpBase & rope(id)
    if id == p.module.labels:
      # not found in cache:
      inc(p.module.labels)
      addf(p.module.s[cfsData], "static NIM_CONST $1 $2 = $3;$n",
           [getTypeDesc(p.module, n.typ), result, genRawSetData(cs, size)])
  else:
    result = genRawSetData(cs, size)

proc getStorageLoc(n: PNode): TStorageLoc =
  case n.kind
  of nkSym:
    case n.sym.kind
    of skParam, skTemp:
      result = OnStack
    of skVar, skForVar, skResult, skLet:
      if sfGlobal in n.sym.flags: result = OnHeap
      else: result = OnStack
    of skConst:
      if sfGlobal in n.sym.flags: result = OnHeap
      else: result = OnUnknown
    else: result = OnUnknown
  of nkDerefExpr, nkHiddenDeref:
    case n.sons[0].typ.kind
    of tyVar, tyLent: result = OnUnknown
    of tyPtr: result = OnStack
    of tyRef: result = OnHeap
    else: doAssert(false, "getStorageLoc")
  of nkBracketExpr, nkDotExpr, nkObjDownConv, nkObjUpConv:
    result = getStorageLoc(n.sons[0])
  else: result = OnUnknown

proc canMove(p: BProc, n: PNode): bool =
  # for now we're conservative here:
  if n.kind == nkBracket:
    # This needs to be kept consistent with 'const' seq code
    # generation!
    if not isDeepConstExpr(n) or n.len == 0:
      if skipTypes(n.typ, abstractVarRange).kind == tySequence:
        return true
  elif optNilSeqs notin p.options and
    n.kind in nkStrKinds and n.strVal.len == 0:
    # Empty strings are codegen'd as NIM_NIL so it's just a pointer copy
    return true
  result = n.kind in nkCallKinds
  #if result:
  #  echo n.info, " optimized ", n
  #  result = false

proc genRefAssign(p: BProc, dest, src: TLoc, flags: TAssignmentFlags) =
  if (dest.storage == OnStack and p.config.selectedGC != gcGo) or not usesWriteBarrier(p.config):
    linefmt(p, cpsStmts, "$1 = $2;$n", rdLoc(dest), rdLoc(src))
  elif dest.storage == OnHeap:
    # location is on heap
    # now the writer barrier is inlined for performance:
    #
    #    if afSrcIsNotNil in flags:
    #      UseMagic(p.module, 'nimGCref')
    #      lineF(p, cpsStmts, 'nimGCref($1);$n', [rdLoc(src)])
    #    elif afSrcIsNil notin flags:
    #      UseMagic(p.module, 'nimGCref')
    #      lineF(p, cpsStmts, 'if ($1) nimGCref($1);$n', [rdLoc(src)])
    #    if afDestIsNotNil in flags:
    #      UseMagic(p.module, 'nimGCunref')
    #      lineF(p, cpsStmts, 'nimGCunref($1);$n', [rdLoc(dest)])
    #    elif afDestIsNil notin flags:
    #      UseMagic(p.module, 'nimGCunref')
    #      lineF(p, cpsStmts, 'if ($1) nimGCunref($1);$n', [rdLoc(dest)])
    #    lineF(p, cpsStmts, '$1 = $2;$n', [rdLoc(dest), rdLoc(src)])
    if canFormAcycle(dest.t):
      linefmt(p, cpsStmts, "#asgnRef((void**) $1, $2);$n",
              addrLoc(p.config, dest), rdLoc(src))
    else:
      linefmt(p, cpsStmts, "#asgnRefNoCycle((void**) $1, $2);$n",
              addrLoc(p.config, dest), rdLoc(src))
  else:
    linefmt(p, cpsStmts, "#unsureAsgnRef((void**) $1, $2);$n",
            addrLoc(p.config, dest), rdLoc(src))

proc asgnComplexity(n: PNode): int =
  if n != nil:
    case n.kind
    of nkSym: result = 1
    of nkRecCase:
      # 'case objects' are too difficult to inline their assignment operation:
      result = 100
    of nkRecList:
      for t in items(n):
        result += asgnComplexity(t)
    else: discard

proc optAsgnLoc(a: TLoc, t: PType, field: Rope): TLoc =
  assert field != nil
  result.k = locField
  result.storage = a.storage
  result.lode = lodeTyp t
  result.r = rdLoc(a) & "." & field

proc genOptAsgnTuple(p: BProc, dest, src: TLoc, flags: TAssignmentFlags) =
  let newflags =
    if src.storage == OnStatic:
      flags + {needToCopy}
    elif tfShallow in dest.t.flags:
      flags - {needToCopy}
    else:
      flags
  let t = skipTypes(dest.t, abstractInst).getUniqueType()
  for i in 0 ..< t.len:
    let t = t.sons[i]
    let field = "Field$1" % [i.rope]
    genAssignment(p, optAsgnLoc(dest, t, field),
                     optAsgnLoc(src, t, field), newflags)

proc genOptAsgnObject(p: BProc, dest, src: TLoc, flags: TAssignmentFlags,
                      t: PNode, typ: PType) =
  if t == nil: return
  let newflags =
    if src.storage == OnStatic:
      flags + {needToCopy}
    elif tfShallow in dest.t.flags:
      flags - {needToCopy}
    else:
      flags
  case t.kind
  of nkSym:
    let field = t.sym
    if field.loc.r == nil: fillObjectFields(p.module, typ)
    genAssignment(p, optAsgnLoc(dest, field.typ, field.loc.r),
                     optAsgnLoc(src, field.typ, field.loc.r), newflags)
  of nkRecList:
    for child in items(t): genOptAsgnObject(p, dest, src, newflags, child, typ)
  else: discard

proc genGenericAsgn(p: BProc, dest, src: TLoc, flags: TAssignmentFlags) =
  # Consider:
  # type TMyFastString {.shallow.} = string
  # Due to the implementation of pragmas this would end up to set the
  # tfShallow flag for the built-in string type too! So we check only
  # here for this flag, where it is reasonably safe to do so
  # (for objects, etc.):
  if p.config.selectedGC == gcDestructors:
    linefmt(p, cpsStmts,
        "$1.len = $2.len; $1.p = $2.p;$n",
        rdLoc(dest), rdLoc(src))
  elif needToCopy notin flags or
      tfShallow in skipTypes(dest.t, abstractVarRange).flags:
    if (dest.storage == OnStack and p.config.selectedGC != gcGo) or not usesWriteBarrier(p.config):
      linefmt(p, cpsStmts,
           "#nimCopyMem((void*)$1, (NIM_CONST void*)$2, sizeof($3));$n",
           addrLoc(p.config, dest), addrLoc(p.config, src), rdLoc(dest))
    else:
      linefmt(p, cpsStmts, "#genericShallowAssign((void*)$1, (void*)$2, $3);$n",
              addrLoc(p.config, dest), addrLoc(p.config, src), genTypeInfo(p.module, dest.t, dest.lode.info))
  else:
    linefmt(p, cpsStmts, "#genericAssign((void*)$1, (void*)$2, $3);$n",
            addrLoc(p.config, dest), addrLoc(p.config, src), genTypeInfo(p.module, dest.t, dest.lode.info))

proc genAssignment(p: BProc, dest, src: TLoc, flags: TAssignmentFlags) =
  # This function replaces all other methods for generating
  # the assignment operation in C.
  if src.t != nil and src.t.kind == tyPtr:
    # little HACK to support the new 'var T' as return type:
    linefmt(p, cpsStmts, "$1 = $2;$n", rdLoc(dest), rdLoc(src))
    return
  let ty = skipTypes(dest.t, abstractRange + tyUserTypeClasses + {tyStatic})
  case ty.kind
  of tyRef:
    genRefAssign(p, dest, src, flags)
  of tySequence:
    if p.config.selectedGC == gcDestructors:
      genGenericAsgn(p, dest, src, flags)
    elif (needToCopy notin flags and src.storage != OnStatic) or canMove(p, src.lode):
      genRefAssign(p, dest, src, flags)
    else:
      linefmt(p, cpsStmts, "#genericSeqAssign($1, $2, $3);$n",
              addrLoc(p.config, dest), rdLoc(src),
              genTypeInfo(p.module, dest.t, dest.lode.info))
  of tyString:
    if p.config.selectedGC == gcDestructors:
      genGenericAsgn(p, dest, src, flags)
    elif (needToCopy notin flags and src.storage != OnStatic) or canMove(p, src.lode):
      genRefAssign(p, dest, src, flags)
    else:
      if (dest.storage == OnStack and p.config.selectedGC != gcGo) or not usesWriteBarrier(p.config):
        linefmt(p, cpsStmts, "$1 = #copyString($2);$n", dest.rdLoc, src.rdLoc)
      elif dest.storage == OnHeap:
        # we use a temporary to care for the dreaded self assignment:
        var tmp: TLoc
        getTemp(p, ty, tmp)
        linefmt(p, cpsStmts, "$3 = $1; $1 = #copyStringRC1($2);$n",
                dest.rdLoc, src.rdLoc, tmp.rdLoc)
        linefmt(p, cpsStmts, "if ($1) #nimGCunrefNoCycle($1);$n", tmp.rdLoc)
      else:
        linefmt(p, cpsStmts, "#unsureAsgnRef((void**) $1, #copyString($2));$n",
               addrLoc(p.config, dest), rdLoc(src))
  of tyProc:
    if needsComplexAssignment(dest.t):
      # optimize closure assignment:
      let a = optAsgnLoc(dest, dest.t, "ClE_0".rope)
      let b = optAsgnLoc(src, dest.t, "ClE_0".rope)
      genRefAssign(p, a, b, flags)
      linefmt(p, cpsStmts, "$1.ClP_0 = $2.ClP_0;$n", rdLoc(dest), rdLoc(src))
    else:
      linefmt(p, cpsStmts, "$1 = $2;$n", rdLoc(dest), rdLoc(src))
  of tyTuple:
    if needsComplexAssignment(dest.t):
      if dest.t.len <= 4: genOptAsgnTuple(p, dest, src, flags)
      else: genGenericAsgn(p, dest, src, flags)
    else:
      linefmt(p, cpsStmts, "$1 = $2;$n", rdLoc(dest), rdLoc(src))
  of tyObject:
    # XXX: check for subtyping?
    if ty.isImportedCppType:
      linefmt(p, cpsStmts, "$1 = $2;$n", rdLoc(dest), rdLoc(src))
    elif not isObjLackingTypeField(ty):
      genGenericAsgn(p, dest, src, flags)
    elif needsComplexAssignment(ty):
      if ty.sons[0].isNil and asgnComplexity(ty.n) <= 4:
        discard getTypeDesc(p.module, ty)
        internalAssert p.config, ty.n != nil
        genOptAsgnObject(p, dest, src, flags, ty.n, ty)
      else:
        genGenericAsgn(p, dest, src, flags)
    else:
      linefmt(p, cpsStmts, "$1 = $2;$n", rdLoc(dest), rdLoc(src))
  of tyArray:
    if needsComplexAssignment(dest.t):
      genGenericAsgn(p, dest, src, flags)
    else:
      linefmt(p, cpsStmts,
           "#nimCopyMem((void*)$1, (NIM_CONST void*)$2, sizeof($3));$n",
           rdLoc(dest), rdLoc(src), getTypeDesc(p.module, dest.t))
  of tyOpenArray, tyVarargs:
    # open arrays are always on the stack - really? What if a sequence is
    # passed to an open array?
    if needsComplexAssignment(dest.t):
      linefmt(p, cpsStmts,     # XXX: is this correct for arrays?
           "#genericAssignOpenArray((void*)$1, (void*)$2, $1Len_0, $3);$n",
           addrLoc(p.config, dest), addrLoc(p.config, src),
           genTypeInfo(p.module, dest.t, dest.lode.info))
    else:
      linefmt(p, cpsStmts,
           # bug #4799, keep the nimCopyMem for a while
           #"#nimCopyMem((void*)$1, (NIM_CONST void*)$2, sizeof($1[0])*$1Len_0);$n",
           "$1 = $2;$n",
           rdLoc(dest), rdLoc(src))
  of tySet:
    if mapType(p.config, ty) == ctArray:
      linefmt(p, cpsStmts, "#nimCopyMem((void*)$1, (NIM_CONST void*)$2, $3);$n",
              rdLoc(dest), rdLoc(src), rope(getSize(p.config, dest.t)))
    else:
      linefmt(p, cpsStmts, "$1 = $2;$n", rdLoc(dest), rdLoc(src))
  of tyPtr, tyPointer, tyChar, tyBool, tyEnum, tyCString,
     tyInt..tyUInt64, tyRange, tyVar, tyLent:
    linefmt(p, cpsStmts, "$1 = $2;$n", rdLoc(dest), rdLoc(src))
  else: internalError(p.config, "genAssignment: " & $ty.kind)

  if optMemTracker in p.options and dest.storage in {OnHeap, OnUnknown}:
    #writeStackTrace()
    #echo p.currLineInfo, " requesting"
    linefmt(p, cpsStmts, "#memTrackerWrite((void*)$1, $2, $3, $4);$n",
            addrLoc(p.config, dest), rope getSize(p.config, dest.t),
            makeCString(toFullPath(p.config, p.currLineInfo)),
            rope p.currLineInfo.safeLineNm)

proc genDeepCopy(p: BProc; dest, src: TLoc) =
  template addrLocOrTemp(a: TLoc): Rope =
    if a.k == locExpr:
      var tmp: TLoc
      getTemp(p, a.t, tmp)
      genAssignment(p, tmp, a, {})
      addrLoc(p.config, tmp)
    else:
      addrLoc(p.config, a)

  var ty = skipTypes(dest.t, abstractVarRange + {tyStatic})
  case ty.kind
  of tyPtr, tyRef, tyProc, tyTuple, tyObject, tyArray:
    # XXX optimize this
    linefmt(p, cpsStmts, "#genericDeepCopy((void*)$1, (void*)$2, $3);$n",
            addrLoc(p.config, dest), addrLocOrTemp(src),
            genTypeInfo(p.module, dest.t, dest.lode.info))
  of tySequence, tyString:
    linefmt(p, cpsStmts, "#genericSeqDeepCopy($1, $2, $3);$n",
            addrLoc(p.config, dest), rdLoc(src),
            genTypeInfo(p.module, dest.t, dest.lode.info))
  of tyOpenArray, tyVarargs:
    linefmt(p, cpsStmts,
         "#genericDeepCopyOpenArray((void*)$1, (void*)$2, $1Len_0, $3);$n",
         addrLoc(p.config, dest), addrLocOrTemp(src),
         genTypeInfo(p.module, dest.t, dest.lode.info))
  of tySet:
    if mapType(p.config, ty) == ctArray:
      linefmt(p, cpsStmts, "#nimCopyMem((void*)$1, (NIM_CONST void*)$2, $3);$n",
              rdLoc(dest), rdLoc(src), rope(getSize(p.config, dest.t)))
    else:
      linefmt(p, cpsStmts, "$1 = $2;$n", rdLoc(dest), rdLoc(src))
  of tyPointer, tyChar, tyBool, tyEnum, tyCString,
     tyInt..tyUInt64, tyRange, tyVar, tyLent:
    linefmt(p, cpsStmts, "$1 = $2;$n", rdLoc(dest), rdLoc(src))
  else: internalError(p.config, "genDeepCopy: " & $ty.kind)

proc putLocIntoDest(p: BProc, d: var TLoc, s: TLoc) =
  if d.k != locNone:
    if lfNoDeepCopy in d.flags: genAssignment(p, d, s, {})
    else: genAssignment(p, d, s, {needToCopy})
  else:
    d = s # ``d`` is free, so fill it with ``s``

proc putDataIntoDest(p: BProc, d: var TLoc, n: PNode, r: Rope) =
  var a: TLoc
  if d.k != locNone:
    # need to generate an assignment here
    initLoc(a, locData, n, OnStatic)
    a.r = r
    if lfNoDeepCopy in d.flags: genAssignment(p, d, a, {})
    else: genAssignment(p, d, a, {needToCopy})
  else:
    # we cannot call initLoc() here as that would overwrite
    # the flags field!
    d.k = locData
    d.lode = n
    d.r = r

proc putIntoDest(p: BProc, d: var TLoc, n: PNode, r: Rope; s=OnUnknown) =
  var a: TLoc
  if d.k != locNone:
    # need to generate an assignment here
    initLoc(a, locExpr, n, s)
    a.r = r
    if lfNoDeepCopy in d.flags: genAssignment(p, d, a, {})
    else: genAssignment(p, d, a, {needToCopy})
  else:
    # we cannot call initLoc() here as that would overwrite
    # the flags field!
    d.k = locExpr
    d.lode = n
    d.r = r

proc binaryStmt(p: BProc, e: PNode, d: var TLoc, frmt: string) =
  var a, b: TLoc
  if d.k != locNone: internalError(p.config, e.info, "binaryStmt")
  initLocExpr(p, e.sons[1], a)
  initLocExpr(p, e.sons[2], b)
  lineCg(p, cpsStmts, frmt, rdLoc(a), rdLoc(b))

proc binaryStmtAddr(p: BProc, e: PNode, d: var TLoc, frmt: string) =
  var a, b: TLoc
  if d.k != locNone: internalError(p.config, e.info, "binaryStmtAddr")
  initLocExpr(p, e.sons[1], a)
  initLocExpr(p, e.sons[2], b)
  lineCg(p, cpsStmts, frmt, addrLoc(p.config, a), rdLoc(b))

proc unaryStmt(p: BProc, e: PNode, d: var TLoc, frmt: string) =
  var a: TLoc
  if d.k != locNone: internalError(p.config, e.info, "unaryStmt")
  initLocExpr(p, e.sons[1], a)
  lineCg(p, cpsStmts, frmt, [rdLoc(a)])

proc binaryExpr(p: BProc, e: PNode, d: var TLoc, frmt: string) =
  var a, b: TLoc
  assert(e.sons[1].typ != nil)
  assert(e.sons[2].typ != nil)
  initLocExpr(p, e.sons[1], a)
  initLocExpr(p, e.sons[2], b)
  putIntoDest(p, d, e, ropecg(p.module, frmt, [rdLoc(a), rdLoc(b)]))

proc binaryExprChar(p: BProc, e: PNode, d: var TLoc, frmt: string) =
  var a, b: TLoc
  assert(e.sons[1].typ != nil)
  assert(e.sons[2].typ != nil)
  initLocExpr(p, e.sons[1], a)
  initLocExpr(p, e.sons[2], b)
  putIntoDest(p, d, e, ropecg(p.module, frmt, [a.rdCharLoc, b.rdCharLoc]))

proc unaryExpr(p: BProc, e: PNode, d: var TLoc, frmt: string) =
  var a: TLoc
  initLocExpr(p, e.sons[1], a)
  putIntoDest(p, d, e, ropecg(p.module, frmt, [rdLoc(a)]))

proc unaryExprChar(p: BProc, e: PNode, d: var TLoc, frmt: string) =
  var a: TLoc
  initLocExpr(p, e.sons[1], a)
  putIntoDest(p, d, e, ropecg(p.module, frmt, [rdCharLoc(a)]))

proc binaryArithOverflowRaw(p: BProc, t: PType, a, b: TLoc;
                            frmt: string): Rope =
  var size = getSize(p.config, t)
  let storage = if size < p.config.target.intSize: rope("NI")
                else: getTypeDesc(p.module, t)
  result = getTempName(p.module)
  linefmt(p, cpsLocals, "$1 $2;$n", storage, result)
  lineCg(p, cpsStmts, frmt, result, rdCharLoc(a), rdCharLoc(b))
  if size < p.config.target.intSize or t.kind in {tyRange, tyEnum}:
    linefmt(p, cpsStmts, "if ($1 < $2 || $1 > $3) #raiseOverflow();$n",
            result, intLiteral(firstOrd(p.config, t)), intLiteral(lastOrd(p.config, t)))

proc binaryArithOverflow(p: BProc, e: PNode, d: var TLoc, m: TMagic) =
  const
    prc: array[mAddI..mPred, string] = [
      "$# = #addInt($#, $#);$n", "$# = #subInt($#, $#);$n",
      "$# = #mulInt($#, $#);$n", "$# = #divInt($#, $#);$n",
      "$# = #modInt($#, $#);$n",
      "$# = #addInt($#, $#);$n", "$# = #subInt($#, $#);$n"]
    prc64: array[mAddI..mPred, string] = [
      "$# = #addInt64($#, $#);$n", "$# = #subInt64($#, $#);$n",
      "$# = #mulInt64($#, $#);$n", "$# = #divInt64($#, $#);$n",
      "$# = #modInt64($#, $#);$n",
      "$# = #addInt64($#, $#);$n", "$# = #subInt64($#, $#);$n"]
    opr: array[mAddI..mPred, string] = [
      "($#)($# + $#)", "($#)($# - $#)", "($#)($# * $#)",
      "($#)($# / $#)", "($#)($# % $#)",
      "($#)($# + $#)", "($#)($# - $#)"]
  var a, b: TLoc
  assert(e.sons[1].typ != nil)
  assert(e.sons[2].typ != nil)
  initLocExpr(p, e.sons[1], a)
  initLocExpr(p, e.sons[2], b)
  # skipping 'range' is correct here as we'll generate a proper range check
  # later via 'chckRange'
  let t = e.typ.skipTypes(abstractRange)
  if optOverflowCheck notin p.options:
    let res = opr[m] % [getTypeDesc(p.module, e.typ), rdLoc(a), rdLoc(b)]
    putIntoDest(p, d, e, res)
  else:
    let res = binaryArithOverflowRaw(p, t, a, b,
                                   if t.kind == tyInt64: prc64[m] else: prc[m])
    putIntoDest(p, d, e, "($#)($#)" % [getTypeDesc(p.module, e.typ), res])

proc unaryArithOverflow(p: BProc, e: PNode, d: var TLoc, m: TMagic) =
  const
    opr: array[mUnaryMinusI..mAbsI, string] = [
      mUnaryMinusI: "((NI$2)-($1))",
      mUnaryMinusI64: "-($1)",
      mAbsI: "($1 > 0? ($1) : -($1))"]
  var
    a: TLoc
    t: PType
  assert(e.sons[1].typ != nil)
  initLocExpr(p, e.sons[1], a)
  t = skipTypes(e.typ, abstractRange)
  if optOverflowCheck in p.options:
    linefmt(p, cpsStmts, "if ($1 == $2) #raiseOverflow();$n",
            rdLoc(a), intLiteral(firstOrd(p.config, t)))
  putIntoDest(p, d, e, opr[m] % [rdLoc(a), rope(getSize(p.config, t) * 8)])

proc binaryArith(p: BProc, e: PNode, d: var TLoc, op: TMagic) =
  const
    binArithTab: array[mAddF64..mXor, string] = [
      "(($4)($1) + ($4)($2))", # AddF64
      "(($4)($1) - ($4)($2))", # SubF64
      "(($4)($1) * ($4)($2))", # MulF64
      "(($4)($1) / ($4)($2))", # DivF64
      "($4)((NU$5)($1) >> (NU$3)($2))", # ShrI
      "($4)((NU$3)($1) << (NU$3)($2))", # ShlI
      "($4)((NI$3)($1) >> (NU$3)($2))", # AshrI
      "($4)($1 & $2)",      # BitandI
      "($4)($1 | $2)",      # BitorI
      "($4)($1 ^ $2)",      # BitxorI
      "(($1 <= $2) ? $1 : $2)", # MinI
      "(($1 >= $2) ? $1 : $2)", # MaxI
      "(($1 <= $2) ? $1 : $2)", # MinF64
      "(($1 >= $2) ? $1 : $2)", # MaxF64
      "($4)((NU$3)($1) + (NU$3)($2))", # AddU
      "($4)((NU$3)($1) - (NU$3)($2))", # SubU
      "($4)((NU$3)($1) * (NU$3)($2))", # MulU
      "($4)((NU$3)($1) / (NU$3)($2))", # DivU
      "($4)((NU$3)($1) % (NU$3)($2))", # ModU
      "($1 == $2)",           # EqI
      "($1 <= $2)",           # LeI
      "($1 < $2)",            # LtI
      "($1 == $2)",           # EqF64
      "($1 <= $2)",           # LeF64
      "($1 < $2)",            # LtF64
      "((NU$3)($1) <= (NU$3)($2))", # LeU
      "((NU$3)($1) < (NU$3)($2))", # LtU
      "((NU64)($1) <= (NU64)($2))", # LeU64
      "((NU64)($1) < (NU64)($2))", # LtU64
      "($1 == $2)",           # EqEnum
      "($1 <= $2)",           # LeEnum
      "($1 < $2)",            # LtEnum
      "((NU8)($1) == (NU8)($2))", # EqCh
      "((NU8)($1) <= (NU8)($2))", # LeCh
      "((NU8)($1) < (NU8)($2))", # LtCh
      "($1 == $2)",           # EqB
      "($1 <= $2)",           # LeB
      "($1 < $2)",            # LtB
      "($1 == $2)",           # EqRef
      "($1 == $2)",           # EqPtr
      "($1 <= $2)",           # LePtr
      "($1 < $2)",            # LtPtr
      "($1 != $2)"]           # Xor
  var
    a, b: TLoc
    s, k: BiggestInt
  assert(e.sons[1].typ != nil)
  assert(e.sons[2].typ != nil)
  initLocExpr(p, e.sons[1], a)
  initLocExpr(p, e.sons[2], b)
  # BUGFIX: cannot use result-type here, as it may be a boolean
  s = max(getSize(p.config, a.t), getSize(p.config, b.t)) * 8
  k = getSize(p.config, a.t) * 8
  putIntoDest(p, d, e,
              binArithTab[op] % [rdLoc(a), rdLoc(b), rope(s),
                                      getSimpleTypeDesc(p.module, e.typ), rope(k)])

proc genEqProc(p: BProc, e: PNode, d: var TLoc) =
  var a, b: TLoc
  assert(e.sons[1].typ != nil)
  assert(e.sons[2].typ != nil)
  initLocExpr(p, e.sons[1], a)
  initLocExpr(p, e.sons[2], b)
  if a.t.skipTypes(abstractInst).callConv == ccClosure:
    putIntoDest(p, d, e,
      "($1.ClP_0 == $2.ClP_0 && $1.ClE_0 == $2.ClE_0)" % [rdLoc(a), rdLoc(b)])
  else:
    putIntoDest(p, d, e, "($1 == $2)" % [rdLoc(a), rdLoc(b)])

proc genIsNil(p: BProc, e: PNode, d: var TLoc) =
  let t = skipTypes(e.sons[1].typ, abstractRange)
  if t.kind == tyProc and t.callConv == ccClosure:
    unaryExpr(p, e, d, "($1.ClP_0 == 0)")
  else:
    unaryExpr(p, e, d, "($1 == 0)")

proc unaryArith(p: BProc, e: PNode, d: var TLoc, op: TMagic) =
  const
    unArithTab: array[mNot..mToBiggestInt, string] = ["!($1)", # Not
      "$1",                   # UnaryPlusI
      "($3)((NU$2) ~($1))",   # BitnotI
      "$1",                   # UnaryPlusF64
      "-($1)",                # UnaryMinusF64
      "($1 < 0? -($1) : ($1))", # AbsF64; BUGFIX: fabs() makes problems
                                # for Tiny C, so we don't use it
      "(($3)(NU)(NU8)($1))",  # mZe8ToI
      "(($3)(NU64)(NU8)($1))", # mZe8ToI64
      "(($3)(NU)(NU16)($1))", # mZe16ToI
      "(($3)(NU64)(NU16)($1))", # mZe16ToI64
      "(($3)(NU64)(NU32)($1))", # mZe32ToI64
      "(($3)(NU64)(NU)($1))", # mZeIToI64
      "(($3)(NU8)(NU)($1))", # ToU8
      "(($3)(NU16)(NU)($1))", # ToU16
      "(($3)(NU32)(NU64)($1))", # ToU32
      "((double) ($1))",      # ToFloat
      "((double) ($1))",      # ToBiggestFloat
      "float64ToInt32($1)",   # ToInt
      "float64ToInt64($1)"]   # ToBiggestInt
  var
    a: TLoc
    t: PType
  assert(e.sons[1].typ != nil)
  initLocExpr(p, e.sons[1], a)
  t = skipTypes(e.typ, abstractRange)
  putIntoDest(p, d, e,
              unArithTab[op] % [rdLoc(a), rope(getSize(p.config, t) * 8),
                getSimpleTypeDesc(p.module, e.typ)])

proc isCppRef(p: BProc; typ: PType): bool {.inline.} =
  result = p.module.compileToCpp and
      skipTypes(typ, abstractInst).kind == tyVar and
      tfVarIsPtr notin skipTypes(typ, abstractInst).flags

proc genDeref(p: BProc, e: PNode, d: var TLoc; enforceDeref=false) =
  let mt = mapType(p.config, e.sons[0].typ)
  if mt in {ctArray, ctPtrToArray} and not enforceDeref:
    # XXX the amount of hacks for C's arrays is incredible, maybe we should
    # simply wrap them in a struct? --> Losing auto vectorization then?
    #if e[0].kind != nkBracketExpr:
    #  message(e.info, warnUser, "CAME HERE " & renderTree(e))
    expr(p, e.sons[0], d)
    if e.sons[0].typ.skipTypes(abstractInst).kind == tyRef:
      d.storage = OnHeap
  else:
    var a: TLoc
    var typ = e.sons[0].typ
    if typ.kind in {tyUserTypeClass, tyUserTypeClassInst} and typ.isResolvedUserTypeClass:
      typ = typ.lastSon
    typ = typ.skipTypes(abstractInst)
    if typ.kind == tyVar and tfVarIsPtr notin typ.flags and p.module.compileToCpp and e.sons[0].kind == nkHiddenAddr:
      initLocExprSingleUse(p, e[0][0], d)
      return
    else:
      initLocExprSingleUse(p, e.sons[0], a)
    if d.k == locNone:
      # dest = *a;  <-- We do not know that 'dest' is on the heap!
      # It is completely wrong to set 'd.storage' here, unless it's not yet
      # been assigned to.
      case typ.kind
      of tyRef:
        d.storage = OnHeap
      of tyVar, tyLent:
        d.storage = OnUnknown
        if tfVarIsPtr notin typ.flags and p.module.compileToCpp and
            e.kind == nkHiddenDeref:
          putIntoDest(p, d, e, rdLoc(a), a.storage)
          return
      of tyPtr:
        d.storage = OnUnknown         # BUGFIX!
      else:
        internalError(p.config, e.info, "genDeref " & $typ.kind)
    elif p.module.compileToCpp:
      if typ.kind == tyVar and tfVarIsPtr notin typ.flags and
           e.kind == nkHiddenDeref:
        putIntoDest(p, d, e, rdLoc(a), a.storage)
        return
    if enforceDeref and mt == ctPtrToArray:
      # we lie about the type for better C interop: 'ptr array[3,T]' is
      # translated to 'ptr T', but for deref'ing this produces wrong code.
      # See tmissingderef. So we get rid of the deref instead. The codegen
      # ends up using 'memcpy' for the array assignment,
      # so the '&' and '*' cancel out:
      putIntoDest(p, d, lodeTyp(a.t.sons[0]), rdLoc(a), a.storage)
    else:
      putIntoDest(p, d, e, "(*$1)" % [rdLoc(a)], a.storage)

proc genAddr(p: BProc, e: PNode, d: var TLoc) =
  # careful  'addr(myptrToArray)' needs to get the ampersand:
  if e.sons[0].typ.skipTypes(abstractInst).kind in {tyRef, tyPtr}:
    var a: TLoc
    initLocExpr(p, e.sons[0], a)
    putIntoDest(p, d, e, "&" & a.r, a.storage)
    #Message(e.info, warnUser, "HERE NEW &")
  elif mapType(p.config, e.sons[0].typ) == ctArray or isCppRef(p, e.typ):
    expr(p, e.sons[0], d)
  else:
    var a: TLoc
    initLocExpr(p, e.sons[0], a)
    putIntoDest(p, d, e, addrLoc(p.config, a), a.storage)

template inheritLocation(d: var TLoc, a: TLoc) =
  if d.k == locNone: d.storage = a.storage

proc genRecordFieldAux(p: BProc, e: PNode, d, a: var TLoc) =
  initLocExpr(p, e.sons[0], a)
  if e.sons[1].kind != nkSym: internalError(p.config, e.info, "genRecordFieldAux")
  d.inheritLocation(a)
  discard getTypeDesc(p.module, a.t) # fill the record's fields.loc

proc genTupleElem(p: BProc, e: PNode, d: var TLoc) =
  var
    a: TLoc
    i: int
  initLocExpr(p, e.sons[0], a)
  let tupType = a.t.skipTypes(abstractInst)
  assert tupType.kind == tyTuple
  d.inheritLocation(a)
  discard getTypeDesc(p.module, a.t) # fill the record's fields.loc
  var r = rdLoc(a)
  case e.sons[1].kind
  of nkIntLit..nkUInt64Lit: i = int(e.sons[1].intVal)
  else: internalError(p.config, e.info, "genTupleElem")
  addf(r, ".Field$1", [rope(i)])
  putIntoDest(p, d, e, r, a.storage)

proc lookupFieldAgain(p: BProc, ty: PType; field: PSym; r: var Rope;
                      resTyp: ptr PType = nil): PSym =
  var ty = ty
  assert r != nil
  while ty != nil:
    ty = ty.skipTypes(skipPtrs)
    assert(ty.kind in {tyTuple, tyObject})
    result = lookupInRecord(ty.n, field.name)
    if result != nil:
      if resTyp != nil: resTyp[] = ty
      break
    if not p.module.compileToCpp: add(r, ".Sup")
    ty = ty.sons[0]
  if result == nil: internalError(p.config, field.info, "genCheckedRecordField")

proc genRecordField(p: BProc, e: PNode, d: var TLoc) =
  var a: TLoc
  genRecordFieldAux(p, e, d, a)
  var r = rdLoc(a)
  var f = e.sons[1].sym
  let ty = skipTypes(a.t, abstractInst + tyUserTypeClasses)
  if ty.kind == tyTuple:
    # we found a unique tuple type which lacks field information
    # so we use Field$i
    addf(r, ".Field$1", [rope(f.position)])
    putIntoDest(p, d, e, r, a.storage)
  else:
    var rtyp: PType
    let field = lookupFieldAgain(p, ty, f, r, addr rtyp)
    if field.loc.r == nil and rtyp != nil: fillObjectFields(p.module, rtyp)
    if field.loc.r == nil: internalError(p.config, e.info, "genRecordField 3 " & typeToString(ty))
    addf(r, ".$1", [field.loc.r])
    putIntoDest(p, d, e, r, a.storage)

proc genInExprAux(p: BProc, e: PNode, a, b, d: var TLoc)

proc genFieldCheck(p: BProc, e: PNode, obj: Rope, field: PSym) =
  var test, u, v: TLoc
  for i in countup(1, sonsLen(e) - 1):
    var it = e.sons[i]
    assert(it.kind in nkCallKinds)
    assert(it.sons[0].kind == nkSym)
    let op = it.sons[0].sym
    if op.magic == mNot: it = it.sons[1]
    let disc = it.sons[2].skipConv
    assert(disc.kind == nkSym)
    initLoc(test, locNone, it, OnStack)
    initLocExpr(p, it.sons[1], u)
    initLoc(v, locExpr, disc, OnUnknown)
    v.r = obj
    v.r.add(".")
    v.r.add(disc.sym.loc.r)
    genInExprAux(p, it, u, v, test)
    let id = nodeTableTestOrSet(p.module.dataCache,
                               newStrNode(nkStrLit, field.name.s), p.module.labels)
    let strLit = if id == p.module.labels: genStringLiteralDataOnly(p.module, field.name.s, e.info)
                 else: p.module.tmpBase & rope(id)
    if op.magic == mNot:
      linefmt(p, cpsStmts,
              "if ($1) #raiseFieldError($2);$n",
              rdLoc(test), genStringLiteralFromData(p.module, strLit, e.info))
    else:
      linefmt(p, cpsStmts,
              "if (!($1)) #raiseFieldError($2);$n",
              rdLoc(test), genStringLiteralFromData(p.module, strLit, e.info))

proc genCheckedRecordField(p: BProc, e: PNode, d: var TLoc) =
  if optFieldCheck in p.options:
    var a: TLoc
    genRecordFieldAux(p, e.sons[0], d, a)
    let ty = skipTypes(a.t, abstractInst + tyUserTypeClasses)
    var r = rdLoc(a)
    let f = e.sons[0].sons[1].sym
    let field = lookupFieldAgain(p, ty, f, r)
    if field.loc.r == nil: fillObjectFields(p.module, ty)
    if field.loc.r == nil:
      internalError(p.config, e.info, "genCheckedRecordField") # generate the checks:
    genFieldCheck(p, e, r, field)
    add(r, ropecg(p.module, ".$1", field.loc.r))
    putIntoDest(p, d, e.sons[0], r, a.storage)
  else:
    genRecordField(p, e.sons[0], d)

proc genUncheckedArrayElem(p: BProc, n, x, y: PNode, d: var TLoc) =
  var a, b: TLoc
  initLocExpr(p, x, a)
  initLocExpr(p, y, b)
  var ty = skipTypes(a.t, abstractVarRange + abstractPtrs + tyUserTypeClasses)
  d.inheritLocation(a)
  putIntoDest(p, d, n, ropecg(p.module, "$1[$2]", rdLoc(a), rdCharLoc(b)),
              a.storage)

proc genArrayElem(p: BProc, n, x, y: PNode, d: var TLoc) =
  var a, b: TLoc
  initLocExpr(p, x, a)
  initLocExpr(p, y, b)
  var ty = skipTypes(a.t, abstractVarRange + abstractPtrs + tyUserTypeClasses)
  var first = intLiteral(firstOrd(p.config, ty))
  # emit range check:
  if optBoundsCheck in p.options and ty.kind != tyUncheckedArray:
    if not isConstExpr(y):
      # semantic pass has already checked for const index expressions
      if firstOrd(p.config, ty) == 0:
        if (firstOrd(p.config, b.t) < firstOrd(p.config, ty)) or (lastOrd(p.config, b.t) > lastOrd(p.config, ty)):
          linefmt(p, cpsStmts, "if ((NU)($1) > (NU)($2)) #raiseIndexError();$n",
                  rdCharLoc(b), intLiteral(lastOrd(p.config, ty)))
      else:
        linefmt(p, cpsStmts, "if ($1 < $2 || $1 > $3) #raiseIndexError();$n",
                rdCharLoc(b), first, intLiteral(lastOrd(p.config, ty)))
    else:
      let idx = getOrdValue(y)
      if idx < firstOrd(p.config, ty) or idx > lastOrd(p.config, ty):
        localError(p.config, x.info, "index out of bounds")
  d.inheritLocation(a)
  putIntoDest(p, d, n,
              ropecg(p.module, "$1[($2)- $3]", rdLoc(a), rdCharLoc(b), first), a.storage)

proc genCStringElem(p: BProc, n, x, y: PNode, d: var TLoc) =
  var a, b: TLoc
  initLocExpr(p, x, a)
  initLocExpr(p, y, b)
  var ty = skipTypes(a.t, abstractVarRange)
  inheritLocation(d, a)
  putIntoDest(p, d, n,
              ropecg(p.module, "$1[$2]", rdLoc(a), rdCharLoc(b)), a.storage)

proc genBoundsCheck(p: BProc; arr, a, b: TLoc) =
  let ty = skipTypes(arr.t, abstractVarRange)
  case ty.kind
  of tyOpenArray, tyVarargs:
    linefmt(p, cpsStmts,
      "if ($2-$1 != -1 && " &
      "((NU)($1) >= (NU)($3Len_0) || (NU)($2) >= (NU)($3Len_0))) #raiseIndexError();$n",
      rdLoc(a), rdLoc(b), rdLoc(arr))
  of tyArray:
    let first = intLiteral(firstOrd(p.config, ty))
    linefmt(p, cpsStmts,
      "if ($2-$1 != -1 && " &
      "($2-$1 < -1 || $1 < $3 || $1 > $4 || $2 < $3 || $2 > $4)) #raiseIndexError();$n",
      rdCharLoc(a), rdCharLoc(b), first, intLiteral(lastOrd(p.config, ty)))
  of tySequence, tyString:
    linefmt(p, cpsStmts,
      "if ($2-$1 != -1 && " &
      "((NU)($1) >= (NU)$3 || (NU)($2) >= (NU)$3)) #raiseIndexError();$n",
      rdLoc(a), rdLoc(b), lenExpr(p, arr))
  else: discard

proc genOpenArrayElem(p: BProc, n, x, y: PNode, d: var TLoc) =
  var a, b: TLoc
  initLocExpr(p, x, a)
  initLocExpr(p, y, b) # emit range check:
  if optBoundsCheck in p.options:
    linefmt(p, cpsStmts, "if ((NU)($1) >= (NU)($2Len_0)) #raiseIndexError();$n",
            rdLoc(b), rdLoc(a)) # BUGFIX: ``>=`` and not ``>``!
  inheritLocation(d, a)
  putIntoDest(p, d, n,
              ropecg(p.module, "$1[$2]", rdLoc(a), rdCharLoc(b)), a.storage)

proc genSeqElem(p: BProc, n, x, y: PNode, d: var TLoc) =
  var a, b: TLoc
  initLocExpr(p, x, a)
  initLocExpr(p, y, b)
  var ty = skipTypes(a.t, abstractVarRange)
  if ty.kind in {tyRef, tyPtr}:
    ty = skipTypes(ty.lastSon, abstractVarRange) # emit range check:
  if optBoundsCheck in p.options:
    if ty.kind == tyString and (not defined(nimNoZeroTerminator) or optLaxStrings in p.options):
      linefmt(p, cpsStmts,
              "if ((NU)($1) > (NU)$2) #raiseIndexError();$n",
              rdLoc(b), lenExpr(p, a))
    else:
      linefmt(p, cpsStmts,
              "if ((NU)($1) >= (NU)$2) #raiseIndexError();$n",
              rdLoc(b), lenExpr(p, a))
  if d.k == locNone: d.storage = OnHeap
  if skipTypes(a.t, abstractVar).kind in {tyRef, tyPtr}:
    a.r = ropecg(p.module, "(*$1)", a.r)
  putIntoDest(p, d, n,
              ropecg(p.module, "$1$3[$2]", rdLoc(a), rdCharLoc(b), dataField(p)), a.storage)

proc genBracketExpr(p: BProc; n: PNode; d: var TLoc) =
  var ty = skipTypes(n.sons[0].typ, abstractVarRange + tyUserTypeClasses)
  if ty.kind in {tyRef, tyPtr}: ty = skipTypes(ty.lastSon, abstractVarRange)
  case ty.kind
  of tyUncheckedArray: genUncheckedArrayElem(p, n, n.sons[0], n.sons[1], d)
  of tyArray: genArrayElem(p, n, n.sons[0], n.sons[1], d)
  of tyOpenArray, tyVarargs: genOpenArrayElem(p, n, n.sons[0], n.sons[1], d)
  of tySequence, tyString: genSeqElem(p, n, n.sons[0], n.sons[1], d)
  of tyCString: genCStringElem(p, n, n.sons[0], n.sons[1], d)
  of tyTuple: genTupleElem(p, n, d)
  else: internalError(p.config, n.info, "expr(nkBracketExpr, " & $ty.kind & ')')

proc genAndOr(p: BProc, e: PNode, d: var TLoc, m: TMagic) =
  # how to generate code?
  #  'expr1 and expr2' becomes:
  #     result = expr1
  #     fjmp result, end
  #     result = expr2
  #  end:
  #  ... (result computed)
  # BUGFIX:
  #   a = b or a
  # used to generate:
  # a = b
  # if a: goto end
  # a = a
  # end:
  # now it generates:
  # tmp = b
  # if tmp: goto end
  # tmp = a
  # end:
  # a = tmp
  var
    L: TLabel
    tmp: TLoc
  getTemp(p, e.typ, tmp)      # force it into a temp!
  inc p.splitDecls
  expr(p, e.sons[1], tmp)
  L = getLabel(p)
  if m == mOr:
    lineF(p, cpsStmts, "if ($1) goto $2;$n", [rdLoc(tmp), L])
  else:
    lineF(p, cpsStmts, "if (!($1)) goto $2;$n", [rdLoc(tmp), L])
  expr(p, e.sons[2], tmp)
  fixLabel(p, L)
  if d.k == locNone:
    d = tmp
  else:
    genAssignment(p, d, tmp, {}) # no need for deep copying
  dec p.splitDecls

proc genEcho(p: BProc, n: PNode) =
  # this unusal way of implementing it ensures that e.g. ``echo("hallo", 45)``
  # is threadsafe.
  internalAssert p.config, n.kind == nkBracket
  if p.config.target.targetOS == osGenode:
    # echo directly to the Genode LOG session
    var args: Rope = nil
    var a: TLoc
    for it in n.sons:
      if it.skipConv.kind == nkNilLit:
        add(args, ", \"\"")
      else:
        initLocExpr(p, it, a)
        add(args, ropecg(p.module, ", Genode::Cstring($1->data, $1->len)", [rdLoc(a)]))
    p.module.includeHeader("<base/log.h>")
    p.module.includeHeader("<util/string.h>")
    linefmt(p, cpsStmts, """Genode::log(""$1);$n""", args)
  else:
    if n.len == 0:
      linefmt(p, cpsStmts, "#echoBinSafe(NIM_NIL, $1);$n", n.len.rope)
    else:
      var a: TLoc
      initLocExpr(p, n, a)
      linefmt(p, cpsStmts, "#echoBinSafe($1, $2);$n", a.rdLoc, n.len.rope)
    when false:
      p.module.includeHeader("<stdio.h>")
      linefmt(p, cpsStmts, "printf($1$2);$n",
              makeCString(repeat("%s", n.len) & "\L"), args)
      linefmt(p, cpsStmts, "fflush(stdout);$n")

proc gcUsage(conf: ConfigRef; n: PNode) =
  if conf.selectedGC == gcNone: message(conf, n.info, warnGcMem, n.renderTree)

proc strLoc(p: BProc; d: TLoc): Rope =
  if p.config.selectedGc == gcDestructors:
    result = addrLoc(p.config, d)
  else:
    result = rdLoc(d)

proc genStrConcat(p: BProc, e: PNode, d: var TLoc) =
  #   <Nim code>
  #   s = 'Hello ' & name & ', how do you feel?' & 'z'
  #
  #   <generated C code>
  #  {
  #    string tmp0;
  #    ...
  #    tmp0 = rawNewString(6 + 17 + 1 + s2->len);
  #    // we cannot generate s = rawNewString(...) here, because
  #    // ``s`` may be used on the right side of the expression
  #    appendString(tmp0, strlit_1);
  #    appendString(tmp0, name);
  #    appendString(tmp0, strlit_2);
  #    appendChar(tmp0, 'z');
  #    asgn(s, tmp0);
  #  }
  var a, tmp: TLoc
  getTemp(p, e.typ, tmp)
  var L = 0
  var appends: Rope = nil
  var lens: Rope = nil
  for i in countup(0, sonsLen(e) - 2):
    # compute the length expression:
    initLocExpr(p, e.sons[i + 1], a)
    if skipTypes(e.sons[i + 1].typ, abstractVarRange).kind == tyChar:
      inc(L)
      add(appends, ropecg(p.module, "#appendChar($1, $2);$n", strLoc(p, tmp), rdLoc(a)))
    else:
      if e.sons[i + 1].kind in {nkStrLit..nkTripleStrLit}:
        inc(L, len(e.sons[i + 1].strVal))
      else:
        add(lens, lenExpr(p, a))
        add(lens, " + ")
      add(appends, ropecg(p.module, "#appendString($1, $2);$n", strLoc(p, tmp), rdLoc(a)))
  linefmt(p, cpsStmts, "$1 = #rawNewString($2$3);$n", tmp.r, lens, rope(L))
  add(p.s(cpsStmts), appends)
  if d.k == locNone:
    d = tmp
  else:
    genAssignment(p, d, tmp, {}) # no need for deep copying
  gcUsage(p.config, e)

proc genStrAppend(p: BProc, e: PNode, d: var TLoc) =
  #  <Nim code>
  #  s &= 'Hello ' & name & ', how do you feel?' & 'z'
  #  // BUG: what if s is on the left side too?
  #  <generated C code>
  #  {
  #    s = resizeString(s, 6 + 17 + 1 + name->len);
  #    appendString(s, strlit_1);
  #    appendString(s, name);
  #    appendString(s, strlit_2);
  #    appendChar(s, 'z');
  #  }
  var
    a, dest, call: TLoc
    appends, lens: Rope
  assert(d.k == locNone)
  var L = 0
  initLocExpr(p, e.sons[1], dest)
  for i in countup(0, sonsLen(e) - 3):
    # compute the length expression:
    initLocExpr(p, e.sons[i + 2], a)
    if skipTypes(e.sons[i + 2].typ, abstractVarRange).kind == tyChar:
      inc(L)
      add(appends, ropecg(p.module, "#appendChar($1, $2);$n",
                        strLoc(p, dest), rdLoc(a)))
    else:
      if e.sons[i + 2].kind in {nkStrLit..nkTripleStrLit}:
        inc(L, len(e.sons[i + 2].strVal))
      else:
        add(lens, lenExpr(p, a))
        add(lens, " + ")
      add(appends, ropecg(p.module, "#appendString($1, $2);$n",
                        strLoc(p, dest), rdLoc(a)))
  if p.config.selectedGC == gcDestructors:
    linefmt(p, cpsStmts, "#prepareAdd($1, $2$3);$n",
            addrLoc(p.config, dest), lens, rope(L))
  else:
    initLoc(call, locCall, e, OnHeap)
    call.r = ropecg(p.module, "#resizeString($1, $2$3)", [rdLoc(dest), lens, rope(L)])
    genAssignment(p, dest, call, {})
    gcUsage(p.config, e)
  add(p.s(cpsStmts), appends)

proc genSeqElemAppend(p: BProc, e: PNode, d: var TLoc) =
  # seq &= x  -->
  #    seq = (typeof seq) incrSeq(&seq->Sup, sizeof(x));
  #    seq->data[seq->len-1] = x;
  let seqAppendPattern = if not p.module.compileToCpp:
                           "($2) #incrSeqV3(&($1)->Sup, $3)"
                         else:
                           "($2) #incrSeqV3($1, $3)"
  var a, b, dest, tmpL, call: TLoc
  initLocExpr(p, e.sons[1], a)
  initLocExpr(p, e.sons[2], b)
  let seqType = skipTypes(e.sons[1].typ, {tyVar})
  initLoc(call, locCall, e, OnHeap)
  call.r = ropecg(p.module, seqAppendPattern, [rdLoc(a),
    getTypeDesc(p.module, e.sons[1].typ),
    genTypeInfo(p.module, seqType, e.info)])
  # emit the write barrier if required, but we can always move here, so
  # use 'genRefAssign' for the seq.
  genRefAssign(p, a, call, {})
  #if bt != b.t:
  #  echo "YES ", e.info, " new: ", typeToString(bt), " old: ", typeToString(b.t)
  initLoc(dest, locExpr, e.sons[2], OnHeap)
  getIntTemp(p, tmpL)
  lineCg(p, cpsStmts, "$1 = $2->$3++;$n", tmpL.r, rdLoc(a), lenField(p))
  dest.r = ropecg(p.module, "$1$3[$2]", rdLoc(a), tmpL.r, dataField(p))
  genAssignment(p, dest, b, {needToCopy, afDestIsNil})
  gcUsage(p.config, e)

proc genReset(p: BProc, n: PNode) =
  var a: TLoc
  initLocExpr(p, n.sons[1], a)
  linefmt(p, cpsStmts, "#genericReset((void*)$1, $2);$n",
          addrLoc(p.config, a),
          genTypeInfo(p.module, skipTypes(a.t, {tyVar}), n.info))

proc rawGenNew(p: BProc, a: TLoc, sizeExpr: Rope) =
  var sizeExpr = sizeExpr
  let typ = a.t
  var b: TLoc
  initLoc(b, locExpr, a.lode, OnHeap)
  let refType = typ.skipTypes(abstractInst)
  assert refType.kind == tyRef
  let bt = refType.lastSon
  if sizeExpr.isNil:
    sizeExpr = "sizeof($1)" %
        [getTypeDesc(p.module, bt)]

  let ti = genTypeInfo(p.module, typ, a.lode.info)
  if bt.destructor != nil:
    # the prototype of a destructor is ``=destroy(x: var T)`` and that of a
    # finalizer is: ``proc (x: ref T) {.nimcall.}``. We need to check the calling
    # convention at least:
    if bt.destructor.typ == nil or bt.destructor.typ.callConv != ccDefault:
      localError(p.module.config, a.lode.info,
        "the destructor that is turned into a finalizer needs " &
        "to have the 'nimcall' calling convention")
    var f: TLoc
    initLocExpr(p, newSymNode(bt.destructor), f)
    addf(p.module.s[cfsTypeInit3], "$1->finalizer = (void*)$2;$n", [ti, rdLoc(f)])

  let args = [getTypeDesc(p.module, typ), ti, sizeExpr]
  if a.storage == OnHeap and usesWriteBarrier(p.config):
    if canFormAcycle(a.t):
      linefmt(p, cpsStmts, "if ($1) { #nimGCunrefRC1($1); $1 = NIM_NIL; }$n", a.rdLoc)
    else:
      linefmt(p, cpsStmts, "if ($1) { #nimGCunrefNoCycle($1); $1 = NIM_NIL; }$n", a.rdLoc)
    if p.config.selectedGC == gcGo:
      # newObjRC1() would clash with unsureAsgnRef() - which is used by gcGo to
      # implement the write barrier
      b.r = ropecg(p.module, "($1) #newObj($2, $3)", args)
      linefmt(p, cpsStmts, "#unsureAsgnRef((void**) $1, $2);$n", addrLoc(p.config, a), b.rdLoc)
    else:
      # use newObjRC1 as an optimization
      b.r = ropecg(p.module, "($1) #newObjRC1($2, $3)", args)
      linefmt(p, cpsStmts, "$1 = $2;$n", a.rdLoc, b.rdLoc)
  else:
    b.r = ropecg(p.module, "($1) #newObj($2, $3)", args)
    genAssignment(p, a, b, {})  # set the object type:
  genObjectInit(p, cpsStmts, bt, a, false)

proc genNew(p: BProc, e: PNode) =
  var a: TLoc
  initLocExpr(p, e.sons[1], a)
  # 'genNew' also handles 'unsafeNew':
  if e.len == 3:
    var se: TLoc
    initLocExpr(p, e.sons[2], se)
    rawGenNew(p, a, se.rdLoc)
  else:
    rawGenNew(p, a, nil)
  gcUsage(p.config, e)

proc genNewSeqAux(p: BProc, dest: TLoc, length: Rope; lenIsZero: bool) =
  let seqtype = skipTypes(dest.t, abstractVarRange)
  let args = [getTypeDesc(p.module, seqtype),
              genTypeInfo(p.module, seqtype, dest.lode.info), length]
  var call: TLoc
  initLoc(call, locExpr, dest.lode, OnHeap)
  if dest.storage == OnHeap and usesWriteBarrier(p.config):
    if canFormAcycle(dest.t):
      linefmt(p, cpsStmts, "if ($1) { #nimGCunrefRC1($1); $1 = NIM_NIL; }$n", dest.rdLoc)
    else:
      linefmt(p, cpsStmts, "if ($1) { #nimGCunrefNoCycle($1); $1 = NIM_NIL; }$n", dest.rdLoc)
    if not lenIsZero:
      if p.config.selectedGC == gcGo:
        # we need the write barrier
        call.r = ropecg(p.module, "($1) #newSeq($2, $3)", args)
        linefmt(p, cpsStmts, "#unsureAsgnRef((void**) $1, $2);$n", addrLoc(p.config, dest), call.rdLoc)
      else:
        call.r = ropecg(p.module, "($1) #newSeqRC1($2, $3)", args)
        linefmt(p, cpsStmts, "$1 = $2;$n", dest.rdLoc, call.rdLoc)
  else:
    if lenIsZero:
      call.r = rope"NIM_NIL"
    else:
      call.r = ropecg(p.module, "($1) #newSeq($2, $3)", args)
    genAssignment(p, dest, call, {})

proc genNewSeq(p: BProc, e: PNode) =
  var a, b: TLoc
  initLocExpr(p, e.sons[1], a)
  initLocExpr(p, e.sons[2], b)
  if p.config.selectedGC == gcDestructors:
    let seqtype = skipTypes(e.sons[1].typ, abstractVarRange)
    linefmt(p, cpsStmts, "$1.len = $2; $1.p = ($4*) #newSeqPayload($2, sizeof($3));$n",
      a.rdLoc, b.rdLoc, getTypeDesc(p.module, seqtype.lastSon),
      getSeqPayloadType(p.module, seqtype))
  else:
    let lenIsZero = optNilSeqs notin p.options and
      e[2].kind == nkIntLit and e[2].intVal == 0
    genNewSeqAux(p, a, b.rdLoc, lenIsZero)
    gcUsage(p.config, e)

proc genNewSeqOfCap(p: BProc; e: PNode; d: var TLoc) =
  let seqtype = skipTypes(e.typ, abstractVarRange)
  var a: TLoc
  initLocExpr(p, e.sons[1], a)
  putIntoDest(p, d, e, ropecg(p.module,
              "($1)#nimNewSeqOfCap($2, $3)", [
              getTypeDesc(p.module, seqtype),
              genTypeInfo(p.module, seqtype, e.info), a.rdLoc]))
  gcUsage(p.config, e)

proc genConstExpr(p: BProc, n: PNode): Rope
proc handleConstExpr(p: BProc, n: PNode, d: var TLoc): bool =
  if d.k == locNone and n.len > ord(n.kind == nkObjConstr) and n.isDeepConstExpr:
    let t = n.typ
    discard getTypeDesc(p.module, t) # so that any fields are initialized
    let id = nodeTableTestOrSet(p.module.dataCache, n, p.module.labels)
    fillLoc(d, locData, n, p.module.tmpBase & rope(id), OnStatic)
    if id == p.module.labels:
      # expression not found in the cache:
      inc(p.module.labels)
      addf(p.module.s[cfsData], "NIM_CONST $1 $2 = $3;$n",
           [getTypeDesc(p.module, t), d.r, genConstExpr(p, n)])
    result = true
  else:
    result = false

proc genObjConstr(p: BProc, e: PNode, d: var TLoc) =
  #echo rendertree e, " ", e.isDeepConstExpr
  # inheritance in C++ does not allow struct initialization so
  # we skip this step here:
  if not p.module.compileToCpp:
    if handleConstExpr(p, e, d): return
  var t = e.typ.skipTypes(abstractInst)
  let isRef = t.kind == tyRef

  # check if we need to construct the object in a temporary
  var useTemp =
        isRef or
        (d.k notin {locTemp,locLocalVar,locGlobalVar,locParam,locField}) or
        (isPartOf(d.lode, e) != arNo)

  var tmp: TLoc
  var r: Rope
  if useTemp:
    getTemp(p, t, tmp)
    r = rdLoc(tmp)
    if isRef:
      rawGenNew(p, tmp, nil)
      t = t.lastSon.skipTypes(abstractInst)
      r = "(*$1)" % [r]
      gcUsage(p.config, e)
    else:
      constructLoc(p, tmp)
  else:
    resetLoc(p, d)
    r = rdLoc(d)
  discard getTypeDesc(p.module, t)
  let ty = getUniqueType(t)
  for i in 1 ..< e.len:
    let it = e.sons[i]
    var tmp2: TLoc
    tmp2.r = r
    let field = lookupFieldAgain(p, ty, it.sons[0].sym, tmp2.r)
    if field.loc.r == nil: fillObjectFields(p.module, ty)
    if field.loc.r == nil: internalError(p.config, e.info, "genObjConstr")
    if it.len == 3 and optFieldCheck in p.options:
      genFieldCheck(p, it.sons[2], r, field)
    add(tmp2.r, ".")
    add(tmp2.r, field.loc.r)
    if useTemp:
      tmp2.k = locTemp
      tmp2.storage = if isRef: OnHeap else: OnStack
    else:
      tmp2.k = d.k
      tmp2.storage = if isRef: OnHeap else: d.storage
    tmp2.lode = it.sons[1]
    expr(p, it.sons[1], tmp2)
  if useTemp:
    if d.k == locNone:
      d = tmp
    else:
      genAssignment(p, d, tmp, {})

proc lhsDoesAlias(a, b: PNode): bool =
  for y in b:
    if isPartOf(a, y) != arNo: return true

proc genSeqConstr(p: BProc, n: PNode, d: var TLoc) =
  var arr, tmp: TLoc
  # bug #668
  let doesAlias = lhsDoesAlias(d.lode, n)
  let dest = if doesAlias: addr(tmp) else: addr(d)
  if doesAlias:
    getTemp(p, n.typ, tmp)
  elif d.k == locNone:
    getTemp(p, n.typ, d)
  # generate call to newSeq before adding the elements per hand:
  genNewSeqAux(p, dest[], intLiteral(sonsLen(n)),
    optNilSeqs notin p.options and n.len == 0)
  for i in countup(0, sonsLen(n) - 1):
    initLoc(arr, locExpr, n[i], OnHeap)
    arr.r = ropecg(p.module, "$1$3[$2]", rdLoc(dest[]), intLiteral(i), dataField(p))
    arr.storage = OnHeap            # we know that sequences are on the heap
    expr(p, n[i], arr)
  gcUsage(p.config, n)
  if doesAlias:
    if d.k == locNone:
      d = tmp
    else:
      genAssignment(p, d, tmp, {})

proc genArrToSeq(p: BProc, n: PNode, d: var TLoc) =
  var elem, a, arr: TLoc
  if n.sons[1].kind == nkBracket:
    n.sons[1].typ = n.typ
    genSeqConstr(p, n.sons[1], d)
    return
  if d.k == locNone:
    getTemp(p, n.typ, d)
  # generate call to newSeq before adding the elements per hand:
  let L = int(lengthOrd(p.config, n.sons[1].typ))
  genNewSeqAux(p, d, intLiteral(L), optNilSeqs notin p.options and L == 0)
  initLocExpr(p, n.sons[1], a)
  # bug #5007; do not produce excessive C source code:
  if L < 10:
    for i in countup(0, L - 1):
      initLoc(elem, locExpr, lodeTyp elemType(skipTypes(n.typ, abstractInst)), OnHeap)
      elem.r = ropecg(p.module, "$1$3[$2]", rdLoc(d), intLiteral(i), dataField(p))
      elem.storage = OnHeap # we know that sequences are on the heap
      initLoc(arr, locExpr, lodeTyp elemType(skipTypes(n.sons[1].typ, abstractInst)), a.storage)
      arr.r = ropecg(p.module, "$1[$2]", rdLoc(a), intLiteral(i))
      genAssignment(p, elem, arr, {afDestIsNil, needToCopy})
  else:
    var i: TLoc
    getTemp(p, getSysType(p.module.g.graph, unknownLineInfo(), tyInt), i)
    let oldCode = p.s(cpsStmts)
    linefmt(p, cpsStmts, "for ($1 = 0; $1 < $2; $1++) {$n",  i.r, L.rope)
    initLoc(elem, locExpr, lodeTyp elemType(skipTypes(n.typ, abstractInst)), OnHeap)
    elem.r = ropecg(p.module, "$1$3[$2]", rdLoc(d), rdLoc(i), dataField(p))
    elem.storage = OnHeap # we know that sequences are on the heap
    initLoc(arr, locExpr, lodeTyp elemType(skipTypes(n.sons[1].typ, abstractInst)), a.storage)
    arr.r = ropecg(p.module, "$1[$2]", rdLoc(a), rdLoc(i))
    genAssignment(p, elem, arr, {afDestIsNil, needToCopy})
    lineF(p, cpsStmts, "}$n", [])


proc genNewFinalize(p: BProc, e: PNode) =
  var
    a, b, f: TLoc
    refType, bt: PType
    ti: Rope
  refType = skipTypes(e.sons[1].typ, abstractVarRange)
  initLocExpr(p, e.sons[1], a)
  initLocExpr(p, e.sons[2], f)
  initLoc(b, locExpr, a.lode, OnHeap)
  ti = genTypeInfo(p.module, refType, e.info)
  addf(p.module.s[cfsTypeInit3], "$1->finalizer = (void*)$2;$n", [ti, rdLoc(f)])
  b.r = ropecg(p.module, "($1) #newObj($2, sizeof($3))", [
      getTypeDesc(p.module, refType),
      ti, getTypeDesc(p.module, skipTypes(refType.lastSon, abstractRange))])
  genAssignment(p, a, b, {})  # set the object type:
  bt = skipTypes(refType.lastSon, abstractRange)
  genObjectInit(p, cpsStmts, bt, a, false)
  gcUsage(p.config, e)

proc genOfHelper(p: BProc; dest: PType; a: Rope; info: TLineInfo): Rope =
  # unfortunately 'genTypeInfo' sets tfObjHasKids as a side effect, so we
  # have to call it here first:
  let ti = genTypeInfo(p.module, dest, info)
  if tfFinal in dest.flags or (objHasKidsValid in p.module.flags and
                               tfObjHasKids notin dest.flags):
    result = "$1.m_type == $2" % [a, ti]
  else:
    discard cgsym(p.module, "TNimType")
    inc p.module.labels
    let cache = "Nim_OfCheck_CACHE" & p.module.labels.rope
    addf(p.module.s[cfsVars], "static TNimType* $#[2];$n", [cache])
    result = ropecg(p.module, "#isObjWithCache($#.m_type, $#, $#)", a, ti, cache)
  when false:
    # former version:
    result = ropecg(p.module, "#isObj($1.m_type, $2)",
                  a, genTypeInfo(p.module, dest, info))

proc genOf(p: BProc, x: PNode, typ: PType, d: var TLoc) =
  var a: TLoc
  initLocExpr(p, x, a)
  var dest = skipTypes(typ, typedescPtrs)
  var r = rdLoc(a)
  var nilCheck: Rope = nil
  var t = skipTypes(a.t, abstractInst)
  while t.kind in {tyVar, tyLent, tyPtr, tyRef}:
    if t.kind notin {tyVar, tyLent}: nilCheck = r
    if t.kind notin {tyVar, tyLent} or not p.module.compileToCpp:
      r = ropecg(p.module, "(*$1)", r)
    t = skipTypes(t.lastSon, typedescInst)
  discard getTypeDesc(p.module, t)
  if not p.module.compileToCpp:
    while t.kind == tyObject and t.sons[0] != nil:
      add(r, ~".Sup")
      t = skipTypes(t.sons[0], skipPtrs)
  if isObjLackingTypeField(t):
    globalError(p.config, x.info,
      "no 'of' operator available for pure objects")
  if nilCheck != nil:
    r = ropecg(p.module, "(($1) && ($2))", nilCheck, genOfHelper(p, dest, r, x.info))
  else:
    r = ropecg(p.module, "($1)", genOfHelper(p, dest, r, x.info))
  putIntoDest(p, d, x, r, a.storage)

proc genOf(p: BProc, n: PNode, d: var TLoc) =
  genOf(p, n.sons[1], n.sons[2].typ, d)

proc genRepr(p: BProc, e: PNode, d: var TLoc) =
  var a: TLoc
  initLocExpr(p, e.sons[1], a)
  var t = skipTypes(e.sons[1].typ, abstractVarRange)
  case t.kind
  of tyInt..tyInt64, tyUInt..tyUInt64:
    putIntoDest(p, d, e,
                ropecg(p.module, "#reprInt((NI64)$1)", [rdLoc(a)]), a.storage)
  of tyFloat..tyFloat128:
    putIntoDest(p, d, e, ropecg(p.module, "#reprFloat($1)", [rdLoc(a)]), a.storage)
  of tyBool:
    putIntoDest(p, d, e, ropecg(p.module, "#reprBool($1)", [rdLoc(a)]), a.storage)
  of tyChar:
    putIntoDest(p, d, e, ropecg(p.module, "#reprChar($1)", [rdLoc(a)]), a.storage)
  of tyEnum, tyOrdinal:
    putIntoDest(p, d, e,
                ropecg(p.module, "#reprEnum((NI)$1, $2)", [
                rdLoc(a), genTypeInfo(p.module, t, e.info)]), a.storage)
  of tyString:
    putIntoDest(p, d, e, ropecg(p.module, "#reprStr($1)", [rdLoc(a)]), a.storage)
  of tySet:
    putIntoDest(p, d, e, ropecg(p.module, "#reprSet($1, $2)", [
                addrLoc(p.config, a), genTypeInfo(p.module, t, e.info)]), a.storage)
  of tyOpenArray, tyVarargs:
    var b: TLoc
    case a.t.kind
    of tyOpenArray, tyVarargs:
      putIntoDest(p, b, e, "$1, $1Len_0" % [rdLoc(a)], a.storage)
    of tyString, tySequence:
      putIntoDest(p, b, e,
                  "$1$3, $2" % [rdLoc(a), lenExpr(p, a), dataField(p)], a.storage)
    of tyArray:
      putIntoDest(p, b, e,
                  "$1, $2" % [rdLoc(a), rope(lengthOrd(p.config, a.t))], a.storage)
    else: internalError(p.config, e.sons[0].info, "genRepr()")
    putIntoDest(p, d, e,
        ropecg(p.module, "#reprOpenArray($1, $2)", [rdLoc(b),
        genTypeInfo(p.module, elemType(t), e.info)]), a.storage)
  of tyCString, tyArray, tyRef, tyPtr, tyPointer, tyNil, tySequence:
    putIntoDest(p, d, e,
                ropecg(p.module, "#reprAny($1, $2)", [
                rdLoc(a), genTypeInfo(p.module, t, e.info)]), a.storage)
  of tyEmpty, tyVoid:
    localError(p.config, e.info, "'repr' doesn't support 'void' type")
  else:
    putIntoDest(p, d, e, ropecg(p.module, "#reprAny($1, $2)",
                              [addrLoc(p.config, a), genTypeInfo(p.module, t, e.info)]),
                               a.storage)
  gcUsage(p.config, e)

proc genGetTypeInfo(p: BProc, e: PNode, d: var TLoc) =
  let t = e.sons[1].typ
  putIntoDest(p, d, e, genTypeInfo(p.module, t, e.info))

proc genDollar(p: BProc, n: PNode, d: var TLoc, frmt: string) =
  var a: TLoc
  initLocExpr(p, n.sons[1], a)
  a.r = ropecg(p.module, frmt, [rdLoc(a)])
  if d.k == locNone: getTemp(p, n.typ, d)
  genAssignment(p, d, a, {})
  gcUsage(p.config, n)

proc genArrayLen(p: BProc, e: PNode, d: var TLoc, op: TMagic) =
  var a = e.sons[1]
  if a.kind == nkHiddenAddr: a = a.sons[0]
  var typ = skipTypes(a.typ, abstractVar + tyUserTypeClasses)
  case typ.kind
  of tyOpenArray, tyVarargs:
    # Bug #9279, len(toOpenArray()) has to work:
    if a.kind in nkCallKinds and a[0].kind == nkSym and a[0].sym.magic == mSlice:
      # magic: pass slice to openArray:
      var b, c: TLoc
      initLocExpr(p, a[2], b)
      initLocExpr(p, a[3], c)
      if op == mHigh:
        putIntoDest(p, d, e, ropecg(p.module, "($2)-($1)", [rdLoc(b), rdLoc(c)]))
      else:
        putIntoDest(p, d, e, ropecg(p.module, "($2)-($1)+1", [rdLoc(b), rdLoc(c)]))
    else:
      if op == mHigh: unaryExpr(p, e, d, "($1Len_0-1)")
      else: unaryExpr(p, e, d, "$1Len_0")
  of tyCString:
    if op == mHigh: unaryExpr(p, e, d, "($1 ? (#nimCStrLen($1)-1) : -1)")
    else: unaryExpr(p, e, d, "($1 ? #nimCStrLen($1) : 0)")
  of tyString:
    var a: TLoc
    initLocExpr(p, e.sons[1], a)
    var x = lenExpr(p, a)
    if op == mHigh: x = "($1-1)" % [x]
    putIntoDest(p, d, e, x)
  of tySequence:
    # we go through a temporary here because people write bullshit code.
    var a, tmp: TLoc
    initLocExpr(p, e[1], a)
    getIntTemp(p, tmp)
    var x = lenExpr(p, a)
    if op == mHigh: x = "($1-1)" % [x]
    lineCg(p, cpsStmts, "$1 = $2;$n", tmp.r, x)
    putIntoDest(p, d, e, tmp.r)
  of tyArray:
    # YYY: length(sideeffect) is optimized away incorrectly?
    if op == mHigh: putIntoDest(p, d, e, rope(lastOrd(p.config, typ)))
    else: putIntoDest(p, d, e, rope(lengthOrd(p.config, typ)))
  else: internalError(p.config, e.info, "genArrayLen()")

proc genSetLengthSeq(p: BProc, e: PNode, d: var TLoc) =
  if p.config.selectedGc == gcDestructors:
    genCall(p, e, d)
    return
  var a, b, call: TLoc
  assert(d.k == locNone)
  var x = e.sons[1]
  if x.kind in {nkAddr, nkHiddenAddr}: x = x[0]
  initLocExpr(p, x, a)
  initLocExpr(p, e.sons[2], b)
  let t = skipTypes(e.sons[1].typ, {tyVar})
  let setLenPattern = if not p.module.compileToCpp:
      "($3) #setLengthSeqV2(&($1)->Sup, $4, $2)"
    else:
      "($3) #setLengthSeqV2($1, $4, $2)"

  initLoc(call, locCall, e, OnHeap)
  call.r = ropecg(p.module, setLenPattern, [
      rdLoc(a), rdLoc(b), getTypeDesc(p.module, t),
      genTypeInfo(p.module, t.skipTypes(abstractInst), e.info)])
  genAssignment(p, a, call, {})
  gcUsage(p.config, e)

proc genSetLengthStr(p: BProc, e: PNode, d: var TLoc) =
  if p.config.selectedGc == gcDestructors:
    binaryStmtAddr(p, e, d, "#setLengthStrV2($1, $2);$n")
  else:
    var a, b, call: TLoc
    if d.k != locNone: internalError(p.config, e.info, "genSetLengthStr")
    initLocExpr(p, e.sons[1], a)
    initLocExpr(p, e.sons[2], b)

    initLoc(call, locCall, e, OnHeap)
    call.r = ropecg(p.module, "#setLengthStr($1, $2)", [
        rdLoc(a), rdLoc(b)])
    genAssignment(p, a, call, {})
    gcUsage(p.config, e)

proc genSwap(p: BProc, e: PNode, d: var TLoc) =
  # swap(a, b) -->
  # temp = a
  # a = b
  # b = temp
  var a, b, tmp: TLoc
  getTemp(p, skipTypes(e.sons[1].typ, abstractVar), tmp)
  initLocExpr(p, e.sons[1], a) # eval a
  initLocExpr(p, e.sons[2], b) # eval b
  genAssignment(p, tmp, a, {})
  genAssignment(p, a, b, {})
  genAssignment(p, b, tmp, {})

proc rdSetElemLoc(conf: ConfigRef; a: TLoc, typ: PType): Rope =
  # read a location of an set element; it may need a subtraction operation
  # before the set operation
  result = rdCharLoc(a)
  let setType = typ.skipTypes(abstractPtrs)
  assert(setType.kind == tySet)
  if firstOrd(conf, setType) != 0:
    result = "($1- $2)" % [result, rope(firstOrd(conf, setType))]

proc fewCmps(conf: ConfigRef; s: PNode): bool =
  # this function estimates whether it is better to emit code
  # for constructing the set or generating a bunch of comparisons directly
  if s.kind != nkCurly: return false
  if (getSize(conf, s.typ) <= conf.target.intSize) and (nfAllConst in s.flags):
    result = false            # it is better to emit the set generation code
  elif elemType(s.typ).kind in {tyInt, tyInt16..tyInt64}:
    result = true             # better not emit the set if int is basetype!
  else:
    result = sonsLen(s) <= 8  # 8 seems to be a good value

proc binaryExprIn(p: BProc, e: PNode, a, b, d: var TLoc, frmt: string) =
  putIntoDest(p, d, e, frmt % [rdLoc(a), rdSetElemLoc(p.config, b, a.t)])

proc genInExprAux(p: BProc, e: PNode, a, b, d: var TLoc) =
  case int(getSize(p.config, skipTypes(e.sons[1].typ, abstractVar)))
  of 1: binaryExprIn(p, e, a, b, d, "(($1 &(1U<<((NU)($2)&7U)))!=0)")
  of 2: binaryExprIn(p, e, a, b, d, "(($1 &(1U<<((NU)($2)&15U)))!=0)")
  of 4: binaryExprIn(p, e, a, b, d, "(($1 &(1U<<((NU)($2)&31U)))!=0)")
  of 8: binaryExprIn(p, e, a, b, d, "(($1 &((NU64)1<<((NU)($2)&63U)))!=0)")
  else: binaryExprIn(p, e, a, b, d, "(($1[(NU)($2)>>3] &(1U<<((NU)($2)&7U)))!=0)")

proc binaryStmtInExcl(p: BProc, e: PNode, d: var TLoc, frmt: string) =
  var a, b: TLoc
  assert(d.k == locNone)
  initLocExpr(p, e.sons[1], a)
  initLocExpr(p, e.sons[2], b)
  lineF(p, cpsStmts, frmt, [rdLoc(a), rdSetElemLoc(p.config, b, a.t)])

proc genInOp(p: BProc, e: PNode, d: var TLoc) =
  var a, b, x, y: TLoc
  if (e.sons[1].kind == nkCurly) and fewCmps(p.config, e.sons[1]):
    # a set constructor but not a constant set:
    # do not emit the set, but generate a bunch of comparisons; and if we do
    # so, we skip the unnecessary range check: This is a semantical extension
    # that code now relies on. :-/ XXX
    let ea = if e.sons[2].kind in {nkChckRange, nkChckRange64}:
               e.sons[2].sons[0]
             else:
               e.sons[2]
    initLocExpr(p, ea, a)
    initLoc(b, locExpr, e, OnUnknown)
    var length = sonsLen(e.sons[1])
    if length > 0:
      b.r = rope("(")
      for i in countup(0, length - 1):
        let it = e.sons[1].sons[i]
        if it.kind == nkRange:
          initLocExpr(p, it.sons[0], x)
          initLocExpr(p, it.sons[1], y)
          addf(b.r, "$1 >= $2 && $1 <= $3",
               [rdCharLoc(a), rdCharLoc(x), rdCharLoc(y)])
        else:
          initLocExpr(p, it, x)
          addf(b.r, "$1 == $2", [rdCharLoc(a), rdCharLoc(x)])
        if i < length - 1: add(b.r, " || ")
      add(b.r, ")")
    else:
      # handle the case of an empty set
      b.r = rope("0")
    putIntoDest(p, d, e, b.r)
  else:
    assert(e.sons[1].typ != nil)
    assert(e.sons[2].typ != nil)
    initLocExpr(p, e.sons[1], a)
    initLocExpr(p, e.sons[2], b)
    genInExprAux(p, e, a, b, d)

proc genSetOp(p: BProc, e: PNode, d: var TLoc, op: TMagic) =
  const
    lookupOpr: array[mLeSet..mSymDiffSet, string] = [
      "for ($1 = 0; $1 < $2; $1++) { $n" &
        "  $3 = (($4[$1] & ~ $5[$1]) == 0);$n" &
        "  if (!$3) break;}$n", "for ($1 = 0; $1 < $2; $1++) { $n" &
        "  $3 = (($4[$1] & ~ $5[$1]) == 0);$n" & "  if (!$3) break;}$n" &
        "if ($3) $3 = (#nimCmpMem($4, $5, $2) != 0);$n",
      "&", "|", "& ~", "^"]
  var a, b, i: TLoc
  var setType = skipTypes(e.sons[1].typ, abstractVar)
  var size = int(getSize(p.config, setType))
  case size
  of 1, 2, 4, 8:
    case op
    of mIncl:
      var ts = "NU" & $(size * 8)
      binaryStmtInExcl(p, e, d,
          "$1 |= ((" & ts & ")1)<<(($2)%(sizeof(" & ts & ")*8));$n")
    of mExcl:
      var ts = "NU" & $(size * 8)
      binaryStmtInExcl(p, e, d, "$1 &= ~(((" & ts & ")1) << (($2) % (sizeof(" &
          ts & ")*8)));$n")
    of mCard:
      if size <= 4: unaryExprChar(p, e, d, "#countBits32($1)")
      else: unaryExprChar(p, e, d, "#countBits64($1)")
    of mLtSet: binaryExprChar(p, e, d, "(($1 & ~ $2 ==0)&&($1 != $2))")
    of mLeSet: binaryExprChar(p, e, d, "(($1 & ~ $2)==0)")
    of mEqSet: binaryExpr(p, e, d, "($1 == $2)")
    of mMulSet: binaryExpr(p, e, d, "($1 & $2)")
    of mPlusSet: binaryExpr(p, e, d, "($1 | $2)")
    of mMinusSet: binaryExpr(p, e, d, "($1 & ~ $2)")
    of mSymDiffSet: binaryExpr(p, e, d, "($1 ^ $2)")
    of mInSet:
      genInOp(p, e, d)
    else: internalError(p.config, e.info, "genSetOp()")
  else:
    case op
    of mIncl: binaryStmtInExcl(p, e, d, "$1[(NU)($2)>>3] |=(1U<<($2&7U));$n")
    of mExcl: binaryStmtInExcl(p, e, d, "$1[(NU)($2)>>3] &= ~(1U<<($2&7U));$n")
    of mCard: unaryExprChar(p, e, d, "#cardSet($1, " & $size & ')')
    of mLtSet, mLeSet:
      getTemp(p, getSysType(p.module.g.graph, unknownLineInfo(), tyInt), i) # our counter
      initLocExpr(p, e.sons[1], a)
      initLocExpr(p, e.sons[2], b)
      if d.k == locNone: getTemp(p, getSysType(p.module.g.graph, unknownLineInfo(), tyBool), d)
      linefmt(p, cpsStmts, lookupOpr[op],
           [rdLoc(i), rope(size), rdLoc(d), rdLoc(a), rdLoc(b)])
    of mEqSet:
      binaryExprChar(p, e, d, "(#nimCmpMem($1, $2, " & $(size) & ")==0)")
    of mMulSet, mPlusSet, mMinusSet, mSymDiffSet:
      # we inline the simple for loop for better code generation:
      getTemp(p, getSysType(p.module.g.graph, unknownLineInfo(), tyInt), i) # our counter
      initLocExpr(p, e.sons[1], a)
      initLocExpr(p, e.sons[2], b)
      if d.k == locNone: getTemp(p, setType, d)
      lineF(p, cpsStmts,
           "for ($1 = 0; $1 < $2; $1++) $n" &
           "  $3[$1] = $4[$1] $6 $5[$1];$n", [
          rdLoc(i), rope(size), rdLoc(d), rdLoc(a), rdLoc(b),
          rope(lookupOpr[op])])
    of mInSet: genInOp(p, e, d)
    else: internalError(p.config, e.info, "genSetOp")

proc genOrd(p: BProc, e: PNode, d: var TLoc) =
  unaryExprChar(p, e, d, "$1")

proc genSomeCast(p: BProc, e: PNode, d: var TLoc) =
  const
    ValueTypes = {tyTuple, tyObject, tyArray, tyOpenArray, tyVarargs}
  # we use whatever C gives us. Except if we have a value-type, we need to go
  # through its address:
  var a: TLoc
  initLocExpr(p, e.sons[1], a)
  let etyp = skipTypes(e.typ, abstractRange)
  if etyp.kind in ValueTypes and lfIndirect notin a.flags:
    putIntoDest(p, d, e, "(*($1*) ($2))" %
        [getTypeDesc(p.module, e.typ), addrLoc(p.config, a)], a.storage)
  elif etyp.kind == tyProc and etyp.callConv == ccClosure:
    putIntoDest(p, d, e, "(($1) ($2))" %
        [getClosureType(p.module, etyp, clHalfWithEnv), rdCharLoc(a)], a.storage)
  else:
    let srcTyp = skipTypes(e.sons[1].typ, abstractRange)
    # C++ does not like direct casts from pointer to shorter integral types
    if srcTyp.kind in {tyPtr, tyPointer} and etyp.kind in IntegralTypes:
      putIntoDest(p, d, e, "(($1) (ptrdiff_t) ($2))" %
          [getTypeDesc(p.module, e.typ), rdCharLoc(a)], a.storage)
    else:
      putIntoDest(p, d, e, "(($1) ($2))" %
          [getTypeDesc(p.module, e.typ), rdCharLoc(a)], a.storage)

proc genCast(p: BProc, e: PNode, d: var TLoc) =
  const ValueTypes = {tyFloat..tyFloat128, tyTuple, tyObject, tyArray}
  let
    destt = skipTypes(e.typ, abstractRange)
    srct = skipTypes(e.sons[1].typ, abstractRange)
  if destt.kind in ValueTypes or srct.kind in ValueTypes:
    # 'cast' and some float type involved? --> use a union.
    inc(p.labels)
    var lbl = p.labels.rope
    var tmp: TLoc
    tmp.r = "LOC$1.source" % [lbl]
    linefmt(p, cpsLocals, "union { $1 source; $2 dest; } LOC$3;$n",
      getTypeDesc(p.module, e.sons[1].typ), getTypeDesc(p.module, e.typ), lbl)
    tmp.k = locExpr
    tmp.lode = lodeTyp srct
    tmp.storage = OnStack
    tmp.flags = {}
    expr(p, e.sons[1], tmp)
    putIntoDest(p, d, e, "LOC$#.dest" % [lbl], tmp.storage)
  else:
    # I prefer the shorter cast version for pointer types -> generate less
    # C code; plus it's the right thing to do for closures:
    genSomeCast(p, e, d)

proc genRangeChck(p: BProc, n: PNode, d: var TLoc, magic: string) =
  var a: TLoc
  var dest = skipTypes(n.typ, abstractVar)
  # range checks for unsigned turned out to be buggy and annoying:
  if optRangeCheck notin p.options or dest.skipTypes({tyRange}).kind in
                                             {tyUInt..tyUInt64}:
    initLocExpr(p, n.sons[0], a)
    putIntoDest(p, d, n, "(($1) ($2))" %
        [getTypeDesc(p.module, dest), rdCharLoc(a)], a.storage)
  else:
    initLocExpr(p, n.sons[0], a)
    putIntoDest(p, d, lodeTyp dest, ropecg(p.module, "(($1)#$5($2, $3, $4))", [
        getTypeDesc(p.module, dest), rdCharLoc(a),
        genLiteral(p, n.sons[1], dest), genLiteral(p, n.sons[2], dest),
        rope(magic)]), a.storage)

proc genConv(p: BProc, e: PNode, d: var TLoc) =
  let destType = e.typ.skipTypes({tyVar, tyLent, tyGenericInst, tyAlias, tySink})
  if sameBackendType(destType, e.sons[1].typ):
    expr(p, e.sons[1], d)
  else:
    genSomeCast(p, e, d)

proc convStrToCStr(p: BProc, n: PNode, d: var TLoc) =
  var a: TLoc
  initLocExpr(p, n.sons[0], a)
  putIntoDest(p, d, n,
              ropecg(p.module, "#nimToCStringConv($1)", [rdLoc(a)]),
#                "($1 ? $1->data : (NCSTRING)\"\")" % [a.rdLoc],
              a.storage)

proc convCStrToStr(p: BProc, n: PNode, d: var TLoc) =
  var a: TLoc
  initLocExpr(p, n.sons[0], a)
  putIntoDest(p, d, n,
              ropecg(p.module, "#cstrToNimstr($1)", [rdLoc(a)]),
              a.storage)
  gcUsage(p.config, n)

proc genStrEquals(p: BProc, e: PNode, d: var TLoc) =
  var x: TLoc
  var a = e.sons[1]
  var b = e.sons[2]
  if a.kind in {nkStrLit..nkTripleStrLit} and a.strVal == "":
    initLocExpr(p, e.sons[2], x)
    putIntoDest(p, d, e,
      ropecg(p.module, "($1 == 0)", lenExpr(p, x)))
  elif b.kind in {nkStrLit..nkTripleStrLit} and b.strVal == "":
    initLocExpr(p, e.sons[1], x)
    putIntoDest(p, d, e,
      ropecg(p.module, "($1 == 0)", lenExpr(p, x)))
  else:
    binaryExpr(p, e, d, "#eqStrings($1, $2)")

proc binaryFloatArith(p: BProc, e: PNode, d: var TLoc, m: TMagic) =
  if {optNaNCheck, optInfCheck} * p.options != {}:
    const opr: array[mAddF64..mDivF64, string] = ["+", "-", "*", "/"]
    var a, b: TLoc
    assert(e.sons[1].typ != nil)
    assert(e.sons[2].typ != nil)
    initLocExpr(p, e.sons[1], a)
    initLocExpr(p, e.sons[2], b)
    putIntoDest(p, d, e, ropecg(p.module, "(($4)($2) $1 ($4)($3))",
                              rope(opr[m]), rdLoc(a), rdLoc(b),
                              getSimpleTypeDesc(p.module, e[1].typ)))
    if optNaNCheck in p.options:
      linefmt(p, cpsStmts, "#nanCheck($1);$n", rdLoc(d))
    if optInfCheck in p.options:
      linefmt(p, cpsStmts, "#infCheck($1);$n", rdLoc(d))
  else:
    binaryArith(p, e, d, m)

proc skipAddr(n: PNode): PNode =
  result = if n.kind in {nkAddr, nkHiddenAddr}: n[0] else: n

proc genWasMoved(p: BProc; n: PNode) =
  var a: TLoc
  initLocExpr(p, n[1].skipAddr, a)
  resetLoc(p, a)
  #linefmt(p, cpsStmts, "#nimZeroMem((void*)$1, sizeof($2));$n",
  #  addrLoc(p.config, a), getTypeDesc(p.module, a.t))

proc genMove(p: BProc; n: PNode; d: var TLoc) =
  if d.k == locNone: getTemp(p, n.typ, d)
  var a: TLoc
  initLocExpr(p, n[1].skipAddr, a)
  genAssignment(p, d, a, {})
  resetLoc(p, a)

proc genMagicExpr(p: BProc, e: PNode, d: var TLoc, op: TMagic) =
  case op
  of mOr, mAnd: genAndOr(p, e, d, op)
  of mNot..mToBiggestInt: unaryArith(p, e, d, op)
  of mUnaryMinusI..mAbsI: unaryArithOverflow(p, e, d, op)
  of mAddF64..mDivF64: binaryFloatArith(p, e, d, op)
  of mShrI..mXor: binaryArith(p, e, d, op)
  of mEqProc: genEqProc(p, e, d)
  of mAddI..mPred: binaryArithOverflow(p, e, d, op)
  of mRepr: genRepr(p, e, d)
  of mGetTypeInfo: genGetTypeInfo(p, e, d)
  of mSwap: genSwap(p, e, d)
  of mUnaryLt:
    if optOverflowCheck notin p.options: unaryExpr(p, e, d, "($1 - 1)")
    else: unaryExpr(p, e, d, "#subInt($1, 1)")
  of mInc, mDec:
    const opr: array[mInc..mDec, string] = ["$1 += $2;$n", "$1 -= $2;$n"]
    const fun64: array[mInc..mDec, string] = ["$# = #addInt64($#, $#);$n",
                                               "$# = #subInt64($#, $#);$n"]
    const fun: array[mInc..mDec, string] = ["$# = #addInt($#, $#);$n",
                                             "$# = #subInt($#, $#);$n"]
    let underlying = skipTypes(e.sons[1].typ, {tyGenericInst, tyAlias, tySink, tyVar, tyLent, tyRange})
    if optOverflowCheck notin p.options or underlying.kind in {tyUInt..tyUInt64}:
      binaryStmt(p, e, d, opr[op])
    else:
      var a, b: TLoc
      assert(e.sons[1].typ != nil)
      assert(e.sons[2].typ != nil)
      initLocExpr(p, e.sons[1], a)
      initLocExpr(p, e.sons[2], b)

      let ranged = skipTypes(e.sons[1].typ, {tyGenericInst, tyAlias, tySink, tyVar, tyLent})
      let res = binaryArithOverflowRaw(p, ranged, a, b,
        if underlying.kind == tyInt64: fun64[op] else: fun[op])
      putIntoDest(p, a, e.sons[1], "($#)($#)" % [
        getTypeDesc(p.module, ranged), res])

  of mConStrStr: genStrConcat(p, e, d)
  of mAppendStrCh:
    if p.config.selectedGC == gcDestructors:
      binaryStmtAddr(p, e, d, "#nimAddCharV1($1, $2);$n")
    else:
      var dest, b, call: TLoc
      initLoc(call, locCall, e, OnHeap)
      initLocExpr(p, e.sons[1], dest)
      initLocExpr(p, e.sons[2], b)
      call.r = ropecg(p.module, "#addChar($1, $2)", [rdLoc(dest), rdLoc(b)])
      genAssignment(p, dest, call, {})
  of mAppendStrStr: genStrAppend(p, e, d)
  of mAppendSeqElem:
    if p.config.selectedGc == gcDestructors:
      genCall(p, e, d)
    else:
      genSeqElemAppend(p, e, d)
  of mEqStr: genStrEquals(p, e, d)
  of mLeStr: binaryExpr(p, e, d, "(#cmpStrings($1, $2) <= 0)")
  of mLtStr: binaryExpr(p, e, d, "(#cmpStrings($1, $2) < 0)")
  of mIsNil: genIsNil(p, e, d)
  of mIntToStr: genDollar(p, e, d, "#nimIntToStr($1)")
  of mInt64ToStr: genDollar(p, e, d, "#nimInt64ToStr($1)")
  of mBoolToStr: genDollar(p, e, d, "#nimBoolToStr($1)")
  of mCharToStr: genDollar(p, e, d, "#nimCharToStr($1)")
  of mFloatToStr: genDollar(p, e, d, "#nimFloatToStr($1)")
  of mCStrToStr: genDollar(p, e, d, "#cstrToNimstr($1)")
  of mStrToStr: expr(p, e.sons[1], d)
  of mEnumToStr: genRepr(p, e, d)
  of mOf: genOf(p, e, d)
  of mNew: genNew(p, e)
  of mNewFinalize: genNewFinalize(p, e)
  of mNewSeq: genNewSeq(p, e)
  of mNewSeqOfCap: genNewSeqOfCap(p, e, d)
  of mSizeOf:
    let t = e.sons[1].typ.skipTypes({tyTypeDesc})
    putIntoDest(p, d, e, "((NI)sizeof($1))" % [getTypeDesc(p.module, t)])
  of mChr: genSomeCast(p, e, d)
  of mOrd: genOrd(p, e, d)
  of mLengthArray, mHigh, mLengthStr, mLengthSeq, mLengthOpenArray:
    genArrayLen(p, e, d, op)
  of mXLenStr:
    if not p.module.compileToCpp:
      unaryExpr(p, e, d, "($1->Sup.len)")
    else:
      unaryExpr(p, e, d, "$1->len")
  of mXLenSeq:
    # see 'taddhigh.nim' for why we need to use a temporary here:
    var a, tmp: TLoc
    initLocExpr(p, e[1], a)
    getIntTemp(p, tmp)
    var frmt: FormatStr
    if not p.module.compileToCpp:
      frmt = "$1 = $2->Sup.len;$n"
    else:
      frmt = "$1 = $2->len;$n"
    lineCg(p, cpsStmts, frmt, tmp.r, rdLoc(a))
    putIntoDest(p, d, e, tmp.r)
  of mGCref: unaryStmt(p, e, d, "if ($1) { #nimGCref($1); }$n")
  of mGCunref: unaryStmt(p, e, d, "if ($1) { #nimGCunref($1); }$n")
  of mSetLengthStr: genSetLengthStr(p, e, d)
  of mSetLengthSeq: genSetLengthSeq(p, e, d)
  of mIncl, mExcl, mCard, mLtSet, mLeSet, mEqSet, mMulSet, mPlusSet, mMinusSet,
     mInSet:
    genSetOp(p, e, d, op)
  of mCopyStr, mCopyStrLast:
    genCall(p, e, d)
  of mNewString, mNewStringOfCap, mExit, mParseBiggestFloat:
    var opr = e.sons[0].sym
    if lfNoDecl notin opr.loc.flags:
      discard cgsym(p.module, $opr.loc.r)
    genCall(p, e, d)
  of mReset: genReset(p, e)
  of mEcho: genEcho(p, e[1].skipConv)
  of mArrToSeq: genArrToSeq(p, e, d)
  of mNLen..mNError, mSlurp..mQuoteAst:
    localError(p.config, e.info, strutils.`%`(errXMustBeCompileTime, e.sons[0].sym.name.s))
  of mSpawn:
    let n = lowerings.wrapProcForSpawn(p.module.g.graph, p.module.module, e, e.typ, nil, nil)
    expr(p, n, d)
  of mParallel:
    when defined(leanCompiler):
      quit "compiler built without support for the 'parallel' statement"
    else:
      let n = semparallel.liftParallel(p.module.g.graph, p.module.module, e)
      expr(p, n, d)
  of mDeepCopy:
    var a, b: TLoc
    let x = if e[1].kind in {nkAddr, nkHiddenAddr}: e[1][0] else: e[1]
    initLocExpr(p, x, a)
    initLocExpr(p, e.sons[2], b)
    genDeepCopy(p, a, b)
  of mDotDot, mEqCString: genCall(p, e, d)
  of mWasMoved: genWasMoved(p, e)
  of mMove: genMove(p, e, d)
  of mSlice:
    localError(p.config, e.info, "invalid context for 'toOpenArray'; " &
      " 'toOpenArray' is only valid within a call expression")
  else:
    when defined(debugMagics):
      echo p.prc.name.s, " ", p.prc.id, " ", p.prc.flags, " ", p.prc.ast[genericParamsPos].kind
    internalError(p.config, e.info, "genMagicExpr: " & $op)

proc genSetConstr(p: BProc, e: PNode, d: var TLoc) =
  # example: { a..b, c, d, e, f..g }
  # we have to emit an expression of the form:
  # nimZeroMem(tmp, sizeof(tmp)); inclRange(tmp, a, b); incl(tmp, c);
  # incl(tmp, d); incl(tmp, e); inclRange(tmp, f, g);
  var
    a, b, idx: TLoc
  if nfAllConst in e.flags:
    putIntoDest(p, d, e, genSetNode(p, e))
  else:
    if d.k == locNone: getTemp(p, e.typ, d)
    if getSize(p.config, e.typ) > 8:
      # big set:
      linefmt(p, cpsStmts, "#nimZeroMem($1, sizeof($2));$n",
          [rdLoc(d), getTypeDesc(p.module, e.typ)])
      for it in e.sons:
        if it.kind == nkRange:
          getTemp(p, getSysType(p.module.g.graph, unknownLineInfo(), tyInt), idx) # our counter
          initLocExpr(p, it.sons[0], a)
          initLocExpr(p, it.sons[1], b)
          lineF(p, cpsStmts, "for ($1 = $3; $1 <= $4; $1++) $n" &
              "$2[(NU)($1)>>3] |=(1U<<((NU)($1)&7U));$n", [rdLoc(idx), rdLoc(d),
              rdSetElemLoc(p.config, a, e.typ), rdSetElemLoc(p.config, b, e.typ)])
        else:
          initLocExpr(p, it, a)
          lineF(p, cpsStmts, "$1[(NU)($2)>>3] |=(1U<<((NU)($2)&7U));$n",
               [rdLoc(d), rdSetElemLoc(p.config, a, e.typ)])
    else:
      # small set
      var ts = "NU" & $(getSize(p.config, e.typ) * 8)
      lineF(p, cpsStmts, "$1 = 0;$n", [rdLoc(d)])
      for it in e.sons:
        if it.kind == nkRange:
          getTemp(p, getSysType(p.module.g.graph, unknownLineInfo(), tyInt), idx) # our counter
          initLocExpr(p, it.sons[0], a)
          initLocExpr(p, it.sons[1], b)
          lineF(p, cpsStmts, "for ($1 = $3; $1 <= $4; $1++) $n" &
              "$2 |=((" & ts & ")(1)<<(($1)%(sizeof(" & ts & ")*8)));$n", [
              rdLoc(idx), rdLoc(d), rdSetElemLoc(p.config, a, e.typ),
              rdSetElemLoc(p.config, b, e.typ)])
        else:
          initLocExpr(p, it, a)
          lineF(p, cpsStmts,
               "$1 |=((" & ts & ")(1)<<(($2)%(sizeof(" & ts & ")*8)));$n",
               [rdLoc(d), rdSetElemLoc(p.config, a, e.typ)])

proc genTupleConstr(p: BProc, n: PNode, d: var TLoc) =
  var rec: TLoc
  if not handleConstExpr(p, n, d):
    let t = n.typ
    discard getTypeDesc(p.module, t) # so that any fields are initialized
    if d.k == locNone: getTemp(p, t, d)
    for i in countup(0, sonsLen(n) - 1):
      var it = n.sons[i]
      if it.kind == nkExprColonExpr: it = it.sons[1]
      initLoc(rec, locExpr, it, d.storage)
      rec.r = "$1.Field$2" % [rdLoc(d), rope(i)]
      expr(p, it, rec)

proc isConstClosure(n: PNode): bool {.inline.} =
  result = n.sons[0].kind == nkSym and isRoutine(n.sons[0].sym) and
      n.sons[1].kind == nkNilLit

proc genClosure(p: BProc, n: PNode, d: var TLoc) =
  assert n.kind in {nkPar, nkTupleConstr, nkClosure}

  if isConstClosure(n):
    inc(p.module.labels)
    var tmp = "CNSTCLOSURE" & rope(p.module.labels)
    addf(p.module.s[cfsData], "static NIM_CONST $1 $2 = $3;$n",
        [getTypeDesc(p.module, n.typ), tmp, genConstExpr(p, n)])
    putIntoDest(p, d, n, tmp, OnStatic)
  else:
    var tmp, a, b: TLoc
    initLocExpr(p, n.sons[0], a)
    initLocExpr(p, n.sons[1], b)
    if n.sons[0].skipConv.kind == nkClosure:
      internalError(p.config, n.info, "closure to closure created")
    # tasyncawait.nim breaks with this optimization:
    when false:
      if d.k != locNone:
        linefmt(p, cpsStmts, "$1.ClP_0 = $2; $1.ClE_0 = $3;$n",
                d.rdLoc, a.rdLoc, b.rdLoc)
    else:
      getTemp(p, n.typ, tmp)
      linefmt(p, cpsStmts, "$1.ClP_0 = $2; $1.ClE_0 = $3;$n",
              tmp.rdLoc, a.rdLoc, b.rdLoc)
      putLocIntoDest(p, d, tmp)

proc genArrayConstr(p: BProc, n: PNode, d: var TLoc) =
  var arr: TLoc
  if not handleConstExpr(p, n, d):
    if d.k == locNone: getTemp(p, n.typ, d)
    for i in countup(0, sonsLen(n) - 1):
      initLoc(arr, locExpr, lodeTyp elemType(skipTypes(n.typ, abstractInst)), d.storage)
      arr.r = "$1[$2]" % [rdLoc(d), intLiteral(i)]
      expr(p, n.sons[i], arr)

proc genComplexConst(p: BProc, sym: PSym, d: var TLoc) =
  requestConstImpl(p, sym)
  assert((sym.loc.r != nil) and (sym.loc.t != nil))
  putLocIntoDest(p, d, sym.loc)

template genStmtListExprImpl(exprOrStmt) {.dirty.} =
  #let hasNimFrame = magicsys.getCompilerProc("nimFrame") != nil
  let hasNimFrame = p.prc != nil and
      sfSystemModule notin p.module.module.flags and
      optStackTrace in p.prc.options
  var frameName: Rope = nil
  for i in 0 .. n.len - 2:
    let it = n[i]
    if it.kind == nkComesFrom:
      if hasNimFrame and frameName == nil:
        inc p.labels
        frameName = "FR" & rope(p.labels) & "_"
        let theMacro = it[0].sym
        add p.s(cpsStmts), initFrameNoDebug(p, frameName,
           makeCString theMacro.name.s,
           quotedFilename(p.config, theMacro.info), it.info.line.int)
    else:
      genStmts(p, it)
  if n.len > 0: exprOrStmt
  if frameName != nil:
    add p.s(cpsStmts), deinitFrameNoDebug(p, frameName)

proc genStmtListExpr(p: BProc, n: PNode, d: var TLoc) =
  genStmtListExprImpl:
    expr(p, n[n.len - 1], d)

proc genStmtList(p: BProc, n: PNode) =
  genStmtListExprImpl:
    genStmts(p, n[n.len - 1])

proc upConv(p: BProc, n: PNode, d: var TLoc) =
  var a: TLoc
  initLocExpr(p, n.sons[0], a)
  let dest = skipTypes(n.typ, abstractPtrs)
  if optObjCheck in p.options and not isObjLackingTypeField(dest):
    var r = rdLoc(a)
    var nilCheck: Rope = nil
    var t = skipTypes(a.t, abstractInst)
    while t.kind in {tyVar, tyLent, tyPtr, tyRef}:
      if t.kind notin {tyVar, tyLent}: nilCheck = r
      if t.kind notin {tyVar, tyLent} or not p.module.compileToCpp:
        r = "(*$1)" % [r]
      t = skipTypes(t.lastSon, abstractInst)
    discard getTypeDesc(p.module, t)
    if not p.module.compileToCpp:
      while t.kind == tyObject and t.sons[0] != nil:
        add(r, ".Sup")
        t = skipTypes(t.sons[0], skipPtrs)
    if nilCheck != nil:
      linefmt(p, cpsStmts, "if ($1) #chckObj($2.m_type, $3);$n",
              nilCheck, r, genTypeInfo(p.module, dest, n.info))
    else:
      linefmt(p, cpsStmts, "#chckObj($1.m_type, $2);$n",
              r, genTypeInfo(p.module, dest, n.info))
  if n.sons[0].typ.kind != tyObject:
    putIntoDest(p, d, n,
                "(($1) ($2))" % [getTypeDesc(p.module, n.typ), rdLoc(a)], a.storage)
  else:
    putIntoDest(p, d, n, "(*($1*) ($2))" %
                        [getTypeDesc(p.module, dest), addrLoc(p.config, a)], a.storage)

proc downConv(p: BProc, n: PNode, d: var TLoc) =
  if p.module.compileToCpp:
    discard getTypeDesc(p.module, skipTypes(n[0].typ, abstractPtrs))
    expr(p, n.sons[0], d)     # downcast does C++ for us
  else:
    var dest = skipTypes(n.typ, abstractPtrs)

    var arg = n.sons[0]
    while arg.kind == nkObjDownConv: arg = arg.sons[0]

    var src = skipTypes(arg.typ, abstractPtrs)
    discard getTypeDesc(p.module, src)
    var a: TLoc
    initLocExpr(p, arg, a)
    var r = rdLoc(a)
    let isRef = skipTypes(arg.typ, abstractInst).kind in {tyRef, tyPtr, tyVar, tyLent}
    if isRef:
      add(r, "->Sup")
    else:
      add(r, ".Sup")
    for i in countup(2, abs(inheritanceDiff(dest, src))): add(r, ".Sup")
    if isRef:
      # it can happen that we end up generating '&&x->Sup' here, so we pack
      # the '&x->Sup' into a temporary and then those address is taken
      # (see bug #837). However sometimes using a temporary is not correct:
      # init(TFigure(my)) # where it is passed to a 'var TFigure'. We test
      # this by ensuring the destination is also a pointer:
      if d.k == locNone and skipTypes(n.typ, abstractInst).kind in {tyRef, tyPtr, tyVar, tyLent}:
        getTemp(p, n.typ, d)
        linefmt(p, cpsStmts, "$1 = &$2;$n", rdLoc(d), r)
      else:
        r = "&" & r
        putIntoDest(p, d, n, r, a.storage)
    else:
      putIntoDest(p, d, n, r, a.storage)

proc exprComplexConst(p: BProc, n: PNode, d: var TLoc) =
  let t = n.typ
  discard getTypeDesc(p.module, t) # so that any fields are initialized
  let id = nodeTableTestOrSet(p.module.dataCache, n, p.module.labels)
  let tmp = p.module.tmpBase & rope(id)

  if id == p.module.labels:
    # expression not found in the cache:
    inc(p.module.labels)
    addf(p.module.s[cfsData], "NIM_CONST $1 $2 = $3;$n",
         [getTypeDesc(p.module, t), tmp, genConstExpr(p, n)])

  if d.k == locNone:
    fillLoc(d, locData, n, tmp, OnStatic)
  else:
    putDataIntoDest(p, d, n, tmp)
    # This fixes bug #4551, but we really need better dataflow
    # analysis to make this 100% safe.
    if t.kind notin {tySequence, tyString}:
      d.storage = OnStatic

proc expr(p: BProc, n: PNode, d: var TLoc) =
  p.currLineInfo = n.info
  case n.kind
  of nkSym:
    var sym = n.sym
    case sym.kind
    of skMethod:
      if {sfDispatcher, sfForward} * sym.flags != {}:
        # we cannot produce code for the dispatcher yet:
        fillProcLoc(p.module, n)
        genProcPrototype(p.module, sym)
      else:
        genProc(p.module, sym)
      putLocIntoDest(p, d, sym.loc)
    of skProc, skConverter, skIterator, skFunc:
      #if sym.kind == skIterator:
      #  echo renderTree(sym.getBody, {renderIds})
      if sfCompileTime in sym.flags:
        localError(p.config, n.info, "request to generate code for .compileTime proc: " &
           sym.name.s)
      genProc(p.module, sym)
      if sym.loc.r == nil or sym.loc.lode == nil:
        internalError(p.config, n.info, "expr: proc not init " & sym.name.s)
      putLocIntoDest(p, d, sym.loc)
    of skConst:
      if isSimpleConst(sym.typ):
        putIntoDest(p, d, n, genLiteral(p, sym.ast, sym.typ), OnStatic)
      else:
        genComplexConst(p, sym, d)
    of skEnumField:
      # we never reach this case - as of the time of this comment,
      # skEnumField is folded to an int in semfold.nim, but this code
      # remains for robustness
      putIntoDest(p, d, n, rope(sym.position))
    of skVar, skForVar, skResult, skLet:
      if {sfGlobal, sfThread} * sym.flags != {}:
        genVarPrototype(p.module, n)
      if sym.loc.r == nil or sym.loc.t == nil:
        #echo "FAILED FOR PRCO ", p.prc.name.s
        #echo renderTree(p.prc.ast, {renderIds})
        internalError p.config, n.info, "expr: var not init " & sym.name.s & "_" & $sym.id
      if sfThread in sym.flags:
        accessThreadLocalVar(p, sym)
        if emulatedThreadVars(p.config):
          putIntoDest(p, d, sym.loc.lode, "NimTV_->" & sym.loc.r)
        else:
          putLocIntoDest(p, d, sym.loc)
      else:
        putLocIntoDest(p, d, sym.loc)
    of skTemp:
      if sym.loc.r == nil or sym.loc.t == nil:
        #echo "FAILED FOR PRCO ", p.prc.name.s
        #echo renderTree(p.prc.ast, {renderIds})
        internalError(p.config, n.info, "expr: temp not init " & sym.name.s & "_" & $sym.id)
      putLocIntoDest(p, d, sym.loc)
    of skParam:
      if sym.loc.r == nil or sym.loc.t == nil:
        # echo "FAILED FOR PRCO ", p.prc.name.s
        # debug p.prc.typ.n
        # echo renderTree(p.prc.ast, {renderIds})
        internalError(p.config, n.info, "expr: param not init " & sym.name.s & "_" & $sym.id)
      putLocIntoDest(p, d, sym.loc)
    else: internalError(p.config, n.info, "expr(" & $sym.kind & "); unknown symbol")
  of nkNilLit:
    if not isEmptyType(n.typ):
      putIntoDest(p, d, n, genLiteral(p, n))
  of nkStrLit..nkTripleStrLit:
    putDataIntoDest(p, d, n, genLiteral(p, n))
  of nkIntLit..nkUInt64Lit,
     nkFloatLit..nkFloat128Lit, nkCharLit:
    putIntoDest(p, d, n, genLiteral(p, n))
  of nkCall, nkHiddenCallConv, nkInfix, nkPrefix, nkPostfix, nkCommand,
     nkCallStrLit:
    genLineDir(p, n)
    let op = n.sons[0]
    if n.typ.isNil:
      # discard the value:
      var a: TLoc
      if op.kind == nkSym and op.sym.magic != mNone:
        genMagicExpr(p, n, a, op.sym.magic)
      else:
        genCall(p, n, a)
    else:
      # load it into 'd':
      if op.kind == nkSym and op.sym.magic != mNone:
        genMagicExpr(p, n, d, op.sym.magic)
      else:
        genCall(p, n, d)
  of nkCurly:
    if isDeepConstExpr(n) and n.len != 0:
      putIntoDest(p, d, n, genSetNode(p, n))
    else:
      genSetConstr(p, n, d)
  of nkBracket:
    if isDeepConstExpr(n) and n.len != 0:
      exprComplexConst(p, n, d)
    elif skipTypes(n.typ, abstractVarRange).kind == tySequence:
      genSeqConstr(p, n, d)
    else:
      genArrayConstr(p, n, d)
  of nkPar, nkTupleConstr:
    if n.typ != nil and n.typ.kind == tyProc and n.len == 2:
      genClosure(p, n, d)
    elif isDeepConstExpr(n) and n.len != 0:
      exprComplexConst(p, n, d)
    else:
      genTupleConstr(p, n, d)
  of nkObjConstr: genObjConstr(p, n, d)
  of nkCast: genCast(p, n, d)
  of nkHiddenStdConv, nkHiddenSubConv, nkConv: genConv(p, n, d)
  of nkHiddenAddr, nkAddr: genAddr(p, n, d)
  of nkBracketExpr: genBracketExpr(p, n, d)
  of nkDerefExpr, nkHiddenDeref: genDeref(p, n, d)
  of nkDotExpr: genRecordField(p, n, d)
  of nkCheckedFieldExpr: genCheckedRecordField(p, n, d)
  of nkBlockExpr, nkBlockStmt: genBlock(p, n, d)
  of nkStmtListExpr: genStmtListExpr(p, n, d)
  of nkStmtList: genStmtList(p, n)
  of nkIfExpr, nkIfStmt: genIf(p, n, d)
  of nkWhen:
    # This should be a "when nimvm" node.
    expr(p, n.sons[1].sons[0], d)
  of nkObjDownConv: downConv(p, n, d)
  of nkObjUpConv: upConv(p, n, d)
  of nkChckRangeF: genRangeChck(p, n, d, "chckRangeF")
  of nkChckRange64: genRangeChck(p, n, d, "chckRange64")
  of nkChckRange: genRangeChck(p, n, d, "chckRange")
  of nkStringToCString: convStrToCStr(p, n, d)
  of nkCStringToString: convCStrToStr(p, n, d)
  of nkLambdaKinds:
    var sym = n.sons[namePos].sym
    genProc(p.module, sym)
    if sym.loc.r == nil or sym.loc.lode == nil:
      internalError(p.config, n.info, "expr: proc not init " & sym.name.s)
    putLocIntoDest(p, d, sym.loc)
  of nkClosure: genClosure(p, n, d)

  of nkEmpty: discard
  of nkWhileStmt: genWhileStmt(p, n)
  of nkVarSection, nkLetSection: genVarStmt(p, n)
  of nkConstSection: discard  # consts generated lazily on use
  of nkForStmt: internalError(p.config, n.info, "for statement not eliminated")
  of nkCaseStmt: genCase(p, n, d)
  of nkReturnStmt: genReturnStmt(p, n)
  of nkBreakStmt: genBreakStmt(p, n)
  of nkAsgn:
    if nfPreventCg notin n.flags:
      genAsgn(p, n, fastAsgn=false)
  of nkFastAsgn:
    if nfPreventCg notin n.flags:
      # transf is overly aggressive with 'nkFastAsgn', so we work around here.
      # See tests/run/tcnstseq3 for an example that would fail otherwise.
      genAsgn(p, n, fastAsgn=p.prc != nil)
  of nkDiscardStmt:
    let ex = n[0]
    if ex.kind != nkEmpty:
      genLineDir(p, n)
      var a: TLoc
      if ex.kind in nkCallKinds and (ex[0].kind != nkSym or
                                     ex[0].sym.magic == mNone):
        # bug #6037: do not assign to a temp in C++ mode:
        incl a.flags, lfSingleUse
        genCall(p, ex, a)
        if lfSingleUse notin a.flags:
          line(p, cpsStmts, a.r & ";\L")
      else:
        initLocExpr(p, ex, a)
  of nkAsmStmt: genAsmStmt(p, n)
  of nkTryStmt:
    if p.module.compileToCpp and optNoCppExceptions notin p.config.globalOptions:
      genTryCpp(p, n, d)
    else:
      genTry(p, n, d)
  of nkRaiseStmt: genRaiseStmt(p, n)
  of nkTypeSection:
    # we have to emit the type information for object types here to support
    # separate compilation:
    genTypeSection(p.module, n)
  of nkCommentStmt, nkIteratorDef, nkIncludeStmt,
     nkImportStmt, nkImportExceptStmt, nkExportStmt, nkExportExceptStmt,
     nkFromStmt, nkTemplateDef, nkMacroDef, nkStaticStmt:
    discard
  of nkPragma: genPragma(p, n)
  of nkPragmaBlock: expr(p, n.lastSon, d)
  of nkProcDef, nkFuncDef, nkMethodDef, nkConverterDef:
    if n.sons[genericParamsPos].kind == nkEmpty:
      var prc = n.sons[namePos].sym
      # due to a bug/limitation in the lambda lifting, unused inner procs
      # are not transformed correctly. We work around this issue (#411) here
      # by ensuring it's no inner proc (owner is a module):
      if prc.skipGenericOwner.kind == skModule and sfCompileTime notin prc.flags:
        if ({sfExportc, sfCompilerProc} * prc.flags == {sfExportc}) or
            (sfExportc in prc.flags and lfExportLib in prc.loc.flags) or
            (prc.kind == skMethod):
          # we have not only the header:
          if prc.getBody.kind != nkEmpty or lfDynamicLib in prc.loc.flags:
            genProc(p.module, prc)
  of nkParForStmt: genParForStmt(p, n)
  of nkState: genState(p, n)
  of nkGotoState: genGotoState(p, n)
  of nkBreakState: genBreakState(p, n, d)
  else: internalError(p.config, n.info, "expr(" & $n.kind & "); unknown node kind")

proc genNamedConstExpr(p: BProc, n: PNode): Rope =
  if n.kind == nkExprColonExpr: result = genConstExpr(p, n.sons[1])
  else: result = genConstExpr(p, n)

proc getDefaultValue(p: BProc; typ: PType; info: TLineInfo): Rope =
  var t = skipTypes(typ, abstractRange-{tyTypeDesc})
  case t.kind
  of tyBool: result = rope"NIM_FALSE"
  of tyEnum, tyChar, tyInt..tyInt64, tyUInt..tyUInt64: result = rope"0"
  of tyFloat..tyFloat128: result = rope"0.0"
  of tyCString, tyString, tyVar, tyLent, tyPointer, tyPtr, tySequence, tyExpr,
     tyStmt, tyTypeDesc, tyStatic, tyRef, tyNil:
    result = rope"NIM_NIL"
  of tyProc:
    if t.callConv != ccClosure:
      result = rope"NIM_NIL"
    else:
      result = rope"{NIM_NIL, NIM_NIL}"
  of tyObject:
    if not isObjLackingTypeField(t) and not p.module.compileToCpp:
      result = "{{$1}}" % [genTypeInfo(p.module, t, info)]
    else:
      result = rope"{}"
  of tyTuple:
    result = rope"{"
    for i in 0 ..< typ.len:
      if i > 0: result.add ", "
      result.add getDefaultValue(p, typ.sons[i], info)
    result.add "}"
  of tyArray: result = rope"{}"
  of tySet:
    if mapType(p.config, t) == ctArray: result = rope"{}"
    else: result = rope"0"
  else:
    globalError(p.config, info, "cannot create null element for: " & $t.kind)

proc getNullValueAux(p: BProc; t: PType; obj, cons: PNode, result: var Rope; count: var int) =
  case obj.kind
  of nkRecList:
    for it in obj.sons:
      getNullValueAux(p, t, it, cons, result, count)
  of nkRecCase:
    getNullValueAux(p, t, obj.sons[0], cons, result, count)
    for i in countup(1, sonsLen(obj) - 1):
      getNullValueAux(p, t, lastSon(obj.sons[i]), cons, result, count)
  of nkSym:
    if count > 0: result.add ", "
    inc count
    let field = obj.sym
    for i in 1..<cons.len:
      if cons[i].kind == nkExprColonExpr:
        if cons[i][0].sym.name.id == field.name.id:
          result.add genConstExpr(p, cons[i][1])
          return
      elif i == field.position:
        result.add genConstExpr(p, cons[i])
        return
    # not found, produce default value:
    result.add getDefaultValue(p, field.typ, cons.info)
  else:
    localError(p.config, cons.info, "cannot create null element for: " & $obj)

proc getNullValueAuxT(p: BProc; orig, t: PType; obj, cons: PNode, result: var Rope; count: var int) =
  var base = t.sons[0]
  let oldRes = result
  if not p.module.compileToCpp: result.add "{"
  let oldcount = count
  if base != nil:
    base = skipTypes(base, skipPtrs)
    getNullValueAuxT(p, orig, base, base.n, cons, result, count)
  elif not isObjLackingTypeField(t) and not p.module.compileToCpp:
    addf(result, "$1", [genTypeInfo(p.module, orig, obj.info)])
    inc count
  getNullValueAux(p, t, obj, cons, result, count)
  # do not emit '{}' as that is not valid C:
  if oldcount == count: result = oldres
  elif not p.module.compileToCpp: result.add "}"

proc genConstObjConstr(p: BProc; n: PNode): Rope =
  result = nil
  let t = n.typ.skipTypes(abstractInst)
  var count = 0
  #if not isObjLackingTypeField(t) and not p.module.compileToCpp:
  #  addf(result, "{$1}", [genTypeInfo(p.module, t)])
  #  inc count
  getNullValueAuxT(p, t, t, t.n, n, result, count)
  if p.module.compileToCpp:
    result = "{$1}$n" % [result]

proc genConstSimpleList(p: BProc, n: PNode): Rope =
  var length = sonsLen(n)
  result = rope("{")
  let t = n.typ.skipTypes(abstractInst)
  for i in countup(0, length - 2):
    addf(result, "$1,$n", [genNamedConstExpr(p, n.sons[i])])
  if length > 0:
    add(result, genNamedConstExpr(p, n.sons[length - 1]))
  addf(result, "}$n", [])

proc genConstSeq(p: BProc, n: PNode, t: PType): Rope =
  var data = "{{$1, $1 | NIM_STRLIT_FLAG}" % [n.len.rope]
  if n.len > 0:
    # array part needs extra curlies:
    data.add(", {")
    for i in countup(0, n.len - 1):
      if i > 0: data.addf(",$n", [])
      data.add genConstExpr(p, n.sons[i])
    data.add("}")
  data.add("}")

  result = getTempName(p.module)
  let base = t.skipTypes(abstractInst).sons[0]

  appcg(p.module, cfsData,
        "NIM_CONST struct {$n" &
        "  #TGenericSeq Sup;$n" &
        "  $1 data[$2];$n" &
        "} $3 = $4;$n", [
        getTypeDesc(p.module, base), n.len.rope, result, data])

  result = "(($1)&$2)" % [getTypeDesc(p.module, t), result]

proc genConstExpr(p: BProc, n: PNode): Rope =
  case n.kind
  of nkHiddenStdConv, nkHiddenSubConv:
    result = genConstExpr(p, n.sons[1])
  of nkCurly:
    var cs: TBitSet
    toBitSet(p.config, n, cs)
    result = genRawSetData(cs, int(getSize(p.config, n.typ)))
  of nkBracket, nkPar, nkTupleConstr, nkClosure:
    var t = skipTypes(n.typ, abstractInst)
    if t.kind == tySequence:
      result = genConstSeq(p, n, n.typ)
    elif t.kind == tyProc and t.callConv == ccClosure and n.len > 1 and
         n.sons[1].kind == nkNilLit:
      # Conversion: nimcall -> closure.
      # this hack fixes issue that nkNilLit is expanded to {NIM_NIL,NIM_NIL}
      # this behaviour is needed since closure_var = nil must be
      # expanded to {NIM_NIL,NIM_NIL}
      # in VM closures are initialized with nkPar(nkNilLit, nkNilLit)
      # leading to duplicate code like this:
      # "{NIM_NIL,NIM_NIL}, {NIM_NIL,NIM_NIL}"
      if n[0].kind == nkNilLit:
        result = ~"{NIM_NIL,NIM_NIL}"
      else:
        var d: TLoc
        initLocExpr(p, n[0], d)
        result = "{(($1) $2),NIM_NIL}" % [getClosureType(p.module, t, clHalfWithEnv), rdLoc(d)]
    else:
      result = genConstSimpleList(p, n)
  of nkObjConstr:
    result = genConstObjConstr(p, n)
  of nkStrLit..nkTripleStrLit:
    if p.config.selectedGc == gcDestructors:
      result = genStringLiteralV2Const(p.module, n)
    else:
      var d: TLoc
      initLocExpr(p, n, d)
      result = rdLoc(d)
  else:
    var d: TLoc
    initLocExpr(p, n, d)
    result = rdLoc(d)
