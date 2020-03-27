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

proc canRaiseDisp(p: BProc; n: PNode): bool =
  # we assume things like sysFatal cannot raise themselves
  if n.kind == nkSym and {sfNeverRaises, sfImportc, sfCompilerProc} * n.sym.flags != {}:
    result = false
  elif optPanics in p.config.globalOptions or
      (n.kind == nkSym and sfSystemModule in getModule(n.sym).flags):
    # we know we can be strict:
    result = canRaise(n)
  else:
    # we have to be *very* conservative:
    result = canRaiseConservative(n)

proc leftAppearsOnRightSide(le, ri: PNode): bool =
  if le != nil:
    for i in 1..<ri.len:
      let r = ri[i]
      if isPartOf(le, r) != arNo: return true

proc hasNoInit(call: PNode): bool {.inline.} =
  result = call[0].kind == nkSym and sfNoInit in call[0].sym.flags

proc isHarmlessStore(p: BProc; canRaise: bool; d: TLoc): bool =
  if d.k in {locTemp, locNone} or not canRaise:
    result = true
  elif d.k == locLocalVar and p.withinTryWithExcept == 0:
    # we cannot observe a store to a local variable if the current proc
    # has no error handler:
    result = true
  else:
    result = false

proc fixupCall(p: BProc, le, ri: PNode, d: var TLoc,
               callee, params: Rope) =
  let canRaise = p.config.exc == excGoto and canRaiseDisp(p, ri[0])
  genLineDir(p, ri)
  var pl = callee & ~"(" & params
  # getUniqueType() is too expensive here:
  var typ = skipTypes(ri[0].typ, abstractInst)
  if typ[0] != nil:
    if isInvalidReturnType(p.config, typ[0]):
      if params != nil: pl.add(~", ")
      # beware of 'result = p(result)'. We may need to allocate a temporary:
      if d.k in {locTemp, locNone} or not leftAppearsOnRightSide(le, ri):
        # Great, we can use 'd':
        if d.k == locNone: getTemp(p, typ[0], d, needsInit=true)
        elif d.k notin {locTemp} and not hasNoInit(ri):
          # reset before pass as 'result' var:
          discard "resetLoc(p, d)"
        pl.add(addrLoc(p.config, d))
        pl.add(~");$n")
        line(p, cpsStmts, pl)
      else:
        var tmp: TLoc
        getTemp(p, typ[0], tmp, needsInit=true)
        pl.add(addrLoc(p.config, tmp))
        pl.add(~");$n")
        line(p, cpsStmts, pl)
        genAssignment(p, d, tmp, {}) # no need for deep copying
      if canRaise: raiseExit(p)
    else:
      pl.add(~")")
      if p.module.compileToCpp:
        if lfSingleUse in d.flags:
          # do not generate spurious temporaries for C++! For C we're better off
          # with them to prevent undefined behaviour and because the codegen
          # is free to emit expressions multiple times!
          d.k = locCall
          d.setRope pl
          excl d.flags, lfSingleUse
        else:
          if d.k == locNone and p.splitDecls == 0:
            getTempCpp(p, typ[0], d, pl)
          else:
            if d.k == locNone: getTemp(p, typ[0], d)
            var list: TLoc
            initLoc(list, locCall, d.lode, OnUnknown)
            list.setRope pl
            genAssignment(p, d, list, {}) # no need for deep copying
            if canRaise: raiseExit(p)

      elif isHarmlessStore(p, canRaise, d):
        if d.k == locNone: getTemp(p, typ[0], d)
        assert(d.t != nil)        # generate an assignment to d:
        var list: TLoc
        initLoc(list, locCall, d.lode, OnUnknown)
        list.setRope pl
        genAssignment(p, d, list, {}) # no need for deep copying
        if canRaise: raiseExit(p)
      else:
        var tmp: TLoc
        getTemp(p, typ[0], tmp, needsInit=true)
        var list: TLoc
        initLoc(list, locCall, d.lode, OnUnknown)
        list.r = pl
        genAssignment(p, tmp, list, {}) # no need for deep copying
        if canRaise: raiseExit(p)
        genAssignment(p, d, tmp, {})
  else:
    pl.add(~");$n")
    line(p, cpsStmts, pl)
    if canRaise: raiseExit(p)

