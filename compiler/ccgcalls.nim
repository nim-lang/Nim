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

proc canRaiseDisp(p: BProc; n: AnyNode): bool =
  # we assume things like sysFatal cannot raise themselves
  # 5 = "decided here, neither predicate ran". Without resetting, the marker
  # keeps whatever the PREVIOUS call left in it and the early return below
  # attributes this answer to a branch that did not execute — which is how the
  # first run of this differential came to claim effect-list coverage it did
  # not have.
  markCanRaiseBranch 5
  if n.kind == nkSym and {sfNeverRaises, sfImportc, sfCompilerProc} * n.sym.flags != {}:
    result = false
  elif optPanics in p.config.globalOptions or
      (n.kind == nkSym and sfSystemModule in getModule(n.sym).flags and
       sfSystemRaisesDefect notin n.sym.flags):
    # we know we can be strict:
    result = canRaise(n)
  else:
    # we have to be *very* conservative:
    result = canRaiseConservative(n)
  when defined(icCanRaiseLog):
    # `canRaise` reads the raises spec off `fn.typ.n`, and under `--ic:on` that
    # node came back from a `.bif`. Whether it came back INTACT is not something
    # the `BNode`/`PNode` grinder can answer — both spellings ask the same
    # `PType` and so agree however wrong it is. The only oracle is the same
    # program built without IC. Log the verdict per callee; the two builds must
    # produce the same one.
    if n.kind == nkSym:
      logCanRaise(n.sym, result)

proc preventNrvo(p: BProc; dest, le: PNode; ri: AnyNode): bool =
  ## `dest` and `le` stay `PNode`s: they are DESTINATIONS, which the whole call
  ## family keeps as `PNode`s so they can be nil and so they can be handed to
  ## the alias analysis, and it is also what keeps the `warnObservableStores`
  ## message able to RENDER `le` — rendering being a capability the cursor seam
  ## does not have at all. `ri`, the call being generated, is a cursor.
  proc locationEscapes(p: BProc; le: PNode; inTryStmt: bool): bool =
    result = false
    var n = le
    while true:
      # do NOT follow nkHiddenDeref here!
      case n.kind
      of nkSym:
        # we don't own the location so it escapes:
        if n.sym.owner != p.prc:
          return true
        elif inTryStmt and sfUsedInFinallyOrExcept in n.sym.flags:
          # it is also an observable store if the location is used
          # in 'except' or 'finally'
          return true
        return false
      of nkDotExpr, nkBracketExpr, nkObjUpConv, nkObjDownConv,
          nkCheckedFieldExpr:
        n = n.firstSon
      of nkHiddenStdConv, nkHiddenSubConv, nkConv:
        n = n.secondSon
      else:
        # cannot analyse the location; assume the worst
        return true

  result = false
  if le != nil:
    for r in sonsFrom(ri, 1):
      # `isPartOf` compares field symbols by identity and so has not moved to
      # the seam; `origin` hands it the same nodes it always compared.
      if isPartOf(le, origin(r), {pfStructural}) != arNo: return true
    # we use the weaker 'canRaise' here in order to prevent too many
    # annoying warnings, see #14514
    if canRaise(ri.firstSon) and
        locationEscapes(p, le, p.nestedTryStmts.len > 0):
      message(p.config, le.info, warnObservableStores, $le)
  # bug #19613 prevent dangerous aliasing too:
  if dest != nil and dest != le:
    for r in sonsFrom(ri, 1):
      if isPartOf(dest, origin(r), {pfStructural}) != arNo: return true

proc hasNoInit(call: AnyNode): bool {.inline.} =
  result = call.firstSon.kind == nkSym and sfNoInit in call.firstSon.sym.flags

proc isHarmlessStore(p: BProc; canRaise: bool; d: TLoc): bool =
  if d.k in {locTemp, locNone} or not canRaise:
    result = true
  elif d.k == locLocalVar and p.withinTryWithExcept == 0:
    # we cannot observe a store to a local variable if the current proc
    # has no error handler:
    result = true
  else:
    result = false

proc cleanupTemp(p: BProc; returnType: PType, tmp: TLoc): bool =
  if returnType.kind in {tyVar, tyLent}:
    # we don't need to worry about var/lent return types
    result = false
  elif hasDestructor(returnType) and getAttachedOp(p.module.g.graph, returnType, attachedDestructor) != nil:
    let dtor = getAttachedOp(p.module.g.graph, returnType, attachedDestructor)
    var op = initLocExpr(p, newSymNode(dtor))
    var callee = rdLoc(op)
    let destroyArg =
      if dtor.typ.firstParamType.kind == tyVar:
        cAddr(rdLoc(tmp))
      else:
        rdLoc(tmp)
    let destroy = cCall(callee, destroyArg)
    raiseExitCleanup(p, destroy)
    result = true
  else:
    result = false

# `le` — the assignment DESTINATION — stays a `PNode` throughout this family.
# It is nilable (`genCall` passes nil, and a cursor has no standalone nil), and
# it is what `preventNrvo` and `isPartOf` are handed, both of which are still
# `PNode`-typed. `ri`, the expression being generated, is the part that moves.
proc fixupCall(p: BProc, le: PNode, ri: AnyNode, d: var TLoc,
               result: var Builder, call: var CallBuilder) =
  let canRaise = p.config.exc == excGoto and canRaiseDisp(p, ri.firstSon)
  genLineDir(p, ri)
  # getUniqueType() is too expensive here:
  var typ = skipTypes(ri.firstSon.typ, abstractInst)
  if typ.returnType != nil:
    var flags: TAssignmentFlags = {}
    if typ.returnType.kind in {tyOpenArray, tyVarargs}:
      # perhaps generate no temp if the call doesn't have side effects
      flags.incl needTempForOpenArray
    if isInvalidReturnType(p.config, typ):
      # beware of 'result = p(result)'. We may need to allocate a temporary:
      if d.k in {locTemp, locNone} or not preventNrvo(p, d.lode, le, ri):
        # Great, we can use 'd':
        if d.k == locNone: d = getTemp(p, typ.returnType, needsInit=true)
        elif d.k notin {locTemp} and not hasNoInit(ri):
          # reset before pass as 'result' var:
          discard "resetLoc(p, d)"
        let rad = addrLoc(p.config, d)
        result.addArgument(call):
          result.add(rad)
        result.finishCallBuilder(call)
        p.s(cpsStmts).addStmt():
          p.s(cpsStmts).add(extract(result))
      else:
        var tmp: TLoc = getTemp(p, typ.returnType, needsInit=true)
        let ratmp = addrLoc(p.config, tmp)
        result.addArgument(call):
          result.add(ratmp)
        result.finishCallBuilder(call)
        p.s(cpsStmts).addStmt():
          p.s(cpsStmts).add(extract(result))
        genAssignment(p, d, tmp, {}) # no need for deep copying
      if canRaise: raiseExit(p)
    else:
      result.finishCallBuilder(call)
      if p.module.compileToCpp:
        if lfSingleUse in d.flags:
          # do not generate spurious temporaries for C++! For C we're better off
          # with them to prevent undefined behaviour and because the codegen
          # is free to emit expressions multiple times!
          d.k = locCall
          d.snippet = extract(result)
          excl d.flags, lfSingleUse
        else:
          if d.k == locNone and p.splitDecls == 0 and p.config.exc != excGoto:
            d = getTempCpp(p, typ.returnType, extract(result))
          else:
            if d.k == locNone: d = getTemp(p, typ.returnType)
            var list = initLoc(locCall, d.lode, OnUnknown)
            list.snippet = extract(result)
            genAssignment(p, d, list, {needAssignCall}) # no need for deep copying
            if canRaise: raiseExit(p)

      elif isHarmlessStore(p, canRaise, d):
        var useTemp = false
        if d.k == locNone:
          useTemp = true
          d = getTemp(p, typ.returnType)
        assert(d.t != nil)        # generate an assignment to d:
        var list = initLoc(locCall, d.lode, OnUnknown)
        list.snippet = extract(result)
        genAssignment(p, d, list, flags+{needAssignCall}) # no need for deep copying
        if canRaise:
          if not (useTemp and cleanupTemp(p, typ.returnType, d)):
            raiseExit(p)
      else:
        var tmp: TLoc = getTemp(p, typ.returnType, needsInit=true)
        var list = initLoc(locCall, d.lode, OnUnknown)
        list.snippet = extract(result)
        genAssignment(p, tmp, list, flags+{needAssignCall}) # no need for deep copying
        if canRaise:
          if not cleanupTemp(p, typ.returnType, tmp):
            raiseExit(p)
        genAssignment(p, d, tmp, {})
  else:
    finishCallBuilder(result, call)
    p.s(cpsStmts).addStmt():
      p.s(cpsStmts).add(extract(result))
    if canRaise: raiseExit(p)

proc genBoundsCheck(p: BProc; arr, a, b: TLoc; arrTyp: PType)

proc reifiedOpenArray(n: AnyNode): bool {.inline.} =
  var x = n
  while true:
    case x.kind
    of {nkAddr, nkHiddenAddr, nkHiddenDeref}:
      x = x.firstSon
    of nkHiddenStdConv:
      x = x.secondSon
    else:
      break
  if x.kind == nkSym and x.sym.kind == skParam:
    result = false
  else:
    result = true