proc genBoundsCheck(p: BProc; arr, a, b: TLoc)

proc openArrayLoc(p: BProc, formalType: PType, n: PNode): Rope =
  var a: TLoc

  var q = skipConv(n)
  var skipped = false
  while q.kind == nkStmtListExpr and q.len > 0:
    skipped = true
    q = q.lastSon
  if getMagic(q) == mSlice:
    # magic: pass slice to openArray:
    if skipped:
      q = skipConv(n)
      while q.kind == nkStmtListExpr and q.len > 0:
        for i in 0..<q.len-1:
          genStmts(p, q[i])
        q = q.lastSon
    var b, c: TLoc
    initLocExpr(p, q[1], a)
    initLocExpr(p, q[2], b)
    initLocExpr(p, q[3], c)
    # but first produce the required index checks:
    if optBoundsCheck in p.options:
      genBoundsCheck(p, a, b, c)
    let ty = skipTypes(a.t, abstractVar+{tyPtr})
    let dest = getTypeDesc(p.module, n.typ[0])
    case ty.kind
    of tyArray:
      let first = toInt64(firstOrd(p.config, ty))
      if first == 0:
        result = "($4*)(($1)+($2)), ($3)-($2)+1" % [rdLoc(a), rdLoc(b), rdLoc(c), dest]
      else:
        result = "($5*)($1)+(($2)-($4)), ($3)-($2)+1" %
          [rdLoc(a), rdLoc(b), rdLoc(c), intLiteral(first), dest]
    of tyOpenArray, tyVarargs, tyUncheckedArray, tyCString:
      result = "($4*)($1)+($2), ($3)-($2)+1" % [rdLoc(a), rdLoc(b), rdLoc(c), dest]
    of tyString, tySequence:
      let atyp = skipTypes(a.t, abstractInst)
      if formalType.skipTypes(abstractInst).kind == tyVar and atyp.kind == tyString and 
          optSeqDestructors in p.config.globalOptions:
        linefmt(p, cpsStmts, "#nimPrepareStrMutationV2($1);$n", [byRefLoc(p, a)])
      if atyp.kind == tyVar and not compileToCpp(p.module):
        result = "($5*)(*$1)$4+($2), ($3)-($2)+1" % [rdLoc(a), rdLoc(b), rdLoc(c), dataField(p), dest]
      else:
        result = "($5*)$1$4+($2), ($3)-($2)+1" % [rdLoc(a), rdLoc(b), rdLoc(c), dataField(p), dest]
    else:
      internalError(p.config, "openArrayLoc: " & typeToString(a.t))
  else:
    initLocExpr(p, n, a)
    case skipTypes(a.t, abstractVar).kind
    of tyOpenArray, tyVarargs:
      result = "$1, $1Len_0" % [rdLoc(a)]
    of tyString, tySequence:
      let ntyp = skipTypes(n.typ, abstractInst)
      if formalType.skipTypes(abstractInst).kind == tyVar and ntyp.kind == tyString and 
          optSeqDestructors in p.config.globalOptions:
        linefmt(p, cpsStmts, "#nimPrepareStrMutationV2($1);$n", [byRefLoc(p, a)])
      if ntyp.kind == tyVar and not compileToCpp(p.module):
        var t: TLoc
        t.setRope "(*$1)" % [a.rdLoc]
        result = "(*$1)$3, $2" % [a.rdLoc, lenExpr(p, t), dataField(p)]
      else:
        result = "$1$3, $2" % [a.rdLoc, lenExpr(p, a), dataField(p)]
    of tyArray:
      result = "$1, $2" % [rdLoc(a), rope(lengthOrd(p.config, a.t))]
    of tyPtr, tyRef:
      case lastSon(a.t).kind
      of tyString, tySequence:
        var t: TLoc
        t.setRope "(*$1)" % [a.rdLoc]
        result = "(*$1)$3, $2" % [a.rdLoc, lenExpr(p, t), dataField(p)]
      of tyArray:
        result = "$1, $2" % [rdLoc(a), rope(lengthOrd(p.config, lastSon(a.t)))]
      else:
        internalError(p.config, "openArrayLoc: " & typeToString(a.t))
    else: internalError(p.config, "openArrayLoc: " & typeToString(a.t))