proc genOpenArraySlice(p: BProc; q: AnyNode; formalType, destType: PType; prepareForMutation = false): (Rope, Rope) =
  var a = initLocExpr(p, q.secondSon)
  var b = initLocExpr(p, son(q, 2))
  var c = initLocExpr(p, son(q, 3))
  # bug #23321: In the function mapType, ptrs (tyPtr, tyVar, tyLent, tyRef)
  # are mapped into ctPtrToArray, the dereference of which is skipped
  # in the `genDeref`. We need to skip these ptrs here
  let ty = skipTypes(a.t, abstractVar+{tyPtr, tyRef})
  # but first produce the required index checks:
  if optBoundsCheck in p.options:
    genBoundsCheck(p, a, b, c, ty)
  if prepareForMutation:
    let bra = byRefLoc(p, a)
    p.s(cpsStmts).addCallStmt(cgsymValue(p.module, "nimPrepareStrMutationV2"),
      bra)
  let dest = getTypeDesc(p.module, destType)
  let ra = rdLoc(a)
  let rb = rdLoc(b)
  let rc = rdLoc(c)
  let lengthExpr = cOp(Add, NimInt, cOp(Sub, NimInt, rc, rb), cIntValue(1))
  case ty.kind
  of tyArray:
    let first = toInt64(firstOrd(p.config, ty))
    if first == 0:
      result = (cCast(ptrType(dest), cOp(Add, NimInt, ra, rb)), lengthExpr)
    else:
      let lit = cIntLiteral(first)
      result = (cCast(ptrType(dest), cOp(Add, NimInt, ra, cOp(Sub, NimInt, rb, lit))), lengthExpr)
  of tyOpenArray, tyVarargs:
    let data = if reifiedOpenArray(q.secondSon): dotField(ra, "Field0") else: ra
    result = (cCast(ptrType(dest), cOp(Add, NimInt, data, rb)), lengthExpr)
  of tyUncheckedArray, tyCstring:
    result = (cCast(ptrType(dest), cOp(Add, NimInt, ra, rb)), lengthExpr)
  of tyString, tySequence:
    let atyp = skipTypes(a.t, abstractInst)
    if formalType.skipTypes(abstractInst).kind in {tyVar} and atyp.kind == tyString and
        optSeqDestructors in p.config.globalOptions and not p.config.usesSso():
      let bra = byRefLoc(p, a)
      p.s(cpsStmts).addCallStmt(cgsymValue(p.module, "nimPrepareStrMutationV2"),
        bra)
    if p.config.usesSso() and
        skipTypes(a.t, abstractVar + abstractInst).kind == tyString:
      let strPtr = if atyp.kind in {tyVar} and not compileToCpp(p.module): ra
                   else: addrLoc(p.config, a)
      result = (
        cCast(ptrType(dest), cOp(Add, NimInt,
          cCall(cgsymValue(p.module, "nimStrData"), strPtr), rb)),
        lengthExpr)
    else:
      var val: Snippet
      if atyp.kind in {tyVar} and not compileToCpp(p.module):
        val = cDeref(ra)
      else:
        val = ra
      result = (
        cIfExpr(dataFieldAccessor(p, val),
          cCast(ptrType(dest), cOp(Add, NimInt, dataField(p, val), rb)),
          NimNil),
        lengthExpr)
  else:
    result = ("", "")
    internalError(p.config, "openArrayLoc: " & typeToString(a.t))

proc openArrayLoc(p: BProc, formalType: PType, n: AnyNode; result: var Builder) =
  var q = skipConv(n)
  var skipped = false
  while q.kind == nkStmtListExpr and q.hasSons:
    skipped = true
    q = q.lastSon
  if getMagic(q) == mSlice:
    # magic: pass slice to openArray:
    if skipped:
      q = skipConv(n)
      while q.kind == nkStmtListExpr and q.hasSons:
        for it in sonsButLast(q):
          genStmts(p, it)
        q = q.lastSon
    let (x, y) = genOpenArraySlice(p, q, formalType, n.typ.elementType)
    result.add(x)
    result.addArgumentSeparator()
    result.add(y)
  else:
    var a = initLocExpr(p, if n.kind == nkHiddenStdConv: n.secondSon else: n)
    case skipTypes(a.t, abstractVar+{tyStatic}).kind
    of tyOpenArray, tyVarargs:
      let ra = rdLoc(a)
      if reifiedOpenArray(n):
        if a.t.kind in {tyVar, tyLent}:
          result.add(derefField(ra, "Field0"))
          result.addArgumentSeparator()
          result.add(derefField(ra, "Field1"))
        else:
          result.add(dotField(ra, "Field0"))
          result.addArgumentSeparator()
          result.add(dotField(ra, "Field1"))
      else:
        result.add(ra)
        result.addArgumentSeparator()
        result.add(ra & "Len_0")
    of tyString, tySequence:
      let ntyp = skipTypes(n.typ, abstractInst)
      if formalType.skipTypes(abstractInst).kind in {tyVar} and ntyp.kind == tyString and
          optSeqDestructors in p.config.globalOptions and not p.config.usesSso():
        let bra = byRefLoc(p, a)
        p.s(cpsStmts).addCallStmt(cgsymValue(p.module, "nimPrepareStrMutationV2"),
          bra)
      if p.config.usesSso() and
          skipTypes(n.typ, abstractVar + abstractInst).kind == tyString:
        if ntyp.kind in {tyVar} and not compileToCpp(p.module):
          let ra = a.rdLoc
          result.add(cCall(cgsymValue(p.module, "nimStrData"), ra))
          result.addArgumentSeparator()
          result.add(cCall(cgsymValue(p.module, "nimStrLen"), cDeref(ra)))
        else:
          result.add(cCall(cgsymValue(p.module, "nimStrData"), addrLoc(p.config, a)))
          result.addArgumentSeparator()
          result.add(lenExpr(p, a))
      elif ntyp.kind in {tyVar} and not compileToCpp(p.module):
        let ra = a.rdLoc
        var t = TLoc(snippet: cDeref(ra))
        let lt = lenExpr(p, t)
        result.add(cIfExpr(dataFieldAccessor(p, t.snippet), dataField(p, t.snippet), NimNil))
        result.addArgumentSeparator()
        result.add(lt)
      else:
        let ra = a.rdLoc
        let la = lenExpr(p, a)
        result.add(cIfExpr(dataFieldAccessor(p, ra), dataField(p, ra), NimNil))
        result.addArgumentSeparator()
        result.add(la)
    of tyArray:
      let ra = rdLoc(a)
      result.add(ra)
      result.addArgumentSeparator()
      result.addIntValue(lengthOrd(p.config, a.t))
    of tyPtr, tyRef:
      case elementType(a.t).kind
      of tyString, tySequence:
        let ra = a.rdLoc
        var t = TLoc(snippet: cDeref(ra))
        let lt = lenExpr(p, t)
        if p.config.usesSso():
          result.add(cCall(cgsymValue(p.module, "nimStrData"), ra))
          result.addArgumentSeparator()
          result.add(cCall(cgsymValue(p.module, "nimStrLen"), t.snippet))
        else:
          result.add(cIfExpr(dataFieldAccessor(p, t.snippet), dataField(p, t.snippet), NimNil))
          result.addArgumentSeparator()
          result.add(lt)
      of tyArray:
        let ra = rdLoc(a)
        result.add(ra)
        result.addArgumentSeparator()
        result.addIntValue(lengthOrd(p.config, elementType(a.t)))
      else:
        internalError(p.config, "openArrayLoc: " & typeToString(a.t))
    else: internalError(p.config, "openArrayLoc: " & typeToString(a.t))

proc withTmpIfNeeded(p: BProc, a: TLoc, needsTmp: bool): TLoc =
  # Bug https://github.com/status-im/nimbus-eth2/issues/1549
  # Aliasing is preferred over stack overflows.
  # Also don't regress for non ARC-builds, too risky.
  if needsTmp and a.lode.typ != nil and p.config.selectedGC in {gcArc, gcAtomicArc, gcOrc, gcYrc} and
      getSize(p.config, a.lode.typ) < 1024:
    result = getTemp(p, a.lode.typ, needsInit=false)
    genAssignment(p, result, a, {})
  else:
    result = a

proc expressionsNeedsTmp(p: BProc, a: TLoc): TLoc =
  result = getTemp(p, a.lode.typ, needsInit=false)
  genAssignment(p, result, a, {})

proc genArgStringToCString(p: BProc, n: AnyNode; result: var Builder; needsTmp: bool) {.inline.} =
  var a = initLocExpr(p, n.firstSon)
  let tmp = withTmpIfNeeded(p, a, needsTmp)
  let ra = if p.config.usesSso(): byRefLoc(p, tmp) else: tmp.rdLoc
  result.addCall(cgsymValue(p.module, "nimToCStringConv"), ra)

proc genArg(p: BProc, n: AnyNode, param: PSym; call: AnyNode; result: var Builder; needsTmp = false) =
  var a: TLoc
  if n.kind == nkStringToCString:
    genArgStringToCString(p, n, result, needsTmp)
  elif skipTypes(param.typ, abstractVar).kind in {tyOpenArray, tyVarargs}:
    var n = if n.kind != nkHiddenAddr: n else: n.firstSon
    openArrayLoc(p, param.typ, n, result)
  elif ccgIntroducedPtr(p.config, param, call.firstSon.typ.returnType) and
    (optByRef notin param.options or not p.module.compileToCpp):
    a = initLocExpr(p, n)
    if n.kind in {nkCharLit..nkNilLit}:
      addAddrLoc(p.config, expressionsNeedsTmp(p, a), result)
    else:
      addAddrLoc(p.config, withTmpIfNeeded(p, a, needsTmp), result)
  elif p.module.compileToCpp and param.typ.kind in {tyVar} and
      n.kind == nkHiddenAddr:
    # bug #23748: we need to introduce a temporary here. The expression type
    # will be a reference in C++ and we cannot create a temporary reference
    # variable. Thus, we create a temporary pointer variable instead.
    let needsIndirect = mapType(p.config, n.firstSon.typ, mapTypeChooser(n.firstSon) == skParam) != ctArray
    # A REWRITE, and one that has to be followed. The node's type is replaced in
    # place, and a cursor would keep reading the type slot as it was ENCODED —
    # the buffer does not see the mutation. So from here this site works on the
    # origin, which is the node being mutated and therefore the one that has the
    # new type.
    let nn = origin(n)
    if needsIndirect:
      nn.typ = copyType(nn.typ, p.module.idgen, nn.typ.owner)
      nn.typ.incl tfVarIsPtr
    a = initLocExprSingleUse(p, nn)
    a = withTmpIfNeeded(p, a, needsTmp)
    if needsIndirect: a.flags.incl lfIndirect
    # if the proc is 'importc'ed but not 'importcpp'ed then 'var T' still
    # means '*T'. See posix.nim for lots of examples that do that in the wild.
    let callee = call.firstSon
    if callee.kind == nkSym and
        {sfImportc, sfInfixCall, sfCompilerProc} * callee.sym.flags == {sfImportc} and
        {lfHeader, lfNoDecl} * callee.sym.loc.flags != {} and
        needsIndirect:
      addAddrLoc(p.config, a, result)
    else:
      addRdLoc(a, result)
  else:
    a = initLocExprSingleUse(p, n)
    if param.typ.kind in {tyVar, tyPtr, tyRef, tySink}:
      let typ = skipTypes(param.typ, abstractPtrs)
      if not sameBackendTypePickyAliases(typ, n.typ.skipTypes(abstractPtrs)):
        a.snippet = cCast(getTypeDesc(p.module, param.typ), rdCharLoc(a))
    addRdLoc(withTmpIfNeeded(p, a, needsTmp), result)
  #assert result != nil

proc genArgNoParam(p: BProc, n: AnyNode; result: var Builder; needsTmp = false) =
  var a: TLoc
  if n.kind == nkStringToCString:
    genArgStringToCString(p, n, result, needsTmp)
  else:
    a = initLocExprSingleUse(p, n)
    addRdLoc(withTmpIfNeeded(p, a, needsTmp), result)