proc genArgStringToCString(p: BProc, n: PNode): Rope {.inline.} =
  var a: TLoc
  initLocExpr(p, n[0], a)
  result = ropecg(p.module, "#nimToCStringConv($1)", [a.rdLoc])

proc genArg(p: BProc, n: PNode, param: PSym; call: PNode): Rope =
  var a: TLoc
  if n.kind == nkStringToCString:
    result = genArgStringToCString(p, n)
  elif skipTypes(param.typ, abstractVar).kind in {tyOpenArray, tyVarargs}:
    var n = if n.kind != nkHiddenAddr: n else: n[0]
    result = openArrayLoc(p, param.typ, n)
  elif ccgIntroducedPtr(p.config, param, call[0].typ[0]):
    initLocExpr(p, n, a)
    result = addrLoc(p.config, a)
  elif p.module.compileToCpp and param.typ.kind == tyVar and
      n.kind == nkHiddenAddr:
    initLocExprSingleUse(p, n[0], a)
    # if the proc is 'importc'ed but not 'importcpp'ed then 'var T' still
    # means '*T'. See posix.nim for lots of examples that do that in the wild.
    let callee = call[0]
    if callee.kind == nkSym and
        {sfImportc, sfInfixCall, sfCompilerProc} * callee.sym.flags == {sfImportc} and
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
  if i < typ.len:
    assert(typ.n[i].kind == nkSym)
    let paramType = typ.n[i]
    if not paramType.typ.isCompileTimeOnly:
      if params != nil: params.add(~", ")
      params.add(genArg(p, ri[i], paramType.sym, ri))
  else:
    if params != nil: params.add(~", ")
    params.add(genArgNoParam(p, ri[i]))

proc addActualSuffixForHCR(res: var Rope, module: PSym, sym: PSym) =
  if sym.flags * {sfImportc, sfNonReloadable} == {} and sym.loc.k == locProc and
      (sym.typ.callConv == ccInline or sym.owner.id == module.id):
    res = res & "_actual".rope

proc genPrefixCall(p: BProc, le, ri: PNode, d: var TLoc) =
  var op: TLoc
  # this is a hotspot in the compiler
  initLocExpr(p, ri[0], op)
  var params: Rope
  # getUniqueType() is too expensive here:
  var typ = skipTypes(ri[0].typ, abstractInstOwned)
  assert(typ.kind == tyProc)
  assert(typ.len == typ.n.len)
  for i in 1..<ri.len:
    genParamLoop(params)
  var callee = rdLoc(op)
  if p.hcrOn and ri[0].kind == nkSym:
    callee.addActualSuffixForHCR(p.module.module, ri[0].sym)
  fixupCall(p, le, ri, d, callee, params)