import aliasanalysis

proc potentialAlias(n: AnyNode, potentialWrites: seq[PNode]): bool =
  result = false
  for p in potentialWrites:
    if p.aliases(n) != no or n.aliases(p) != no:
      return true

proc skipTrivialIndirections[T: AnyNode](n: T): T =
  ## Explicitly generic rather than `(n: AnyNode): AnyNode`: two occurrences of
  ## a type class in one signature are two INDEPENDENT parameters, so that
  ## spelling would let the result type drift from the argument's.
  result = n
  while true:
    case result.kind
    of nkDerefExpr, nkHiddenDeref, nkAddr, nkHiddenAddr, nkObjDownConv, nkObjUpConv:
      result = result.firstSon
    of nkHiddenStdConv, nkHiddenSubConv:
      result = result.secondSon
    else: break

proc getPotentialReads(n: AnyNode; result: var seq[PNode]) =
  case n.kind:
  of nkLiterals, nkIdent, nkFormalParams: discard
  of nkSym: result.add n
  else:
    for s in sons(n):
      getPotentialReads(s, result)

proc genParams(p: BProc, ri: AnyNode, typ: PType; result: var Builder, argBuilder: var CallBuilder) =
  # We must generate temporaries in cases like #14396
  # to keep the strict Left-To-Right evaluation
  # The arguments are walked BACKWARDS below, which a `Cursor` cannot do and
  # which costs a re-walk per step even on a `PNode`. Materialize them in one
  # forward pass and index that; `needTmp` already allocates per call, so this
  # is the same order of work.
  #
  # The arguments are materialized as `PNode`s, not cursors, because the alias
  # analysis below (`potentialAlias`, `getPotentialReads`) carries a
  # `seq[PNode]` beside the node and has not moved to the seam — see the
  # mixed-representation blocker in `bnode`'s module doc. `origin` gives the
  # same objects the tree-driven build used, so this is the argument list it
  # always was; when that analysis moves, this becomes `seq[AnyNode]`.
  var args: seq[PNode] = @[]
  for it in sonsFrom(ri, 1): args.add origin(it)
  var needTmp = newSeq[bool](args.len)
  var potentialWrites: seq[PNode] = @[]
  for i in countdown(args.high, 0):
    if args[i].skipTrivialIndirections.kind == nkSym:
      needTmp[i] = potentialAlias(args[i], potentialWrites)
    else:
      #if not args[i].typ.isCompileTimeOnly:
      var potentialReads: seq[PNode] = @[]
      getPotentialReads(args[i], potentialReads)
      for n in potentialReads:
        if not needTmp[i]:
          needTmp[i] = potentialAlias(n, potentialWrites)
      getPotentialWrites(args[i], false, potentialWrites)
    when false:
      # this optimization is wrong, see bug #23748
      if args[i].kind in {nkHiddenAddr, nkAddr}:
        # Optimization: don't use a temp, if we would only take the address anyway
        needTmp[i] = false

  for i, it in isons(ri, 1):
    if i < typ.n.len:
      assert(son(typ.n, i).kind == nkSym)
      let paramType = son(typ.n, i)
      if not paramType.typ.isCompileTimeOnly:
        var arg = newBuilder("")
        genArg(p, it, paramType.sym, ri, arg, needTmp[i-1])
        if arg.buf.len != 0:
          result.addArgument(argBuilder):
            result.add(extract(arg))
    else:
      var arg = newBuilder("")
      genArgNoParam(p, it, arg, needTmp[i-1])
      if arg.buf.len != 0:
        result.addArgument(argBuilder):
          result.add(extract(arg))

proc addActualSuffixForHCR(res: var Rope, module: PSym, sym: PSym) =
  if sym.flags * {sfImportc, sfNonReloadable} == {} and sym.loc.k == locProc and
      (sym.typ.callConv == ccInline or sym.owner.id == module.id):
    res = res & "_actual".rope

proc genPrefixCall(p: BProc, le: PNode, ri: AnyNode, d: var TLoc) =
  # this is a hotspot in the compiler
  var op = initLocExpr(p, ri.firstSon)
  # getUniqueType() is too expensive here:
  var typ = skipTypes(ri.firstSon.typ, abstractInstOwned)
  assert(typ.kind == tyProc)

  var callee = rdLoc(op)
  if p.hcrOn and ri.firstSon.kind == nkSym:
    callee.addActualSuffixForHCR(p.module.module, ri.firstSon.sym)

  var res = newBuilder("")
  var call = initCallBuilder(res, callee)
  genParams(p, ri, typ, res, call)
  fixupCall(p, le, ri, d, res, call)