proc genClosureCall(p: BProc, le, ri: PNode, d: var TLoc) =

  proc getRawProcType(p: BProc, t: PType): Rope =
    result = getClosureType(p.module, t, clHalf)

  proc addComma(r: Rope): Rope =
    result = if r == nil: r else: r & ~", "

  const PatProc = "$1.ClE_0? $1.ClP_0($3$1.ClE_0):(($4)($1.ClP_0))($2)"
  const PatIter = "$1.ClP_0($3$1.ClE_0)" # we know the env exists
  var op: TLoc
  initLocExpr(p, ri[0], op)
  var pl: Rope

  var typ = skipTypes(ri[0].typ, abstractInst)
  assert(typ.kind == tyProc)
  for i in 1..<ri.len:
    assert(typ.len == typ.n.len)
    genParamLoop(pl)

  template genCallPattern {.dirty.} =
    if tfIterator in typ.flags:
      lineF(p, cpsStmts, PatIter & ";$n", [rdLoc(op), pl, pl.addComma, rawProc])
    else:
      lineF(p, cpsStmts, PatProc & ";$n", [rdLoc(op), pl, pl.addComma, rawProc])

  let rawProc = getRawProcType(p, typ)
  let canRaise = p.config.exc == excGoto and canRaiseDisp(p, ri[0])
  if typ[0] != nil:
    if isInvalidReturnType(p.config, typ[0]):
      if ri.len > 1: pl.add(~", ")
      # beware of 'result = p(result)'. We may need to allocate a temporary:
      if d.k in {locTemp, locNone} or not leftAppearsOnRightSide(le, ri):
        # Great, we can use 'd':
        if d.k == locNone:
          getTemp(p, typ[0], d, needsInit=true)
        elif d.k notin {locTemp} and not hasNoInit(ri):
          # reset before pass as 'result' var:
          discard "resetLoc(p, d)"
        pl.add(addrLoc(p.config, d))
        genCallPattern()
      else:
        var tmp: TLoc
        getTemp(p, typ[0], tmp, needsInit=true)
        pl.add(addrLoc(p.config, tmp))
        genCallPattern()
        if canRaise: raiseExit(p)
        genAssignment(p, d, tmp, {}) # no need for deep copying
    elif isHarmlessStore(p, canRaise, d):
      if d.k == locNone: getTemp(p, typ[0], d)
      assert(d.t != nil)        # generate an assignment to d:
      var list: TLoc
      initLoc(list, locCall, d.lode, OnUnknown)
      if tfIterator in typ.flags:
        list.setRope PatIter % [rdLoc(op), pl, pl.addComma, rawProc]
      else:
        list.setRope PatProc % [rdLoc(op), pl, pl.addComma, rawProc]

      genAssignment(p, d, list, {}) # no need for deep copying
      if canRaise: raiseExit(p)
    else:
      var tmp: TLoc
      getTemp(p, typ[0], tmp)
      assert(d.t != nil)        # generate an assignment to d:
      var list: TLoc
      initLoc(list, locCall, d.lode, OnUnknown)
      if tfIterator in typ.flags:
        list.r = PatIter % [rdLoc(op), pl, pl.addComma, rawProc]
      else:
        list.r = PatProc % [rdLoc(op), pl, pl.addComma, rawProc]
      genAssignment(p, tmp, list, {})
      if canRaise: raiseExit(p)
      genAssignment(p, d, tmp, {})
  else:
    genCallPattern()
    if canRaise: raiseExit(p)

proc genOtherArg(p: BProc; ri: PNode; i: int; typ: PType): Rope =
  if i < typ.len:
    # 'var T' is 'T&' in C++. This means we ignore the request of
    # any nkHiddenAddr when it's a 'var T'.
    let paramType = typ.n[i]
    assert(paramType.kind == nkSym)
    if paramType.typ.isCompileTimeOnly:
      result = nil
    elif typ[i].kind == tyVar and ri[i].kind == nkHiddenAddr:
      result = genArgNoParam(p, ri[i][0])
    else:
      result = genArgNoParam(p, ri[i]) #, typ.n[i].sym)
  else:
    if tfVarargs notin typ.flags:
      localError(p.config, ri.info, "wrong argument count")
      result = nil
    else:
      result = genArgNoParam(p, ri[i])

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
    n = n[0]
    isAddr = true
  of nkDerefExpr, nkHiddenDeref:
    n = n[0]
  else: return n
  if n.kind == nkObjDownConv: n = n[0]
  if isAddr and n.kind in {nkDerefExpr, nkHiddenDeref}:
    result = n[0]
  elif n.kind in {nkAddr, nkHiddenAddr}:
    result = n[0]
  else:
    result = node