proc genClosureCall(p: BProc, le: PNode, ri: AnyNode, d: var TLoc) =

  template callProc(rp, params, pTyp: Snippet): Snippet =
    let e = dotField(rp, "ClE_0")
    let p = dotField(rp, "ClP_0")
    let eCall =
      # note `params` here is actually multiple params
      if params.len == 0:
        cCall(p, e)
      else:
        cCall(p, params, e)
    cIfExpr(e,
      eCall,
      cCall(cCast(pTyp, p), params))

  template callIter(rp, params: Snippet): Snippet =
    # we know the env exists
    let e = dotField(rp, "ClE_0")
    let p = dotField(rp, "ClP_0")
    # note `params` here is actually multiple params
    if params.len == 0:
      cCall(p, e)
    else:
      cCall(p, params, e)

  var op = initLocExpr(p, ri.firstSon)

  # getUniqueType() is too expensive here:
  var typ = skipTypes(ri.firstSon.typ, abstractInstOwned)
  assert(typ.kind == tyProc)

  var params = newBuilder("")
  var argBuilder = default(CallBuilder) # not initCallBuilder, we just want the params
  genParams(p, ri, typ, params, argBuilder)

  # `rawProc` is bound BEFORE the `{.dirty.}` template that uses it. Inside a
  # generic proc a dirty template's identifiers resolve at instantiation, and a
  # local declared after the template loses to the module-level `rawProc` proc
  # — which type-checks as a completely different thing.
  let rawProc = getClosureType(p.module, typ, clHalf)

  template genCallPattern {.dirty.} =
    let rp = rdLoc(op)
    let pars = extract(params)
    p.s(cpsStmts).addStmt():
      if tfIterator in typ.flags:
        p.s(cpsStmts).add(callIter(rp, pars))
      else:
        p.s(cpsStmts).add(callProc(rp, pars, rawProc))
  let canRaise = p.config.exc == excGoto and canRaiseDisp(p, ri.firstSon)
  if typ.returnType != nil:
    if isInvalidReturnType(p.config, typ):
      # beware of 'result = p(result)'. We may need to allocate a temporary:
      if d.k in {locTemp, locNone} or not preventNrvo(p, d.lode, le, ri):
        # Great, we can use 'd':
        if d.k == locNone:
          d = getTemp(p, typ.returnType, needsInit=true)
        elif d.k notin {locTemp} and not hasNoInit(ri):
          # reset before pass as 'result' var:
          discard "resetLoc(p, d)"
        params.addArgument(argBuilder):
          params.add(addrLoc(p.config, d))
        genCallPattern()
        if canRaise: raiseExit(p)
      else:
        var tmp: TLoc = getTemp(p, typ.returnType, needsInit=true)
        params.addArgument(argBuilder):
          params.add(addrLoc(p.config, tmp))
        genCallPattern()
        if canRaise: raiseExit(p)
        genAssignment(p, d, tmp, {}) # no need for deep copying
    elif isHarmlessStore(p, canRaise, d):
      if d.k == locNone: d = getTemp(p, typ.returnType)
      assert(d.t != nil)        # generate an assignment to d:
      var list: TLoc = initLoc(locCall, d.lode, OnUnknown)
      let rp = rdLoc(op)
      let pars = extract(params)
      if tfIterator in typ.flags:
        list.snippet = callIter(rp, pars)
      else:
        list.snippet = callProc(rp, pars, rawProc)
      genAssignment(p, d, list, {}) # no need for deep copying
      if canRaise: raiseExit(p)
    else:
      var tmp: TLoc = getTemp(p, typ.returnType)
      assert(d.t != nil)        # generate an assignment to d:
      var list: TLoc = initLoc(locCall, d.lode, OnUnknown)
      let rp = rdLoc(op)
      let pars = extract(params)
      if tfIterator in typ.flags:
        list.snippet = callIter(rp, pars)
      else:
        list.snippet = callProc(rp, pars, rawProc)
      genAssignment(p, tmp, list, {})
      if canRaise: raiseExit(p)
      genAssignment(p, d, tmp, {})
  else:
    genCallPattern()
    if canRaise: raiseExit(p)

proc genOtherArg(p: BProc; ri: AnyNode; i: int; typ: PType; result: var Builder;
                 argBuilder: var CallBuilder) =
  if i < typ.n.len:
    # 'var T' is 'T&' in C++. This means we ignore the request of
    # any nkHiddenAddr when it's a 'var T'.
    let paramType = son(typ.n, i)
    assert(paramType.kind == nkSym)
    if paramType.typ.isCompileTimeOnly:
      discard
    elif paramType.typ.kind in {tyVar} and son(ri, i).kind == nkHiddenAddr:
      result.addArgument(argBuilder):
        genArgNoParam(p, son(ri, i).firstSon, result)
    else:
      result.addArgument(argBuilder):
        genArgNoParam(p, son(ri, i), result) #, son(typ.n, i).sym)
  else:
    if tfVarargs notin typ.flags:
      localError(p.config, ri.info, "wrong argument count")
    else:
      result.addArgument(argBuilder):
        genArgNoParam(p, son(ri, i), result)

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

proc skipAddrDeref[T: AnyNode](node: T): T =
  var n = node
  var isAddr = false
  case n.kind
  of nkAddr, nkHiddenAddr:
    n = n.firstSon
    isAddr = true
  of nkDerefExpr, nkHiddenDeref:
    n = n.firstSon
  else: return n
  if n.kind == nkObjDownConv: n = n.firstSon
  if isAddr and n.kind in {nkDerefExpr, nkHiddenDeref}:
    result = n.firstSon
  elif n.kind in {nkAddr, nkHiddenAddr}:
    result = n.firstSon
  else:
    result = node