proc genThisArg(p: BProc; ri: PNode; i: int; typ: PType): Rope =
  # for better or worse c2nim translates the 'this' argument to a 'var T'.
  # However manual wrappers may also use 'ptr T'. In any case we support both
  # for convenience.
  internalAssert p.config, i < typ.len
  assert(typ.n[i].kind == nkSym)
  # if the parameter is lying (tyVar) and thus we required an additional deref,
  # skip the deref:
  var ri = ri[i]
  while ri.kind == nkObjDownConv: ri = ri[0]
  let t = typ[i].skipTypes({tyGenericInst, tyAlias, tySink})
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
    result = genArgNoParam(p, ri) #, typ.n[i].sym)
    result.add(".")

proc genPatternCall(p: BProc; ri: PNode; pat: string; typ: PType): Rope =
  var i = 0
  var j = 1
  while i < pat.len:
    case pat[i]
    of '@':
      var first = true
      for k in j..<ri.len:
        let arg = genOtherArg(p, ri, k, typ)
        if arg.len > 0:
          if not first:
            result.add(~", ")
          first = false
          result.add arg
      inc i
    of '#':
      if i+1 < pat.len and pat[i+1] in {'+', '@'}:
        let ri = ri[j]
        if ri.kind in nkCallKinds:
          let typ = skipTypes(ri[0].typ, abstractInst)
          if pat[i+1] == '+': result.add genArgNoParam(p, ri[0])
          result.add(~"(")
          if 1 < ri.len:
            result.add genOtherArg(p, ri, 1, typ)
          for k in j+1..<ri.len:
            result.add(~", ")
            result.add genOtherArg(p, ri, k, typ)
          result.add(~")")
        else:
          localError(p.config, ri.info, "call expression expected for C++ pattern")
        inc i
      elif i+1 < pat.len and pat[i+1] == '.':
        result.add genThisArg(p, ri, j, typ)
        inc i
      elif i+1 < pat.len and pat[i+1] == '[':
        var arg = ri[j].skipAddrDeref
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
        result.add(substr(pat, start, i - 1))

proc genInfixCall(p: BProc, le, ri: PNode, d: var TLoc) =
  var op: TLoc
  initLocExpr(p, ri[0], op)
  # getUniqueType() is too expensive here:
  var typ = skipTypes(ri[0].typ, abstractInst)
  assert(typ.kind == tyProc)
  assert(typ.len == typ.n.len)
  # don't call '$' here for efficiency:
  let pat = ri[0].sym.loc.r.data
  internalAssert p.config, pat.len > 0
  if pat.contains({'#', '(', '@', '\''}):
    var pl = genPatternCall(p, ri, pat, typ)
    # simpler version of 'fixupCall' that works with the pl+params combination:
    var typ = skipTypes(ri[0].typ, abstractInst)
    if typ[0] != nil:
      if p.module.compileToCpp and lfSingleUse in d.flags:
        # do not generate spurious temporaries for C++! For C we're better off
        # with them to prevent undefined behaviour and because the codegen
        # is free to emit expressions multiple times!
        d.k = locCall
        d.setRope pl
        excl d.flags, lfSingleUse
      else:
        if d.k == locNone: getTemp(p, typ[0], d)
        assert(d.t != nil)        # generate an assignment to d:
        var list: TLoc
        initLoc(list, locCall, d.lode, OnUnknown)
        list.setRope pl
        genAssignment(p, d, list, {}) # no need for deep copying
    else:
      pl.add(~";$n")
      line(p, cpsStmts, pl)
  else:
    var pl: Rope = nil
    #var param = typ.n[1].sym
    if 1 < ri.len:
      pl.add(genThisArg(p, ri, 1, typ))
    pl.add(op.r)
    var params: Rope
    for i in 2..<ri.len:
      if params != nil: params.add(~", ")
      assert(typ.len == typ.n.len)
      params.add(genOtherArg(p, ri, i, typ))
    fixupCall(p, le, ri, d, pl, params)