proc genThisArg(p: BProc; ri: AnyNode; i: int; typ: PType; result: var Builder) =
  # for better or worse c2nim translates the 'this' argument to a 'var T'.
  # However manual wrappers may also use 'ptr T'. In any case we support both
  # for convenience.
  internalAssert p.config, i < typ.n.len
  assert(son(typ.n, i).kind == nkSym)
  # if the parameter is lying (tyVar) and thus we required an additional deref,
  # skip the deref:
  var ri = son(ri, i)
  while ri.kind == nkObjDownConv: ri = ri.firstSon
  let t = typ[i].skipTypes({tyGenericInst, tyAlias, tySink})
  if t.kind in {tyVar}:
    let x = if ri.kind == nkHiddenAddr: ri.firstSon else: ri
    if x.typ.kind == tyPtr:
      genArgNoParam(p, x, result)
      result.add("->")
    elif x.kind in {nkHiddenDeref, nkDerefExpr} and x.firstSon.typ.kind == tyPtr:
      genArgNoParam(p, x.firstSon, result)
      result.add("->")
    else:
      genArgNoParam(p, x, result)
      result.add(".")
  elif t.kind == tyPtr:
    if ri.kind in {nkAddr, nkHiddenAddr}:
      genArgNoParam(p, ri.firstSon, result)
      result.add(".")
    else:
      genArgNoParam(p, ri, result)
      result.add("->")
  else:
    ri = skipAddrDeref(ri)
    if ri.kind in {nkAddr, nkHiddenAddr}: ri = ri.firstSon
    genArgNoParam(p, ri, result) #, son(typ.n, i).sym)
    result.add(".")

proc genPatternCall(p: BProc; ri: AnyNode; pat: string; typ: PType; result: var Builder) =
  var i = 0
  var j = 1
  while i < pat.len:
    case pat[i]
    of '@':
      var callBuilder = default(CallBuilder) # not init call builder
      for k, _ in isons(ri, j):
        genOtherArg(p, ri, k, typ, result, callBuilder)
      inc i
    of '#':
      if i+1 < pat.len and pat[i+1] in {'+', '@'}:
        let ri = son(ri, j)
        if ri.kind in nkCallKinds:
          let typ = skipTypes(ri.firstSon.typ, abstractInst)
          if pat[i+1] == '+': genArgNoParam(p, ri.firstSon, result)
          result.add("(")
          if 1 < ri.len:
            var callBuilder: CallBuilder = default(CallBuilder)
            genOtherArg(p, ri, 1, typ, result, callBuilder)
          for k, _ in isons(ri, j+1):
            var callBuilder: CallBuilder = default(CallBuilder)
            genOtherArg(p, ri, k, typ, result, callBuilder)
          result.add(")")
        else:
          localError(p.config, ri.info, "call expression expected for C++ pattern")
        inc i
      elif i+1 < pat.len and pat[i+1] == '.':
        genThisArg(p, ri, j, typ, result)
        inc i
      elif i+1 < pat.len and pat[i+1] == '[':
        var arg = son(ri, j).skipAddrDeref
        while arg.kind in {nkAddr, nkHiddenAddr, nkObjDownConv}: arg = arg.firstSon
        genArgNoParam(p, arg, result)
        #result.add debugTree(arg, 0, 10)
      else:
        var callBuilder = default(CallBuilder) # not init call builder
        genOtherArg(p, ri, j, typ, result, callBuilder)
      inc j
      inc i
    of '\'':
      var idx, stars: int = 0
      if scanCppGenericSlot(pat, i, idx, stars):
        var t = resolveStarsInCppType(typ, idx, stars)
        if t == nil: result.add(CVoid)
        else: result.add(getTypeDesc(p.module, t))
    else:
      let start = i
      while i < pat.len:
        if pat[i] notin {'@', '#', '\''}: inc(i)
        else: break
      if i - 1 >= start:
        result.add(substr(pat, start, i - 1))

proc genInfixCall(p: BProc, le: PNode, ri: AnyNode, d: var TLoc) =
  var op = initLocExpr(p, ri.firstSon)
  # getUniqueType() is too expensive here:
  var typ = skipTypes(ri.firstSon.typ, abstractInst)
  assert(typ.kind == tyProc)
  # don't call '$' here for efficiency:
  let pat = $ri.firstSon.sym.loc.snippet
  internalAssert p.config, pat.len > 0
  if pat.contains({'#', '(', '@', '\''}):
    var pl = newBuilder("")
    genPatternCall(p, ri, pat, typ, pl)
    # simpler version of 'fixupCall' that works with the pl+params combination:
    var typ = skipTypes(ri.firstSon.typ, abstractInst)
    if typ.returnType != nil:
      if p.module.compileToCpp and lfSingleUse in d.flags:
        # do not generate spurious temporaries for C++! For C we're better off
        # with them to prevent undefined behaviour and because the codegen
        # is free to emit expressions multiple times!
        d.k = locCall
        d.snippet = extract(pl)
        excl d.flags, lfSingleUse
      else:
        if d.k == locNone: d = getTemp(p, typ.returnType)
        assert(d.t != nil)        # generate an assignment to d:
        var list: TLoc = initLoc(locCall, d.lode, OnUnknown)
        list.snippet = extract(pl)
        genAssignment(p, d, list, {}) # no need for deep copying
    else:
      p.s(cpsStmts).addStmt():
        p.s(cpsStmts).add(extract(pl))
  else:
    var pl = newBuilder("")
    if 1 < ri.len:
      genThisArg(p, ri, 1, typ, pl)
    pl.add(op.snippet)
    var res = newBuilder("")
    var call = initCallBuilder(res, extract(pl))
    for i, _ in isons(ri, 2):
      genOtherArg(p, ri, i, typ, res, call)
    fixupCall(p, le, ri, d, res, call)

proc genNamedParamCall(p: BProc, ri: AnyNode, d: var TLoc) =
  # generates a crappy ObjC call
  var op = initLocExpr(p, ri.firstSon)
  var pl = newBuilder("[")
  # getUniqueType() is too expensive here:
  var typ = skipTypes(ri.firstSon.typ, abstractInst)
  assert(typ.kind == tyProc)

  # don't call '$' here for efficiency:
  let pat = $ri.firstSon.sym.loc.snippet
  internalAssert p.config, pat.len > 0
  var start = 3
  if ' ' in pat:
    start = 1
    pl.add(op.snippet)
    if ri.len > 1:
      pl.add(": ")
      genArg(p, ri.secondSon, typ.n.secondSon.sym, ri, pl)
      start = 2
  else:
    if ri.len > 1:
      genArg(p, ri.secondSon, typ.n.secondSon.sym, ri, pl)
      pl.add(" ")
    pl.add(op.snippet)
    if ri.len > 2:
      pl.add(": ")
      genArg(p, son(ri, 2), son(typ.n, 2).sym, ri, pl)
  for i, it in isons(ri, start):
    if i >= typ.n.len:
      internalError(p.config, ri.info, "varargs for objective C method?")
    assert(son(typ.n, i).kind == nkSym)
    var param = son(typ.n, i).sym
    pl.add(" ")
    pl.add(param.name.s)
    pl.add(": ")
    genArg(p, it, param, ri, pl)
  if typ.returnType != nil:
    if isInvalidReturnType(p.config, typ):
      if ri.len > 1: pl.add(" ")
      # beware of 'result = p(result)'. We always allocate a temporary:
      if d.k in {locTemp, locNone}:
        # We already got a temp. Great, special case it:
        if d.k == locNone: d = getTemp(p, typ.returnType, needsInit=true)
        pl.add("Result: ")
        pl.add(addrLoc(p.config, d))
        pl.add("]")
        p.s(cpsStmts).addStmt():
          p.s(cpsStmts).add(extract(pl))
      else:
        var tmp: TLoc = getTemp(p, typ.returnType, needsInit=true)
        pl.add(addrLoc(p.config, tmp))
        pl.add("]")
        p.s(cpsStmts).addStmt():
          p.s(cpsStmts).add(extract(pl))
        genAssignment(p, d, tmp, {}) # no need for deep copying
    else:
      pl.add("]")
      if d.k == locNone: d = getTemp(p, typ.returnType)
      assert(d.t != nil)        # generate an assignment to d:
      var list: TLoc = initLoc(locCall, ri, OnUnknown)
      list.snippet = extract(pl)
      genAssignment(p, d, list, {}) # no need for deep copying
  else:
    pl.add("]")
    p.s(cpsStmts).addStmt():
      p.s(cpsStmts).add(extract(pl))

proc notYetAlive(n: AnyNode): bool {.inline.} =
  let r = getRoot(n)
  result = r != nil and r.loc.lode == nil

proc isInactiveDestructorCall(p: BProc, e: AnyNode): bool =
  #[ Consider this example.

    var :tmpD_3281815
    try:
      if true:
        return
      let args_3280013 =
        wasMoved_3281816(:tmpD_3281815)
        `=_3280036`(:tmpD_3281815, [1])
        :tmpD_3281815
    finally:
      `=destroy_3280027`(args_3280013)

  We want to return early but the 'finally' section is traversed before
  the 'let args = ...' statement. We exploit this to generate better
  code for 'return'. ]#
  result = e.safeLen == 2 and e.firstSon.kind == nkSym and
    e.firstSon.sym.name.s == "=destroy" and notYetAlive(e.secondSon.skipAddr)

proc genAsgnCall(p: BProc, le: PNode, ri: AnyNode, d: var TLoc) =
  if p.withinBlockLeaveActions > 0 and isInactiveDestructorCall(p, ri):
    return
  when defined(icDbgHash):
    if ri.firstSon.typ == nil:
      echo "NILCALLEE kind=", ri.firstSon.kind,
        " sym=", (if ri.firstSon.kind == nkSym: ri.firstSon.sym.name.s else: "-"),
        " symKind=", (if ri.firstSon.kind == nkSym: $ri.firstSon.sym.kind else: "-"),
        " flags=", (if ri.firstSon.kind == nkSym: $ri.firstSon.sym.flags else: "-"),
        " lazy=", nfLazyType in ri.firstSon.flags,
        " inProc=", (if p.prc != nil: p.prc.name.s else: "NIL"),
        " module=", p.module.module.name.s
      raiseAssert "nil callee type, see NILCALLEE above"
  if ri.firstSon.typ.skipTypes({tyGenericInst, tyAlias, tySink, tyOwned}).callConv == ccClosure:
    genClosureCall(p, le, ri, d)
  elif ri.firstSon.kind == nkSym and sfInfixCall in ri.firstSon.sym.flags:
    genInfixCall(p, le, ri, d)
  elif ri.firstSon.kind == nkSym and sfNamedParamCall in ri.firstSon.sym.flags:
    genNamedParamCall(p, ri, d)
  else:
    genPrefixCall(p, le, ri, d)

proc genCall(p: BProc, e: AnyNode, d: var TLoc) = genAsgnCall(p, nil, e, d)