proc genNamedParamCall(p: BProc, ri: PNode, d: var TLoc) =
  # generates a crappy ObjC call
  var op: TLoc
  initLocExpr(p, ri[0], op)
  var pl = ~"["
  # getUniqueType() is too expensive here:
  var typ = skipTypes(ri[0].typ, abstractInst)
  assert(typ.kind == tyProc)
  assert(typ.len == typ.n.len)

  # don't call '$' here for efficiency:
  let pat = ri[0].sym.loc.r.data
  internalAssert p.config, pat.len > 0
  var start = 3
  if ' ' in pat:
    start = 1
    pl.add(op.r)
    if ri.len > 1:
      pl.add(~": ")
      pl.add(genArg(p, ri[1], typ.n[1].sym, ri))
      start = 2
  else:
    if ri.len > 1:
      pl.add(genArg(p, ri[1], typ.n[1].sym, ri))
      pl.add(~" ")
    pl.add(op.r)
    if ri.len > 2:
      pl.add(~": ")
      pl.add(genArg(p, ri[2], typ.n[2].sym, ri))
  for i in start..<ri.len:
    assert(typ.len == typ.n.len)
    if i >= typ.len:
      internalError(p.config, ri.info, "varargs for objective C method?")
    assert(typ.n[i].kind == nkSym)
    var param = typ.n[i].sym
    pl.add(~" ")
    pl.add(param.name.s)
    pl.add(~": ")
    pl.add(genArg(p, ri[i], param, ri))
  if typ[0] != nil:
    if isInvalidReturnType(p.config, typ[0]):
      if ri.len > 1: pl.add(~" ")
      # beware of 'result = p(result)'. We always allocate a temporary:
      if d.k in {locTemp, locNone}:
        # We already got a temp. Great, special case it:
        if d.k == locNone: getTemp(p, typ[0], d, needsInit=true)
        pl.add(~"Result: ")
        pl.add(addrLoc(p.config, d))
        pl.add(~"];$n")
        line(p, cpsStmts, pl)
      else:
        var tmp: TLoc
        getTemp(p, typ[0], tmp, needsInit=true)
        pl.add(addrLoc(p.config, tmp))
        pl.add(~"];$n")
        line(p, cpsStmts, pl)
        genAssignment(p, d, tmp, {}) # no need for deep copying
    else:
      pl.add(~"]")
      if d.k == locNone: getTemp(p, typ[0], d)
      assert(d.t != nil)        # generate an assignment to d:
      var list: TLoc
      initLoc(list, locCall, ri, OnUnknown)
      list.setRope pl
      genAssignment(p, d, list, {}) # no need for deep copying
  else:
    pl.add(~"];$n")
    line(p, cpsStmts, pl)

proc genCall(p: BProc, e: PNode, d: var TLoc) =
  if e[0].typ.skipTypes({tyGenericInst, tyAlias, tySink, tyOwned}).callConv == ccClosure:
    genClosureCall(p, nil, e, d)
  elif e[0].kind == nkSym and sfInfixCall in e[0].sym.flags:
    genInfixCall(p, nil, e, d)
  elif e[0].kind == nkSym and sfNamedParamCall in e[0].sym.flags:
    genNamedParamCall(p, e, d)
  else:
    genPrefixCall(p, nil, e, d)
  postStmtActions(p)

proc genAsgnCall(p: BProc, le, ri: PNode, d: var TLoc) =
  if ri[0].typ.skipTypes({tyGenericInst, tyAlias, tySink, tyOwned}).callConv == ccClosure:
    genClosureCall(p, le, ri, d)
  elif ri[0].kind == nkSym and sfInfixCall in ri[0].sym.flags:
    genInfixCall(p, le, ri, d)
  elif ri[0].kind == nkSym and sfNamedParamCall in ri[0].sym.flags:
    genNamedParamCall(p, ri, d)
  else:
    genPrefixCall(p, le, ri, d)
  postStmtActions(p)
