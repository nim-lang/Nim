#
#
#           The Nim Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# this module does the semantic checking for expressions
# included from sem.nim

const
  errExprXHasNoType = "expression '$1' has no type (or is ambiguous)"
  errXExpectsTypeOrValue = "'$1' expects a type or value"
  errVarForOutParamNeededX = "for a 'var' type a variable needs to be passed; but '$1' is immutable"
  errXStackEscape = "address of '$1' may not escape its stack frame"
  errExprHasNoAddress = "expression has no address"
  errCannotInterpretNodeX = "cannot evaluate '$1'"
  errNamedExprExpected = "named expression expected"
  errNamedExprNotAllowed = "named expression not allowed here"
  errFieldInitTwice = "field initialized twice: '$1'"
  errUndeclaredFieldX = "undeclared field: '$1'"

proc semTemplateExpr(c: PContext, n: PNode, s: PSym,
                     flags: TExprFlags = {}): PNode =
  let info = getCallLineInfo(n)
  markUsed(c, info, s, c.graph.usageSym)
  onUse(info, s)
  # Note: This is n.info on purpose. It prevents template from creating an info
  # context when called from an another template
  pushInfoContext(c.config, n.info, s.detailedInfo)
  result = evalTemplate(n, s, getCurrOwner(c), c.config, efFromHlo in flags)
  if efNoSemCheck notin flags: result = semAfterMacroCall(c, n, result, s, flags)
  popInfoContext(c.config)

  # XXX: A more elaborate line info rewrite might be needed
  result.info = info

proc semFieldAccess(c: PContext, n: PNode, flags: TExprFlags = {}): PNode

template rejectEmptyNode(n: PNode) =
  # No matter what a nkEmpty node is not what we want here
  if n.kind == nkEmpty: illFormedAst(n, c.config)

proc semOperand(c: PContext, n: PNode, flags: TExprFlags = {}): PNode =
  rejectEmptyNode(n)
  # same as 'semExprWithType' but doesn't check for proc vars
  result = semExpr(c, n, flags + {efOperand})
  if result.typ != nil:
    # XXX tyGenericInst here?
    if result.typ.kind == tyProc and tfUnresolved in result.typ.flags:
      localError(c.config, n.info, errProcHasNoConcreteType % n.renderTree)
    if result.typ.kind in {tyVar, tyLent}: result = newDeref(result)
  elif {efWantStmt, efAllowStmt} * flags != {}:
    result.typ = newTypeS(tyVoid, c)
  else:
    localError(c.config, n.info, errExprXHasNoType %
               renderTree(result, {renderNoComments}))
    result.typ = errorType(c)

proc semExprWithType(c: PContext, n: PNode, flags: TExprFlags = {}): PNode =
  rejectEmptyNode(n)
  result = semExpr(c, n, flags+{efWantValue})
  if result.kind == nkEmpty:
    # do not produce another redundant error message:
    result = errorNode(c, n)
  if result.typ == nil or result.typ == c.enforceVoidContext:
    localError(c.config, n.info, errExprXHasNoType %
                renderTree(result, {renderNoComments}))
    result.typ = errorType(c)
  else:
    if result.typ.kind in {tyVar, tyLent}: result = newDeref(result)

proc semExprNoDeref(c: PContext, n: PNode, flags: TExprFlags = {}): PNode =
  rejectEmptyNode(n)
  result = semExpr(c, n, flags+{efWantValue})
  if result.kind == nkEmpty:
    # do not produce another redundant error message:
    result = errorNode(c, n)
  if result.typ == nil:
    localError(c.config, n.info, errExprXHasNoType %
               renderTree(result, {renderNoComments}))
    result.typ = errorType(c)

proc semSymGenericInstantiation(c: PContext, n: PNode, s: PSym): PNode =
  result = symChoice(c, n, s, scClosed)

proc inlineConst(c: PContext, n: PNode, s: PSym): PNode {.inline.} =
  result = copyTree(s.ast)
  if result.isNil:
    localError(c.config, n.info, "constant of type '" & typeToString(s.typ) & "' has no value")
    result = newSymNode(s)
  else:
    result.typ = s.typ
    result.info = n.info

type
  TConvStatus = enum
    convOK,
    convNotNeedeed,
    convNotLegal,
    convNotInRange

proc checkConversionBetweenObjects(castDest, src: PType; pointers: int): TConvStatus =
  let diff = inheritanceDiff(castDest, src)
  return if diff == high(int) or (pointers > 1 and diff != 0):
      convNotLegal
    else:
      convOK

const
  IntegralTypes = {tyBool, tyEnum, tyChar, tyInt..tyUInt64}

proc checkConvertible(c: PContext, targetTyp: PType, src: PNode): TConvStatus =
  let srcTyp = src.typ.skipTypes({tyStatic})
  result = convOK
  if sameType(targetTyp, srcTyp) and targetTyp.sym == srcTyp.sym:
    # don't annoy conversions that may be needed on another processor:
    if targetTyp.kind notin IntegralTypes+{tyRange}:
      result = convNotNeedeed
    return
  var d = skipTypes(targetTyp, abstractVar)
  var s = srcTyp
  if s.kind in tyUserTypeClasses and s.isResolvedUserTypeClass:
    s = s.lastSon
  s = skipTypes(s, abstractVar-{tyTypeDesc, tyOwned})
  if s.kind == tyOwned and d.kind != tyOwned:
    s = s.lastSon
  var pointers = 0
  while (d != nil) and (d.kind in {tyPtr, tyRef, tyOwned}):
    if s.kind == tyOwned and d.kind != tyOwned:
      s = s.lastSon
    elif d.kind != s.kind:
      break
    else:
      d = d.lastSon
      s = s.lastSon
    inc pointers

  let targetBaseTyp = skipTypes(targetTyp, abstractVarRange)
  let srcBaseTyp = skipTypes(srcTyp, abstractVarRange-{tyTypeDesc})

  if d == nil:
    result = convNotLegal
  elif d.skipTypes(abstractInst).kind == tyObject and s.skipTypes(abstractInst).kind == tyObject:
    result = checkConversionBetweenObjects(d.skipTypes(abstractInst), s.skipTypes(abstractInst), pointers)
  elif (targetBaseTyp.kind in IntegralTypes) and
      (srcBaseTyp.kind in IntegralTypes):
    if targetTyp.isOrdinalType:
      if src.kind in nkCharLit..nkUInt64Lit and
          src.intVal notin firstOrd(c.config, targetTyp)..lastOrd(c.config, targetTyp):
        result = convNotInRange
      elif src.kind in nkFloatLit..nkFloat64Lit and
          (classify(src.floatVal) in {fcNan, fcNegInf, fcInf} or
            src.floatVal.int64 notin firstOrd(c.config, targetTyp)..lastOrd(c.config, targetTyp)):
        result = convNotInRange
    elif targetBaseTyp.kind in tyFloat..tyFloat64:
      if src.kind in nkFloatLit..nkFloat64Lit and
          not floatRangeCheck(src.floatVal, targetTyp):
        result = convNotInRange
      elif src.kind in nkCharLit..nkUInt64Lit and
          not floatRangeCheck(src.intVal.float, targetTyp):
        result = convNotInRange
  else:
    # we use d, s here to speed up that operation a bit:
    case cmpTypes(c, d, s)
    of isNone, isGeneric:
      if not compareTypes(targetTyp.skipTypes(abstractVar), srcTyp.skipTypes({tyOwned}), dcEqIgnoreDistinct):
        result = convNotLegal
    else:
      discard

proc isCastable(conf: ConfigRef; dst, src: PType): bool =
  ## Checks whether the source type can be cast to the destination type.
  ## Casting is very unrestrictive; casts are allowed as long as
  ## castDest.size >= src.size, and typeAllowed(dst, skParam)
  #const
  #  castableTypeKinds = {tyInt, tyPtr, tyRef, tyCstring, tyString,
  #                       tySequence, tyPointer, tyNil, tyOpenArray,
  #                       tyProc, tySet, tyEnum, tyBool, tyChar}
  let src = src.skipTypes(tyUserTypeClasses)
  if skipTypes(dst, abstractInst-{tyOpenArray}).kind == tyOpenArray:
    return false
  if skipTypes(src, abstractInst-{tyTypeDesc}).kind == tyTypeDesc:
    return false

  var dstSize, srcSize: BiggestInt
  dstSize = computeSize(conf, dst)
  srcSize = computeSize(conf, src)
  if dstSize == -3 or srcSize == -3: # szUnknownSize
    # The Nim compiler can't detect if it's legal or not.
    # Just assume the programmer knows what he is doing.
    return true
  if dstSize < 0:
    result = false
  elif srcSize < 0:
    result = false
  elif typeAllowed(dst, skParam) != nil:
    result = false
  elif dst.kind == tyProc and dst.callConv == ccClosure:
    result = src.kind == tyProc and src.callConv == ccClosure
  else:
    result = (dstSize >= srcSize) or
        (skipTypes(dst, abstractInst).kind in IntegralTypes) or
        (skipTypes(src, abstractInst-{tyTypeDesc}).kind in IntegralTypes)
  if result and src.kind == tyNil:
    result = dst.size <= conf.target.ptrSize

proc isSymChoice(n: PNode): bool {.inline.} =
  result = n.kind in nkSymChoices

proc maybeLiftType(t: var PType, c: PContext, info: TLineInfo) =
  # XXX: liftParamType started to perform addDecl
  # we could do that instead in semTypeNode by snooping for added
  # gnrc. params, then it won't be necessary to open a new scope here
  openScope(c)
  var lifted = liftParamType(c, skType, newNodeI(nkArgList, info),
                             t, ":anon", info)
  closeScope(c)
  if lifted != nil: t = lifted

proc isOwnedSym(c: PContext; n: PNode): bool =
  let s = qualifiedLookUp(c, n, {})
  result = s != nil and sfSystemModule in s.owner.flags and s.name.s == "owned"

proc semConv(c: PContext, n: PNode): PNode =
  if sonsLen(n) != 2:
    localError(c.config, n.info, "a type conversion takes exactly one argument")
    return n

  result = newNodeI(nkConv, n.info)

  var targetType = semTypeNode(c, n.sons[0], nil)
  if targetType.kind == tyTypeDesc:
    internalAssert c.config, targetType.len > 0
    if targetType.base.kind == tyNone:
      return semTypeOf(c, n)
    else:
      targetType = targetType.base
  elif targetType.kind == tyStatic:
    var evaluated = semStaticExpr(c, n[1])
    if evaluated.kind == nkType or evaluated.typ.kind == tyTypeDesc:
      result = n
      result.typ = c.makeTypeDesc semStaticType(c, evaluated, nil)
      return
    elif targetType.base.kind == tyNone:
      return evaluated
    else:
      targetType = targetType.base

  maybeLiftType(targetType, c, n[0].info)

  if targetType.kind in {tySink, tyLent} or isOwnedSym(c, n[0]):
    let baseType = semTypeNode(c, n.sons[1], nil).skipTypes({tyTypeDesc})
    let t = newTypeS(targetType.kind, c)
    if targetType.kind == tyOwned:
      t.flags.incl tfHasOwned
    t.rawAddSonNoPropagationOfTypeFlags baseType
    result = newNodeI(nkType, n.info)
    result.typ = makeTypeDesc(c, t)
    return

  result.addSon copyTree(n.sons[0])

  # special case to make MyObject(x = 3) produce a nicer error message:
  if n[1].kind == nkExprEqExpr and
      targetType.skipTypes(abstractPtrs).kind == tyObject:
    localError(c.config, n.info, "object construction uses ':', not '='")
  var op = semExprWithType(c, n.sons[1])
  if targetType.isMetaType:
    let final = inferWithMetatype(c, targetType, op, true)
    result.addSon final
    result.typ = final.typ
    return

  result.typ = targetType
  # XXX op is overwritten later on, this is likely added too early
  # here or needs to be overwritten too then.
  addSon(result, op)

  if not isSymChoice(op):
    let status = checkConvertible(c, result.typ, op)
    case status
    of convOK:
      # handle SomeProcType(SomeGenericProc)
      if op.kind == nkSym and op.sym.isGenericRoutine:
        result.sons[1] = fitNode(c, result.typ, result.sons[1], result.info)
      elif op.kind in {nkPar, nkTupleConstr} and targetType.kind == tyTuple:
        op = fitNode(c, targetType, op, result.info)
    of convNotNeedeed:
      message(c.config, n.info, hintConvFromXtoItselfNotNeeded, result.typ.typeToString)
    of convNotLegal:
      result = fitNode(c, result.typ, result.sons[1], result.info)
      if result == nil:
        localError(c.config, n.info, "illegal conversion from '$1' to '$2'" %
          [op.typ.typeToString, result.typ.typeToString])
    of convNotInRange:
      let value =
        if op.kind in {nkCharLit..nkUInt64Lit}: $op.getInt else: $op.getFloat
      localError(c.config, n.info, errGenerated, value & " can't be converted to " &
        result.typ.typeToString)
  else:
    for i in 0 ..< sonsLen(op):
      let it = op.sons[i]
      let status = checkConvertible(c, result.typ, it)
      if status in {convOK, convNotNeedeed}:
        markUsed(c, n.info, it.sym, c.graph.usageSym)
        onUse(n.info, it.sym)
        markIndirect(c, it.sym)
        return it
    errorUseQualifier(c, n.info, op.sons[0].sym)

proc semCast(c: PContext, n: PNode): PNode =
  ## Semantically analyze a casting ("cast[type](param)")
  checkSonsLen(n, 2, c.config)
  let targetType = semTypeNode(c, n.sons[0], nil)
  let castedExpr = semExprWithType(c, n.sons[1])
  if tfHasMeta in targetType.flags:
    localError(c.config, n.sons[0].info, "cannot cast to a non concrete type: '$1'" % $targetType)
  if not isCastable(c.config, targetType, castedExpr.typ):
    let tar = $targetType
    let alt = typeToString(targetType, preferDesc)
    let msg = if tar != alt: tar & "=" & alt else: tar
    localError(c.config, n.info, "expression cannot be cast to " & msg)
  result = newNodeI(nkCast, n.info)
  result.typ = targetType
  addSon(result, copyTree(n.sons[0]))
  addSon(result, castedExpr)

proc semLowHigh(c: PContext, n: PNode, m: TMagic): PNode =
  const
    opToStr: array[mLow..mHigh, string] = ["low", "high"]
  if sonsLen(n) != 2:
    localError(c.config, n.info, errXExpectsTypeOrValue % opToStr[m])
  else:
    n.sons[1] = semExprWithType(c, n.sons[1], {efDetermineType})
    var typ = skipTypes(n.sons[1].typ, abstractVarRange + {tyTypeDesc, tyUserTypeClassInst})
    case typ.kind
    of tySequence, tyString, tyCString, tyOpenArray, tyVarargs:
      n.typ = getSysType(c.graph, n.info, tyInt)
    of tyArray:
      n.typ = typ.sons[0] # indextype
    of tyInt..tyInt64, tyChar, tyBool, tyEnum, tyUInt8, tyUInt16, tyUInt32, tyFloat..tyFloat64:
      n.typ = n.sons[1].typ.skipTypes({tyTypeDesc})
    of tyGenericParam:
      # prepare this for resolving in semtypinst:
      # we must use copyTree here in order to avoid creating a cycle
      # that could easily turn into an infinite recursion in semtypinst
      n.typ = makeTypeFromExpr(c, n.copyTree)
    else:
      localError(c.config, n.info, "invalid argument for: " & opToStr[m])
  result = n

proc fixupStaticType(c: PContext, n: PNode) =
  # This proc can be applied to evaluated expressions to assign
  # them a static type.
  #
  # XXX: with implicit static, this should not be necessary,
  # because the output type of operations such as `semConstExpr`
  # should be a static type (as well as the type of any other
  # expression that can be implicitly evaluated). For now, we
  # apply this measure only in code that is enlightened to work
  # with static types.
  if n.typ.kind != tyStatic:
    n.typ = newTypeWithSons(getCurrOwner(c), tyStatic, @[n.typ])
    n.typ.n = n # XXX: cycles like the one here look dangerous.
                # Consider using `n.copyTree`

proc isOpImpl(c: PContext, n: PNode, flags: TExprFlags): PNode =
  internalAssert c.config,
    n.sonsLen == 3 and
    n[1].typ != nil and
    n[2].kind in {nkStrLit..nkTripleStrLit, nkType}

  var
    res = false
    t1 = n[1].typ
    t2 = n[2].typ

  if t1.kind == tyTypeDesc and t2.kind != tyTypeDesc:
    t1 = t1.base

  if n[2].kind in {nkStrLit..nkTripleStrLit}:
    case n[2].strVal.normalize
    of "closure":
      let t = skipTypes(t1, abstractRange)
      res = t.kind == tyProc and
            t.callConv == ccClosure and
            tfIterator notin t.flags
    of "iterator":
      let t = skipTypes(t1, abstractRange)
      res = t.kind == tyProc and
            t.callConv == ccClosure and
            tfIterator in t.flags
    else:
      res = false
  else:
    maybeLiftType(t2, c, n.info)
    var m: TCandidate
    initCandidate(c, m, t2)
    if efExplain in flags:
      m.diagnostics = @[]
      m.diagnosticsEnabled = true
    res = typeRel(m, t2, t1) >= isSubtype # isNone

  result = newIntNode(nkIntLit, ord(res))
  result.typ = n.typ

proc semIs(c: PContext, n: PNode, flags: TExprFlags): PNode =
  if sonsLen(n) != 3:
    localError(c.config, n.info, "'is' operator takes 2 arguments")

  let boolType = getSysType(c.graph, n.info, tyBool)
  result = n
  n.typ = boolType
  var liftLhs = true

  n.sons[1] = semExprWithType(c, n[1], {efDetermineType, efWantIterator})
  if n[2].kind notin {nkStrLit..nkTripleStrLit}:
    let t2 = semTypeNode(c, n[2], nil)
    n.sons[2] = newNodeIT(nkType, n[2].info, t2)
    if t2.kind == tyStatic:
      let evaluated = tryConstExpr(c, n[1])
      if evaluated != nil:
        c.fixupStaticType(evaluated)
        n[1] = evaluated
      else:
        result = newIntNode(nkIntLit, 0)
        result.typ = boolType
        return
    elif t2.kind == tyTypeDesc and
        (t2.base.kind == tyNone or tfExplicit in t2.flags):
      # When the right-hand side is an explicit type, we must
      # not allow regular values to be matched against the type:
      liftLhs = false
  else:
    n.sons[2] = semExpr(c, n[2])

  var lhsType = n[1].typ
  if lhsType.kind != tyTypeDesc:
    if liftLhs:
      n[1] = makeTypeSymNode(c, lhsType, n[1].info)
      lhsType = n[1].typ
  else:
    if lhsType.base.kind == tyNone or
        (c.inGenericContext > 0 and lhsType.base.containsGenericType):
      # BUGFIX: don't evaluate this too early: ``T is void``
      return

  result = isOpImpl(c, n, flags)

proc semOpAux(c: PContext, n: PNode) =
  const flags = {efDetermineType}
  for i in 1 ..< n.sonsLen:
    var a = n.sons[i]
    if a.kind == nkExprEqExpr and sonsLen(a) == 2:
      let info = a.sons[0].info
      a.sons[0] = newIdentNode(considerQuotedIdent(c, a.sons[0], a), info)
      a.sons[1] = semExprWithType(c, a.sons[1], flags)
      a.typ = a.sons[1].typ
    else:
      n.sons[i] = semExprWithType(c, a, flags)

proc overloadedCallOpr(c: PContext, n: PNode): PNode =
  # quick check if there is *any* () operator overloaded:
  var par = getIdent(c.cache, "()")
  if searchInScopes(c, par) == nil:
    result = nil
  else:
    result = newNodeI(nkCall, n.info)
    addSon(result, newIdentNode(par, n.info))
    for i in 0 ..< sonsLen(n): addSon(result, n.sons[i])
    result = semExpr(c, result)

proc changeType(c: PContext; n: PNode, newType: PType, check: bool) =
  case n.kind
  of nkCurly, nkBracket:
    for i in 0 ..< sonsLen(n):
      changeType(c, n.sons[i], elemType(newType), check)
  of nkPar, nkTupleConstr:
    let tup = newType.skipTypes({tyGenericInst, tyAlias, tySink, tyDistinct})
    if tup.kind != tyTuple:
      if tup.kind == tyObject: return
      globalError(c.config, n.info, "no tuple type for constructor")
    elif sonsLen(n) > 0 and n.sons[0].kind == nkExprColonExpr:
      # named tuple?
      for i in 0 ..< sonsLen(n):
        var m = n.sons[i].sons[0]
        if m.kind != nkSym:
          globalError(c.config, m.info, "invalid tuple constructor")
          return
        if tup.n != nil:
          var f = getSymFromList(tup.n, m.sym.name)
          if f == nil:
            globalError(c.config, m.info, "unknown identifier: " & m.sym.name.s)
            return
          changeType(c, n.sons[i].sons[1], f.typ, check)
        else:
          changeType(c, n.sons[i].sons[1], tup.sons[i], check)
    else:
      for i in 0 ..< sonsLen(n):
        changeType(c, n.sons[i], tup.sons[i], check)
        when false:
          var m = n.sons[i]
          var a = newNodeIT(nkExprColonExpr, m.info, newType.sons[i])
          addSon(a, newSymNode(newType.n.sons[i].sym))
          addSon(a, m)
          changeType(m, tup.sons[i], check)
  of nkCharLit..nkUInt64Lit:
    if check and n.kind != nkUInt64Lit:
      let value = n.intVal
      if value < firstOrd(c.config, newType) or value > lastOrd(c.config, newType):
        localError(c.config, n.info, "cannot convert " & $value &
                                         " to " & typeToString(newType))
  else: discard
  n.typ = newType

proc arrayConstrType(c: PContext, n: PNode): PType =
  var typ = newTypeS(tyArray, c)
  rawAddSon(typ, nil)     # index type
  if sonsLen(n) == 0:
    rawAddSon(typ, newTypeS(tyEmpty, c)) # needs an empty basetype!
  else:
    var t = skipTypes(n.sons[0].typ, {tyGenericInst, tyVar, tyLent, tyOrdinal, tyAlias, tySink})
    addSonSkipIntLit(typ, t)
  typ.sons[0] = makeRangeType(c, 0, sonsLen(n) - 1, n.info)
  result = typ

proc semArrayConstr(c: PContext, n: PNode, flags: TExprFlags): PNode =
  result = newNodeI(nkBracket, n.info)
  result.typ = newTypeS(tyArray, c)
  rawAddSon(result.typ, nil)     # index type
  var
    firstIndex, lastIndex: BiggestInt = 0
    indexType = getSysType(c.graph, n.info, tyInt)
    lastValidIndex = lastOrd(c.config, indexType)
  if sonsLen(n) == 0:
    rawAddSon(result.typ, newTypeS(tyEmpty, c)) # needs an empty basetype!
    lastIndex = -1
  else:
    var x = n.sons[0]
    if x.kind == nkExprColonExpr and sonsLen(x) == 2:
      var idx = semConstExpr(c, x.sons[0])
      if not isOrdinalType(idx.typ):
        localError(c.config, idx.info, "expected ordinal value for array " &
                   "index, got '$1'" % renderTree(idx))
      else:
        firstIndex = getOrdValue(idx)
        lastIndex = firstIndex
        indexType = idx.typ
        lastValidIndex = lastOrd(c.config, indexType)
        x = x.sons[1]

    let yy = semExprWithType(c, x)
    var typ = yy.typ
    addSon(result, yy)
    #var typ = skipTypes(result.sons[0].typ, {tyGenericInst, tyVar, tyLent, tyOrdinal})
    for i in 1 ..< sonsLen(n):
      if lastIndex == lastValidIndex:
        let validIndex = makeRangeType(c, firstIndex, lastValidIndex, n.info,
                                       indexType)
        localError(c.config, n.info, "size of array exceeds range of index " &
          "type '$1' by $2 elements" % [typeToString(validIndex), $(n.len-i)])

      x = n.sons[i]
      if x.kind == nkExprColonExpr and sonsLen(x) == 2:
        var idx = semConstExpr(c, x.sons[0])
        idx = fitNode(c, indexType, idx, x.info)
        if lastIndex+1 != getOrdValue(idx):
          localError(c.config, x.info, "invalid order in array constructor")
        x = x.sons[1]

      let xx = semExprWithType(c, x, flags*{efAllowDestructor})
      result.add xx
      typ = commonType(typ, xx.typ)
      #n.sons[i] = semExprWithType(c, x, flags*{efAllowDestructor})
      #addSon(result, fitNode(c, typ, n.sons[i]))
      inc(lastIndex)
    addSonSkipIntLit(result.typ, typ)
    for i in 0 ..< result.len:
      result.sons[i] = fitNode(c, typ, result.sons[i], result.sons[i].info)
  result.typ.sons[0] = makeRangeType(c, firstIndex, lastIndex, n.info,
                                     indexType)

proc fixAbstractType(c: PContext, n: PNode) =
  for i in 1 ..< n.len:
    let it = n.sons[i]
    # do not get rid of nkHiddenSubConv for OpenArrays, the codegen needs it:
    if it.kind == nkHiddenSubConv and
        skipTypes(it.typ, abstractVar).kind notin {tyOpenArray, tyVarargs}:
      if skipTypes(it.sons[1].typ, abstractVar).kind in
            {tyNil, tyTuple, tySet} or it[1].isArrayConstr:
        var s = skipTypes(it.typ, abstractVar)
        if s.kind != tyUntyped:
          changeType(c, it.sons[1], s, check=true)
        n.sons[i] = it.sons[1]

proc isAssignable(c: PContext, n: PNode; isUnsafeAddr=false): TAssignableResult =
  result = parampatterns.isAssignable(c.p.owner, n, isUnsafeAddr)

proc isUnresolvedSym(s: PSym): bool =
  return s.kind == skGenericParam or
         tfInferrableStatic in s.typ.flags or
         (s.kind == skParam and s.typ.isMetaType) or
         (s.kind == skType and
          s.typ.flags * {tfGenericTypeParam, tfImplicitTypeParam} != {})

proc hasUnresolvedArgs(c: PContext, n: PNode): bool =
  # Checks whether an expression depends on generic parameters that
  # don't have bound values yet. E.g. this could happen in situations
  # such as:
  #  type Slot[T] = array[T.size, byte]
  #  proc foo[T](x: default(T))
  #
  # Both static parameter and type parameters can be unresolved.
  case n.kind
  of nkSym:
    return isUnresolvedSym(n.sym)
  of nkIdent, nkAccQuoted:
    let ident = considerQuotedIdent(c, n)
    let sym = searchInScopes(c, ident)
    if sym != nil:
      return isUnresolvedSym(sym)
    else:
      return false
  else:
    for i in 0..<n.safeLen:
      if hasUnresolvedArgs(c, n.sons[i]): return true
    return false

proc newHiddenAddrTaken(c: PContext, n: PNode): PNode =
  if n.kind == nkHiddenDeref and not (c.config.cmd == cmdCompileToCpp or
                                      sfCompileToCpp in c.module.flags):
    checkSonsLen(n, 1, c.config)
    result = n.sons[0]
  else:
    result = newNodeIT(nkHiddenAddr, n.info, makeVarType(c, n.typ))
    addSon(result, n)
    if isAssignable(c, n) notin {arLValue, arLocalLValue}:
      localError(c.config, n.info, errVarForOutParamNeededX % renderNotLValue(n))

proc analyseIfAddressTaken(c: PContext, n: PNode): PNode =
  result = n
  case n.kind
  of nkSym:
    # n.sym.typ can be nil in 'check' mode ...
    if n.sym.typ != nil and
        skipTypes(n.sym.typ, abstractInst-{tyTypeDesc}).kind notin {tyVar, tyLent}:
      incl(n.sym.flags, sfAddrTaken)
      result = newHiddenAddrTaken(c, n)
  of nkDotExpr:
    checkSonsLen(n, 2, c.config)
    if n.sons[1].kind != nkSym:
      internalError(c.config, n.info, "analyseIfAddressTaken")
      return
    if skipTypes(n.sons[1].sym.typ, abstractInst-{tyTypeDesc}).kind notin {tyVar, tyLent}:
      incl(n.sons[1].sym.flags, sfAddrTaken)
      result = newHiddenAddrTaken(c, n)
  of nkBracketExpr:
    checkMinSonsLen(n, 1, c.config)
    if skipTypes(n.sons[0].typ, abstractInst-{tyTypeDesc}).kind notin {tyVar, tyLent}:
      if n.sons[0].kind == nkSym: incl(n.sons[0].sym.flags, sfAddrTaken)
      result = newHiddenAddrTaken(c, n)
  else:
    result = newHiddenAddrTaken(c, n)

proc analyseIfAddressTakenInCall(c: PContext, n: PNode) =
  checkMinSonsLen(n, 1, c.config)
  const
    FakeVarParams = {mNew, mNewFinalize, mInc, ast.mDec, mIncl, mExcl,
      mSetLengthStr, mSetLengthSeq, mAppendStrCh, mAppendStrStr, mSwap,
      mAppendSeqElem, mNewSeq, mReset, mShallowCopy, mDeepCopy, mMove,
      mWasMoved}

  # get the real type of the callee
  # it may be a proc var with a generic alias type, so we skip over them
  var t = n.sons[0].typ.skipTypes({tyGenericInst, tyAlias, tySink})

  if n.sons[0].kind == nkSym and n.sons[0].sym.magic in FakeVarParams:
    # BUGFIX: check for L-Value still needs to be done for the arguments!
    # note sometimes this is eval'ed twice so we check for nkHiddenAddr here:
    for i in 1 ..< sonsLen(n):
      if i < sonsLen(t) and t.sons[i] != nil and
          skipTypes(t.sons[i], abstractInst-{tyTypeDesc}).kind == tyVar:
        let it = n[i]
        if isAssignable(c, it) notin {arLValue, arLocalLValue}:
          if it.kind != nkHiddenAddr:
            localError(c.config, it.info, errVarForOutParamNeededX % $it)
    # bug #5113: disallow newSeq(result) where result is a 'var T':
    if n[0].sym.magic in {mNew, mNewFinalize, mNewSeq}:
      var arg = n[1] #.skipAddr
      if arg.kind == nkHiddenDeref: arg = arg[0]
      if arg.kind == nkSym and arg.sym.kind == skResult and
          arg.typ.skipTypes(abstractInst).kind in {tyVar, tyLent}:
        localError(c.config, n.info, errXStackEscape % renderTree(n[1], {renderNoComments}))

    return
  for i in 1 ..< sonsLen(n):
    let n = if n.kind == nkHiddenDeref: n[0] else: n
    if n.sons[i].kind == nkHiddenCallConv:
      # we need to recurse explicitly here as converters can create nested
      # calls and then they wouldn't be analysed otherwise
      analyseIfAddressTakenInCall(c, n.sons[i])
    if i < sonsLen(t) and
        skipTypes(t.sons[i], abstractInst-{tyTypeDesc}).kind == tyVar:
      if n.sons[i].kind != nkHiddenAddr:
        n.sons[i] = analyseIfAddressTaken(c, n.sons[i])

include semmagic

proc evalAtCompileTime(c: PContext, n: PNode): PNode =
  result = n
  if n.kind notin nkCallKinds or n.sons[0].kind != nkSym: return
  var callee = n.sons[0].sym
  # workaround for bug #537 (overly aggressive inlining leading to
  # wrong NimNode semantics):
  if n.typ != nil and tfTriggersCompileTime in n.typ.flags: return

  # constant folding that is necessary for correctness of semantic pass:
  if callee.magic != mNone and callee.magic in ctfeWhitelist and n.typ != nil:
    var call = newNodeIT(nkCall, n.info, n.typ)
    call.add(n.sons[0])
    var allConst = true
    for i in 1 ..< n.len:
      var a = getConstExpr(c.module, n.sons[i], c.graph)
      if a == nil:
        allConst = false
        a = n.sons[i]
        if a.kind == nkHiddenStdConv: a = a.sons[1]
      call.add(a)
    if allConst:
      result = semfold.getConstExpr(c.module, call, c.graph)
      if result.isNil: result = n
      else: return result

  block maybeLabelAsStatic:
    # XXX: temporary work-around needed for tlateboundstatic.
    # This is certainly not correct, but it will get the job
    # done until we have a more robust infrastructure for
    # implicit statics.
    if n.len > 1:
      for i in 1 ..< n.len:
        # see bug #2113, it's possible that n[i].typ for errornous code:
        if n[i].typ.isNil or n[i].typ.kind != tyStatic or
            tfUnresolved notin n[i].typ.flags:
          break maybeLabelAsStatic
      n.typ = newTypeWithSons(c, tyStatic, @[n.typ])
      n.typ.flags.incl tfUnresolved

  # optimization pass: not necessary for correctness of the semantic pass
  if callee.kind == skConst or
     {sfNoSideEffect, sfCompileTime} * callee.flags != {} and
     {sfForward, sfImportc} * callee.flags == {} and n.typ != nil:

    if callee.kind != skConst and
       sfCompileTime notin callee.flags and
       optImplicitStatic notin c.config.options: return

    if callee.magic notin ctfeWhitelist: return

    if callee.kind notin {skProc, skFunc, skConverter, skConst} or callee.isGenericRoutine:
      return

    if n.typ != nil and typeAllowed(n.typ, skConst) != nil: return

    var call = newNodeIT(nkCall, n.info, n.typ)
    call.add(n.sons[0])
    for i in 1 ..< n.len:
      let a = getConstExpr(c.module, n.sons[i], c.graph)
      if a == nil: return n
      call.add(a)

    #echo "NOW evaluating at compile time: ", call.renderTree
    if c.inStaticContext == 0 or sfNoSideEffect in callee.flags:
      if sfCompileTime in callee.flags:
        result = evalStaticExpr(c.module, c.graph, call, c.p.owner)
        if result.isNil:
          localError(c.config, n.info, errCannotInterpretNodeX % renderTree(call))
        else: result = fixupTypeAfterEval(c, result, n)
      else:
        result = evalConstExpr(c.module, c.graph, call)
        if result.isNil: result = n
        else: result = fixupTypeAfterEval(c, result, n)
    else:
      result = n
    #if result != n:
    #  echo "SUCCESS evaluated at compile time: ", call.renderTree

proc semStaticExpr(c: PContext, n: PNode): PNode =
  inc c.inStaticContext
  openScope(c)
  let a = semExprWithType(c, n)
  closeScope(c)
  dec c.inStaticContext
  if a.findUnresolvedStatic != nil: return a
  result = evalStaticExpr(c.module, c.graph, a, c.p.owner)
  if result.isNil:
    localError(c.config, n.info, errCannotInterpretNodeX % renderTree(n))
    result = c.graph.emptyNode
  else:
    result = fixupTypeAfterEval(c, result, a)

proc semOverloadedCallAnalyseEffects(c: PContext, n: PNode, nOrig: PNode,
                                     flags: TExprFlags): PNode =
  if flags*{efInTypeof, efWantIterator} != {}:
    # consider: 'for x in pReturningArray()' --> we don't want the restriction
    # to 'skIterator' anymore; skIterator is preferred in sigmatch already
    # for typeof support.
    # for ``type(countup(1,3))``, see ``tests/ttoseq``.
    result = semOverloadedCall(c, n, nOrig,
      {skProc, skFunc, skMethod, skConverter, skMacro, skTemplate, skIterator}, flags)
  else:
    result = semOverloadedCall(c, n, nOrig,
      {skProc, skFunc, skMethod, skConverter, skMacro, skTemplate}, flags)

  if result != nil:
    if result.sons[0].kind != nkSym:
      internalError(c.config, "semOverloadedCallAnalyseEffects")
      return
    let callee = result.sons[0].sym
    case callee.kind
    of skMacro, skTemplate: discard
    else:
      if callee.kind == skIterator and callee.id == c.p.owner.id:
        localError(c.config, n.info, errRecursiveDependencyIteratorX % callee.name.s)
        # error correction, prevents endless for loop elimination in transf.
        # See bug #2051:
        result.sons[0] = newSymNode(errorSym(c, n))

proc semObjConstr(c: PContext, n: PNode, flags: TExprFlags): PNode

proc resolveIndirectCall(c: PContext; n, nOrig: PNode;
                         t: PType): TCandidate =
  initCandidate(c, result, t)
  matches(c, n, nOrig, result)
  if result.state != csMatch:
    # try to deref the first argument:
    if implicitDeref in c.features and canDeref(n):
      n.sons[1] = n.sons[1].tryDeref
      initCandidate(c, result, t)
      matches(c, n, nOrig, result)

proc bracketedMacro(n: PNode): PSym =
  if n.len >= 1 and n[0].kind == nkSym:
    result = n[0].sym
    if result.kind notin {skMacro, skTemplate}:
      result = nil

proc setGenericParams(c: PContext, n: PNode) =
  for i in 1 ..< n.len:
    n[i].typ = semTypeNode(c, n[i], nil)

proc afterCallActions(c: PContext; n, orig: PNode, flags: TExprFlags): PNode =
  result = n
  let callee = result.sons[0].sym
  case callee.kind
  of skMacro: result = semMacroExpr(c, result, orig, callee, flags)
  of skTemplate: result = semTemplateExpr(c, result, callee, flags)
  else:
    semFinishOperands(c, result)
    activate(c, result)
    fixAbstractType(c, result)
    analyseIfAddressTakenInCall(c, result)
    if callee.magic != mNone:
      result = magicsAfterOverloadResolution(c, result, flags)
    when false:
      if result.typ != nil and
          not (result.typ.kind == tySequence and result.typ.sons[0].kind == tyEmpty):
        liftTypeBoundOps(c, result.typ, n.info)
    #result = patchResolvedTypeBoundOp(c, result)
  if c.matchedConcept == nil:
    result = evalAtCompileTime(c, result)

proc semIndirectOp(c: PContext, n: PNode, flags: TExprFlags): PNode =
  result = nil
  checkMinSonsLen(n, 1, c.config)
  var prc = n.sons[0]
  if n.sons[0].kind == nkDotExpr:
    checkSonsLen(n.sons[0], 2, c.config)
    let n0 = semFieldAccess(c, n.sons[0])
    if n0.kind == nkDotCall:
      # it is a static call!
      result = n0
      result.kind = nkCall
      result.flags.incl nfExplicitCall
      for i in 1 ..< sonsLen(n): addSon(result, n.sons[i])
      return semExpr(c, result, flags)
    else:
      n.sons[0] = n0
  else:
    n.sons[0] = semExpr(c, n.sons[0], {efInCall})
    let t = n.sons[0].typ
    if t != nil and t.kind in {tyVar, tyLent}:
      n.sons[0] = newDeref(n.sons[0])
    elif n.sons[0].kind == nkBracketExpr:
      let s = bracketedMacro(n.sons[0])
      if s != nil:
        setGenericParams(c, n[0])
        return semDirectOp(c, n, flags)

  let nOrig = n.copyTree
  semOpAux(c, n)
  var t: PType = nil
  if n.sons[0].typ != nil:
    t = skipTypes(n.sons[0].typ, abstractInst+{tyOwned}-{tyTypeDesc, tyDistinct})
  if t != nil and t.kind == tyProc:
    # This is a proc variable, apply normal overload resolution
    let m = resolveIndirectCall(c, n, nOrig, t)
    if m.state != csMatch:
      if c.config.m.errorOutputs == {}:
        # speed up error generation:
        globalError(c.config, n.info, "type mismatch")
        return c.graph.emptyNode
      else:
        var hasErrorType = false
        var msg = "type mismatch: got <"
        for i in 1 ..< sonsLen(n):
          if i > 1: add(msg, ", ")
          let nt = n.sons[i].typ
          add(msg, typeToString(nt))
          if nt.kind == tyError:
            hasErrorType = true
            break
        if not hasErrorType:
          add(msg, ">\nbut expected one of: \n" &
              typeToString(n.sons[0].typ))
          localError(c.config, n.info, msg)
        return errorNode(c, n)
      result = nil
    else:
      result = m.call
      instGenericConvertersSons(c, result, m)

  elif t != nil and t.kind == tyTypeDesc:
    if n.len == 1: return semObjConstr(c, n, flags)
    return semConv(c, n)
  else:
    result = overloadedCallOpr(c, n)
    # Now that nkSym does not imply an iteration over the proc/iterator space,
    # the old ``prc`` (which is likely an nkIdent) has to be restored:
    if result == nil:
      # XXX: hmm, what kind of symbols will end up here?
      # do we really need to try the overload resolution?
      n.sons[0] = prc
      nOrig.sons[0] = prc
      n.flags.incl nfExprCall
      result = semOverloadedCallAnalyseEffects(c, n, nOrig, flags)
      if result == nil: return errorNode(c, n)
    elif result.kind notin nkCallKinds:
      # the semExpr() in overloadedCallOpr can even break this condition!
      # See bug #904 of how to trigger it:
      return result
  #result = afterCallActions(c, result, nOrig, flags)
  if result.sons[0].kind == nkSym:
    result = afterCallActions(c, result, nOrig, flags)
  else:
    fixAbstractType(c, result)
    analyseIfAddressTakenInCall(c, result)

proc semDirectOp(c: PContext, n: PNode, flags: TExprFlags): PNode =
  # this seems to be a hotspot in the compiler!
  let nOrig = n.copyTree
  #semLazyOpAux(c, n)
  result = semOverloadedCallAnalyseEffects(c, n, nOrig, flags)
  if result != nil: result = afterCallActions(c, result, nOrig, flags)
  else: result = errorNode(c, n)

proc buildEchoStmt(c: PContext, n: PNode): PNode =
  # we MUST not check 'n' for semantics again here! But for now we give up:
  result = newNodeI(nkCall, n.info)
  var e = strTableGet(c.graph.systemModule.tab, getIdent(c.cache, "echo"))
  if e != nil:
    add(result, newSymNode(e))
  else:
    localError(c.config, n.info, "system needs: echo")
    add(result, errorNode(c, n))
  add(result, n)
  result = semExpr(c, result)

proc semExprNoType(c: PContext, n: PNode): PNode =
  let isPush = hintExtendedContext in c.config.notes
  if isPush: pushInfoContext(c.config, n.info)
  result = semExpr(c, n, {efWantStmt})
  discardCheck(c, result, {})
  if isPush: popInfoContext(c.config)

proc isTypeExpr(n: PNode): bool =
  case n.kind
  of nkType, nkTypeOfExpr: result = true
  of nkSym: result = n.sym.kind == skType
  else: result = false

proc createSetType(c: PContext; baseType: PType): PType =
  assert baseType != nil
  result = newTypeS(tySet, c)
  rawAddSon(result, baseType)

proc lookupInRecordAndBuildCheck(c: PContext, n, r: PNode, field: PIdent,
                                 check: var PNode): PSym =
  # transform in a node that contains the runtime check for the
  # field, if it is in a case-part...
  result = nil
  case r.kind
  of nkRecList:
    for i in 0 ..< sonsLen(r):
      result = lookupInRecordAndBuildCheck(c, n, r.sons[i], field, check)
      if result != nil: return
  of nkRecCase:
    checkMinSonsLen(r, 2, c.config)
    if (r.sons[0].kind != nkSym): illFormedAst(r, c.config)
    result = lookupInRecordAndBuildCheck(c, n, r.sons[0], field, check)
    if result != nil: return
    let setType = createSetType(c, r.sons[0].typ)
    var s = newNodeIT(nkCurly, r.info, setType)
    for i in 1 ..< sonsLen(r):
      var it = r.sons[i]
      case it.kind
      of nkOfBranch:
        result = lookupInRecordAndBuildCheck(c, n, lastSon(it), field, check)
        if result == nil:
          for j in 0..sonsLen(it)-2: addSon(s, copyTree(it.sons[j]))
        else:
          if check == nil:
            check = newNodeI(nkCheckedFieldExpr, n.info)
            addSon(check, c.graph.emptyNode) # make space for access node
          s = newNodeIT(nkCurly, n.info, setType)
          for j in 0 .. sonsLen(it) - 2: addSon(s, copyTree(it.sons[j]))
          var inExpr = newNodeIT(nkCall, n.info, getSysType(c.graph, n.info, tyBool))
          addSon(inExpr, newSymNode(c.graph.opContains, n.info))
          addSon(inExpr, s)
          addSon(inExpr, copyTree(r.sons[0]))
          addSon(check, inExpr)
          #addSon(check, semExpr(c, inExpr))
          return
      of nkElse:
        result = lookupInRecordAndBuildCheck(c, n, lastSon(it), field, check)
        if result != nil:
          if check == nil:
            check = newNodeI(nkCheckedFieldExpr, n.info)
            addSon(check, c.graph.emptyNode) # make space for access node
          var inExpr = newNodeIT(nkCall, n.info, getSysType(c.graph, n.info, tyBool))
          addSon(inExpr, newSymNode(c.graph.opContains, n.info))
          addSon(inExpr, s)
          addSon(inExpr, copyTree(r.sons[0]))
          var notExpr = newNodeIT(nkCall, n.info, getSysType(c.graph, n.info, tyBool))
          addSon(notExpr, newSymNode(c.graph.opNot, n.info))
          addSon(notExpr, inExpr)
          addSon(check, notExpr)
          return
      else: illFormedAst(it, c.config)
  of nkSym:
    if r.sym.name.id == field.id: result = r.sym
  else: illFormedAst(n, c.config)

const
  tyTypeParamsHolders = {tyGenericInst, tyCompositeTypeClass}
  tyDotOpTransparent = {tyVar, tyLent, tyPtr, tyRef, tyOwned, tyAlias, tySink}

proc readTypeParameter(c: PContext, typ: PType,
                       paramName: PIdent, info: TLineInfo): PNode =
  # Note: This function will return emptyNode when attempting to read
  # a static type parameter that is not yet resolved (e.g. this may
  # happen in proc signatures such as `proc(x: T): array[T.sizeParam, U]`
  if typ.kind in {tyUserTypeClass, tyUserTypeClassInst}:
    for statement in typ.n:
      case statement.kind
      of nkTypeSection:
        for def in statement:
          if def[0].sym.name.id == paramName.id:
            # XXX: Instead of lifting the section type to a typedesc
            # here, we could try doing it earlier in semTypeSection.
            # This seems semantically correct and then we'll be able
            # to return the section symbol directly here
            let foundType = makeTypeDesc(c, def[2].typ)
            return newSymNode(copySym(def[0].sym).linkTo(foundType), info)

      of nkConstSection:
        for def in statement:
          if def[0].sym.name.id == paramName.id:
            return def[2]

      else:
        discard

  if typ.kind != tyUserTypeClass:
    let ty = if typ.kind == tyCompositeTypeClass: typ.sons[1].skipGenericAlias
             else: typ.skipGenericAlias
    let tbody = ty.sons[0]
    for s in 0 .. tbody.len-2:
      let tParam = tbody.sons[s]
      if tParam.sym.name.id == paramName.id:
        let rawTyp = ty.sons[s + 1]
        if rawTyp.kind == tyStatic:
          if rawTyp.n != nil:
            return rawTyp.n
          else:
            return c.graph.emptyNode
        else:
          let foundTyp = makeTypeDesc(c, rawTyp)
          return newSymNode(copySym(tParam.sym).linkTo(foundTyp), info)

  return nil

proc semSym(c: PContext, n: PNode, sym: PSym, flags: TExprFlags): PNode =
  let s = getGenSym(c, sym)
  case s.kind
  of skConst:
    markUsed(c, n.info, s, c.graph.usageSym)
    onUse(n.info, s)
    let typ = skipTypes(s.typ, abstractInst-{tyTypeDesc})
    case typ.kind
    of  tyNil, tyChar, tyInt..tyInt64, tyFloat..tyFloat128,
        tyTuple, tySet, tyUInt..tyUInt64:
      if s.magic == mNone: result = inlineConst(c, n, s)
      else: result = newSymNode(s, n.info)
    of tyArray, tySequence:
      # Consider::
      #     const x = []
      #     proc p(a: openarray[int])
      #     proc q(a: openarray[char])
      #     p(x)
      #     q(x)
      #
      # It is clear that ``[]`` means two totally different things. Thus, we
      # copy `x`'s AST into each context, so that the type fixup phase can
      # deal with two different ``[]``.
      if s.ast.len == 0: result = inlineConst(c, n, s)
      else: result = newSymNode(s, n.info)
    of tyStatic:
      if typ.n != nil:
        result = typ.n
        result.typ = typ.base
      else:
        result = newSymNode(s, n.info)
    else:
      result = newSymNode(s, n.info)
  of skMacro:
    if efNoEvaluateGeneric in flags and s.ast[genericParamsPos].len > 0 or
       (n.kind notin nkCallKinds and s.requiredParams > 0):
      markUsed(c, n.info, s, c.graph.usageSym)
      onUse(n.info, s)
      result = symChoice(c, n, s, scClosed)
    else:
      result = semMacroExpr(c, n, n, s, flags)
  of skTemplate:
    if efNoEvaluateGeneric in flags and s.ast[genericParamsPos].len > 0 or
       (n.kind notin nkCallKinds and s.requiredParams > 0) or
       sfCustomPragma in sym.flags:
      let info = getCallLineInfo(n)
      markUsed(c, info, s, c.graph.usageSym)
      onUse(info, s)
      result = symChoice(c, n, s, scClosed)
    else:
      result = semTemplateExpr(c, n, s, flags)
  of skParam:
    markUsed(c, n.info, s, c.graph.usageSym)
    onUse(n.info, s)
    if s.typ != nil and s.typ.kind == tyStatic and s.typ.n != nil:
      # XXX see the hack in sigmatch.nim ...
      return s.typ.n
    elif sfGenSym in s.flags:
      # the owner should have been set by now by addParamOrResult
      internalAssert c.config, s.owner != nil
      if c.p.wasForwarded:
        # gensym'ed parameters that nevertheless have been forward declared
        # need a special fixup:
        let realParam = c.p.owner.typ.n[s.position+1]
        internalAssert c.config, realParam.kind == nkSym and realParam.sym.kind == skParam
        return newSymNode(c.p.owner.typ.n[s.position+1].sym, n.info)
      elif c.p.owner.kind == skMacro:
        # gensym'ed macro parameters need a similar hack (see bug #1944):
        var u = searchInScopes(c, s.name)
        internalAssert c.config, u != nil and u.kind == skParam and u.owner == s.owner
        return newSymNode(u, n.info)
    result = newSymNode(s, n.info)
  of skVar, skLet, skResult, skForVar:
    if s.magic == mNimvm:
      localError(c.config, n.info, "illegal context for 'nimvm' magic")

    markUsed(c, n.info, s, c.graph.usageSym)
    onUse(n.info, s)
    result = newSymNode(s, n.info)
    # We cannot check for access to outer vars for example because it's still
    # not sure the symbol really ends up being used:
    # var len = 0 # but won't be called
    # genericThatUsesLen(x) # marked as taking a closure?
  of skGenericParam:
    onUse(n.info, s)
    if s.typ.kind == tyStatic:
      result = newSymNode(s, n.info)
      result.typ = s.typ
    elif s.ast != nil:
      result = semExpr(c, s.ast)
    else:
      n.typ = s.typ
      return n
  of skType:
    markUsed(c, n.info, s, c.graph.usageSym)
    onUse(n.info, s)
    if s.typ.kind == tyStatic and s.typ.base.kind != tyNone and s.typ.n != nil:
      return s.typ.n
    result = newSymNode(s, n.info)
    result.typ = makeTypeDesc(c, s.typ)
  of skField:
    var p = c.p
    while p != nil and p.selfSym == nil:
      p = p.next
    if p != nil and p.selfSym != nil:
      var ty = skipTypes(p.selfSym.typ, {tyGenericInst, tyVar, tyLent, tyPtr, tyRef,
                                         tyAlias, tySink, tyOwned})
      while tfBorrowDot in ty.flags: ty = ty.skipTypes({tyDistinct})
      var check: PNode = nil
      if ty.kind == tyObject:
        while true:
          check = nil
          let f = lookupInRecordAndBuildCheck(c, n, ty.n, s.name, check)
          if f != nil and fieldVisible(c, f):
            # is the access to a public field or in the same module or in a friend?
            doAssert f == s
            markUsed(c, n.info, f, c.graph.usageSym)
            onUse(n.info, f)
            result = newNodeIT(nkDotExpr, n.info, f.typ)
            result.add makeDeref(newSymNode(p.selfSym))
            result.add newSymNode(f) # we now have the correct field
            if check != nil:
              check.sons[0] = result
              check.typ = result.typ
              result = check
            return result
          if ty.sons[0] == nil: break
          ty = skipTypes(ty.sons[0], skipPtrs)
    # old code, not sure if it's live code:
    markUsed(c, n.info, s, c.graph.usageSym)
    onUse(n.info, s)
    result = newSymNode(s, n.info)
  else:
    let info = getCallLineInfo(n)
    markUsed(c, info, s, c.graph.usageSym)
    onUse(info, s)
    result = newSymNode(s, info)

proc builtinFieldAccess(c: PContext, n: PNode, flags: TExprFlags): PNode =
  ## returns nil if it's not a built-in field access
  checkSonsLen(n, 2, c.config)
  # tests/bind/tbindoverload.nim wants an early exit here, but seems to
  # work without now. template/tsymchoicefield doesn't like an early exit
  # here at all!
  #if isSymChoice(n.sons[1]): return
  when defined(nimsuggest):
    if c.config.cmd == cmdIdeTools:
      suggestExpr(c, n)
      if exactEquals(c.config.m.trackPos, n[1].info): suggestExprNoCheck(c, n)

  var s = qualifiedLookUp(c, n, {checkAmbiguity, checkUndeclared, checkModule})
  if s != nil:
    if s.kind in OverloadableSyms:
      result = symChoice(c, n, s, scClosed)
      if result.kind == nkSym: result = semSym(c, n, s, flags)
    else:
      markUsed(c, n.sons[1].info, s, c.graph.usageSym)
      result = semSym(c, n, s, flags)
    onUse(n.sons[1].info, s)
    return

  n.sons[0] = semExprWithType(c, n.sons[0], flags+{efDetermineType})
  #restoreOldStyleType(n.sons[0])
  var i = considerQuotedIdent(c, n.sons[1], n)
  var ty = n.sons[0].typ
  var f: PSym = nil
  result = nil

  template tryReadingGenericParam(t: PType) =
    case t.kind
    of tyTypeParamsHolders:
      result = readTypeParameter(c, t, i, n.info)
      if result == c.graph.emptyNode:
        result = n
        n.typ = makeTypeFromExpr(c, n.copyTree)
      return
    of tyUserTypeClasses:
      if t.isResolvedUserTypeClass:
        return readTypeParameter(c, t, i, n.info)
      else:
        n.typ = makeTypeFromExpr(c, copyTree(n))
        return n
    of tyGenericParam, tyAnything:
      n.typ = makeTypeFromExpr(c, copyTree(n))
      return n
    else:
      discard

  var argIsType = false

  if ty.kind == tyTypeDesc:
    if ty.base.kind == tyNone:
      # This is a still unresolved typedesc parameter.
      # If this is a regular proc, then all bets are off and we must return
      # tyFromExpr, but when this happen in a macro this is not a built-in
      # field access and we leave the compiler to compile a normal call:
      if getCurrOwner(c).kind != skMacro:
        n.typ = makeTypeFromExpr(c, n.copyTree)
        return n
      else:
        return nil
    else:
      ty = ty.base
      argIsType = true
  else:
    argIsType = isTypeExpr(n.sons[0])

  if argIsType:
    ty = ty.skipTypes(tyDotOpTransparent)
    case ty.kind
    of tyEnum:
      # look up if the identifier belongs to the enum:
      while ty != nil:
        f = getSymFromList(ty.n, i)
        if f != nil: break
        ty = ty.sons[0]         # enum inheritance
      if f != nil:
        result = newSymNode(f)
        result.info = n.info
        result.typ = ty
        markUsed(c, n.info, f, c.graph.usageSym)
        onUse(n.info, f)
        return
    of tyObject, tyTuple:
      if ty.n != nil and ty.n.kind == nkRecList:
        let field = lookupInRecord(ty.n, i)
        if field != nil:
          n.typ = makeTypeDesc(c, field.typ)
          return n
    else:
      tryReadingGenericParam(ty)
      return
    # XXX: This is probably not relevant any more
    # reset to prevent 'nil' bug: see "tests/reject/tenumitems.nim":
    ty = n.sons[0].typ
    return nil
  if ty.kind in tyUserTypeClasses and ty.isResolvedUserTypeClass:
    ty = ty.lastSon
  ty = skipTypes(ty, {tyGenericInst, tyVar, tyLent, tyPtr, tyRef, tyOwned, tyAlias, tySink})
  while tfBorrowDot in ty.flags: ty = ty.skipTypes({tyDistinct})
  var check: PNode = nil
  if ty.kind == tyObject:
    while true:
      check = nil
      f = lookupInRecordAndBuildCheck(c, n, ty.n, i, check)
      if f != nil: break
      if ty.sons[0] == nil: break
      ty = skipTypes(ty.sons[0], skipPtrs)
    if f != nil:
      let visibilityCheckNeeded =
        if n[1].kind == nkSym and n[1].sym == f:
          false # field lookup was done already, likely by hygienic template or bindSym
        else: true
      if not visibilityCheckNeeded or fieldVisible(c, f):
        # is the access to a public field or in the same module or in a friend?
        markUsed(c, n.sons[1].info, f, c.graph.usageSym)
        onUse(n.sons[1].info, f)
        n.sons[0] = makeDeref(n.sons[0])
        n.sons[1] = newSymNode(f) # we now have the correct field
        n.typ = f.typ
        if check == nil:
          result = n
        else:
          check.sons[0] = n
          check.typ = n.typ
          result = check
  elif ty.kind == tyTuple and ty.n != nil:
    f = getSymFromList(ty.n, i)
    if f != nil:
      markUsed(c, n.sons[1].info, f, c.graph.usageSym)
      onUse(n.sons[1].info, f)
      n.sons[0] = makeDeref(n.sons[0])
      n.sons[1] = newSymNode(f)
      n.typ = f.typ
      result = n

  # we didn't find any field, let's look for a generic param
  if result == nil:
    let t = n.sons[0].typ.skipTypes(tyDotOpTransparent)
    tryReadingGenericParam(t)

proc dotTransformation(c: PContext, n: PNode): PNode =
  if isSymChoice(n.sons[1]):
    result = newNodeI(nkDotCall, n.info)
    addSon(result, n.sons[1])
    addSon(result, copyTree(n[0]))
  else:
    var i = considerQuotedIdent(c, n.sons[1], n)
    result = newNodeI(nkDotCall, n.info)
    result.flags.incl nfDotField
    addSon(result, newIdentNode(i, n[1].info))
    addSon(result, copyTree(n[0]))

proc semFieldAccess(c: PContext, n: PNode, flags: TExprFlags): PNode =
  # this is difficult, because the '.' is used in many different contexts
  # in Nim. We first allow types in the semantic checking.
  result = builtinFieldAccess(c, n, flags)
  if result == nil:
    result = dotTransformation(c, n)

proc buildOverloadedSubscripts(n: PNode, ident: PIdent): PNode =
  result = newNodeI(nkCall, n.info)
  result.add(newIdentNode(ident, n.info))
  for i in 0 .. n.len-1: result.add(n[i])

proc semDeref(c: PContext, n: PNode): PNode =
  checkSonsLen(n, 1, c.config)
  n.sons[0] = semExprWithType(c, n.sons[0])
  result = n
  var t = skipTypes(n.sons[0].typ, {tyGenericInst, tyVar, tyLent, tyAlias, tySink, tyOwned})
  case t.kind
  of tyRef, tyPtr: n.typ = t.lastSon
  else: result = nil
  #GlobalError(n.sons[0].info, errCircumNeedsPointer)

proc semSubscript(c: PContext, n: PNode, flags: TExprFlags): PNode =
  ## returns nil if not a built-in subscript operator; also called for the
  ## checking of assignments
  if sonsLen(n) == 1:
    let x = semDeref(c, n)
    if x == nil: return nil
    result = newNodeIT(nkDerefExpr, x.info, x.typ)
    result.add(x[0])
    return
  checkMinSonsLen(n, 2, c.config)
  # make sure we don't evaluate generic macros/templates
  n.sons[0] = semExprWithType(c, n.sons[0],
                              {efNoEvaluateGeneric})
  var arr = skipTypes(n.sons[0].typ, {tyGenericInst, tyUserTypeClassInst, tyOwned,
                                      tyVar, tyLent, tyPtr, tyRef, tyAlias, tySink})
  if arr.kind == tyStatic:
    if arr.base.kind == tyNone:
      result = n
      result.typ = semStaticType(c, n[1], nil)
      return
    elif arr.n != nil:
      return semSubscript(c, arr.n, flags)
    else:
      arr = arr.base

  case arr.kind
  of tyArray, tyOpenArray, tyVarargs, tySequence, tyString, tyCString,
    tyUncheckedArray:
    if n.len != 2: return nil
    n.sons[0] = makeDeref(n.sons[0])
    for i in 1 ..< sonsLen(n):
      n.sons[i] = semExprWithType(c, n.sons[i],
                                  flags*{efInTypeof, efDetermineType})
    # Arrays index type is dictated by the range's type
    if arr.kind == tyArray:
      var indexType = arr.sons[0]
      var arg = indexTypesMatch(c, indexType, n.sons[1].typ, n.sons[1])
      if arg != nil:
        n.sons[1] = arg
        result = n
        result.typ = elemType(arr)
    # Other types have a bit more of leeway
    elif n.sons[1].typ.skipTypes(abstractRange-{tyDistinct}).kind in
        {tyInt..tyInt64, tyUInt..tyUInt64}:
      result = n
      result.typ = elemType(arr)
  of tyTypeDesc:
    # The result so far is a tyTypeDesc bound
    # a tyGenericBody. The line below will substitute
    # it with the instantiated type.
    result = n
    result.typ = makeTypeDesc(c, semTypeNode(c, n, nil))
    #result = symNodeFromType(c, semTypeNode(c, n, nil), n.info)
  of tyTuple:
    if n.len != 2: return nil
    n.sons[0] = makeDeref(n.sons[0])
    # [] operator for tuples requires constant expression:
    n.sons[1] = semConstExpr(c, n.sons[1])
    if skipTypes(n.sons[1].typ, {tyGenericInst, tyRange, tyOrdinal, tyAlias, tySink}).kind in
        {tyInt..tyInt64}:
      let idx = getOrdValue(n.sons[1])
      if idx >= 0 and idx < len(arr): n.typ = arr.sons[int(idx)]
      else: localError(c.config, n.info, "invalid index value for tuple subscript")
      result = n
    else:
      result = nil
  else:
    let s = if n.sons[0].kind == nkSym: n.sons[0].sym
            elif n[0].kind in nkSymChoices: n.sons[0][0].sym
            else: nil
    if s != nil:
      case s.kind
      of skProc, skFunc, skMethod, skConverter, skIterator:
        # type parameters: partial generic specialization
        n.sons[0] = semSymGenericInstantiation(c, n.sons[0], s)
        result = explicitGenericInstantiation(c, n, s)
        if result == n:
          n.sons[0] = copyTree(result)
        else:
          n.sons[0] = result
      of skMacro, skTemplate:
        if efInCall in flags:
          # We are processing macroOrTmpl[] in macroOrTmpl[](...) call.
          # Return as is, so it can be transformed into complete macro or
          # template call in semIndirectOp caller.
          result = n
        else:
          # We are processing macroOrTmpl[] not in call. Transform it to the
          # macro or template call with generic arguments here.
          n.kind = nkCall
          case s.kind
          of skMacro: result = semMacroExpr(c, n, n, s, flags)
          of skTemplate: result = semTemplateExpr(c, n, s, flags)
          else: discard
      of skType:
        result = symNodeFromType(c, semTypeNode(c, n, nil), n.info)
      else:
        discard

proc semArrayAccess(c: PContext, n: PNode, flags: TExprFlags): PNode =
  result = semSubscript(c, n, flags)
  if result == nil:
    # overloaded [] operator:
    result = semExpr(c, buildOverloadedSubscripts(n, getIdent(c.cache, "[]")))

proc propertyWriteAccess(c: PContext, n, nOrig, a: PNode): PNode =
  var id = considerQuotedIdent(c, a[1], a)
  var setterId = newIdentNode(getIdent(c.cache, id.s & '='), n.info)
  # a[0] is already checked for semantics, that does ``builtinFieldAccess``
  # this is ugly. XXX Semantic checking should use the ``nfSem`` flag for
  # nodes?
  let aOrig = nOrig[0]
  result = newNode(nkCall, n.info, sons = @[setterId, a[0],
                                            semExprWithType(c, n[1])])
  result.flags.incl nfDotSetter
  let orig = newNode(nkCall, n.info, sons = @[setterId, aOrig[0], nOrig[1]])
  result = semOverloadedCallAnalyseEffects(c, result, orig, {})

  if result != nil:
    result = afterCallActions(c, result, nOrig, {})
    #fixAbstractType(c, result)
    #analyseIfAddressTakenInCall(c, result)

proc takeImplicitAddr(c: PContext, n: PNode; isLent: bool): PNode =
  # See RFC #7373, calls returning 'var T' are assumed to
  # return a view into the first argument (if there is one):
  let root = exprRoot(n)
  if root != nil and root.owner == c.p.owner:
    if root.kind in {skLet, skVar, skTemp} and sfGlobal notin root.flags:
      localError(c.config, n.info, "'$1' escapes its stack frame; context: '$2'; see $3/var_t_return.html" % [
        root.name.s, renderTree(n, {renderNoComments}), explanationsBaseUrl])
    elif root.kind == skParam and root.position != 0:
      localError(c.config, n.info, "'$1' is not the first parameter; context: '$2'; see $3/var_t_return.html" % [
        root.name.s, renderTree(n, {renderNoComments}), explanationsBaseUrl])
  case n.kind
  of nkHiddenAddr, nkAddr: return n
  of nkHiddenDeref, nkDerefExpr: return n.sons[0]
  of nkBracketExpr:
    if len(n) == 1: return n.sons[0]
  else: discard
  let valid = isAssignable(c, n)
  if valid != arLValue:
    if valid == arLocalLValue:
      localError(c.config, n.info, errXStackEscape % renderTree(n, {renderNoComments}))
    elif not isLent:
      localError(c.config, n.info, errExprHasNoAddress)
  result = newNodeIT(nkHiddenAddr, n.info, makePtrType(c, n.typ))
  result.add(n)

proc asgnToResultVar(c: PContext, n, le, ri: PNode) {.inline.} =
  if le.kind == nkHiddenDeref:
    var x = le.sons[0]
    if x.typ.kind in {tyVar, tyLent} and x.kind == nkSym and x.sym.kind == skResult:
      n.sons[0] = x # 'result[]' --> 'result'
      n.sons[1] = takeImplicitAddr(c, ri, x.typ.kind == tyLent)
      x.typ.flags.incl tfVarIsPtr
      #echo x.info, " setting it for this type ", typeToString(x.typ), " ", n.info

proc borrowCheck(c: PContext, n, le, ri: PNode) =
  const
    PathKinds0 = {nkDotExpr, nkCheckedFieldExpr,
                  nkBracketExpr, nkAddr, nkHiddenAddr,
                  nkObjDownConv, nkObjUpConv}
    PathKinds1 = {nkHiddenStdConv, nkHiddenSubConv}

  proc getRoot(n: PNode; followDeref: bool): PNode =
    result = n
    while true:
      case result.kind
      of nkDerefExpr, nkHiddenDeref:
        if followDeref: result = result[0]
        else: break
      of PathKinds0:
        result = result[0]
      of PathKinds1:
        result = result[1]
      else: break

  proc scopedLifetime(c: PContext; ri: PNode): bool {.inline.} =
    let n = getRoot(ri, followDeref = false)
    result = (ri.kind in nkCallKinds+{nkObjConstr}) or
      (n.kind == nkSym and n.sym.owner == c.p.owner)

  proc escapes(c: PContext; le: PNode): bool {.inline.} =
    # param[].foo[] = self  definitely escapes, we don't need to
    # care about pointer derefs:
    let n = getRoot(le, followDeref = true)
    result = n.kind == nkSym and n.sym.kind == skParam

  # Special typing rule: do not allow to pass 'owned T' to 'T' in 'result = x':
  const absInst = abstractInst - {tyOwned}
  if ri.typ != nil and ri.typ.skipTypes(absInst).kind == tyOwned and
      le.typ != nil and le.typ.skipTypes(absInst).kind != tyOwned and
      scopedLifetime(c, ri):
    if le.kind == nkSym and le.sym.kind == skResult:
      localError(c.config, n.info, "cannot return an owned pointer as an unowned pointer; " &
        "use 'owned(" & typeToString(le.typ) & ")' as the return type")
    elif escapes(c, le):
      localError(c.config, n.info,
        "assignment produces a dangling ref: the unowned ref lives longer than the owned ref")

template resultTypeIsInferrable(typ: PType): untyped =
  typ.isMetaType and typ.kind != tyTypeDesc

proc goodLineInfo(arg: PNode): TLineInfo =
  if arg.kind == nkStmtListExpr and arg.len > 0:
    goodLineInfo(arg[^1])
  else:
    arg.info

proc semAsgn(c: PContext, n: PNode; mode=asgnNormal): PNode =
  checkSonsLen(n, 2, c.config)
  var a = n.sons[0]
  case a.kind
  of nkDotExpr:
    # r.f = x
    # --> `f=` (r, x)
    let nOrig = n.copyTree
    a = builtinFieldAccess(c, a, {efLValue})
    if a == nil:
      a = propertyWriteAccess(c, n, nOrig, n[0])
      if a != nil: return a
      # we try without the '='; proc that return 'var' or macros are still
      # possible:
      a = dotTransformation(c, n[0])
      if a.kind == nkDotCall:
        a.kind = nkCall
        a = semExprWithType(c, a, {efLValue})
  of nkBracketExpr:
    # a[i] = x
    # --> `[]=`(a, i, x)
    a = semSubscript(c, a, {efLValue})
    if a == nil:
      result = buildOverloadedSubscripts(n.sons[0], getIdent(c.cache, "[]="))
      add(result, n[1])
      if mode == noOverloadedSubscript:
        bracketNotFoundError(c, result)
        return n
      else:
        result = semExprNoType(c, result)
        return result
  of nkCurlyExpr:
    # a{i} = x -->  `{}=`(a, i, x)
    result = buildOverloadedSubscripts(n.sons[0], getIdent(c.cache, "{}="))
    add(result, n[1])
    return semExprNoType(c, result)
  of nkPar, nkTupleConstr:
    if a.len >= 2:
      # unfortunately we need to rewrite ``(x, y) = foo()`` already here so
      # that overloading of the assignment operator still works. Usually we
      # prefer to do these rewritings in transf.nim:
      return semStmt(c, lowerTupleUnpackingForAsgn(c.graph, n, c.p.owner), {})
    else:
      a = semExprWithType(c, a, {efLValue})
  else:
    a = semExprWithType(c, a, {efLValue})
  n.sons[0] = a
  # a = b # both are vars, means: a[] = b[]
  # a = b # b no 'var T' means: a = addr(b)
  var le = a.typ
  if le == nil:
    localError(c.config, a.info, "expression has no type")
  elif (skipTypes(le, {tyGenericInst, tyAlias, tySink}).kind != tyVar and
        isAssignable(c, a) == arNone) or
      skipTypes(le, abstractVar).kind in {tyOpenArray, tyVarargs}:
    # Direct assignment to a discriminant is allowed!
    localError(c.config, a.info, errXCannotBeAssignedTo %
               renderTree(a, {renderNoComments}))
  else:
    let
      lhs = n.sons[0]
      lhsIsResult = lhs.kind == nkSym and lhs.sym.kind == skResult
    var
      rhs = semExprWithType(c, n.sons[1],
        if lhsIsResult: {efAllowDestructor} else: {})
    if lhsIsResult:
      n.typ = c.enforceVoidContext
      if c.p.owner.kind != skMacro and resultTypeIsInferrable(lhs.sym.typ):
        var rhsTyp = rhs.typ
        if rhsTyp.kind in tyUserTypeClasses and rhsTyp.isResolvedUserTypeClass:
          rhsTyp = rhsTyp.lastSon
        if cmpTypes(c, lhs.typ, rhsTyp) in {isGeneric, isEqual}:
          internalAssert c.config, c.p.resultSym != nil
          # Make sure the type is valid for the result variable
          typeAllowedCheck(c.config, n.info, rhsTyp, skResult)
          lhs.typ = rhsTyp
          c.p.resultSym.typ = rhsTyp
          c.p.owner.typ.sons[0] = rhsTyp
        else:
          typeMismatch(c.config, n.info, lhs.typ, rhsTyp)
    borrowCheck(c, n, lhs, rhs)

    n.sons[1] = fitNode(c, le, rhs, goodLineInfo(n[1]))
    when false: liftTypeBoundOps(c, lhs.typ, lhs.info)

    fixAbstractType(c, n)
    asgnToResultVar(c, n, n.sons[0], n.sons[1])
  result = n

proc semReturn(c: PContext, n: PNode): PNode =
  result = n
  checkSonsLen(n, 1, c.config)
  if c.p.owner.kind in {skConverter, skMethod, skProc, skFunc, skMacro} or
      isClosureIterator(c.p.owner):
    if n.sons[0].kind != nkEmpty:
      # transform ``return expr`` to ``result = expr; return``
      if c.p.resultSym != nil:
        var a = newNodeI(nkAsgn, n.sons[0].info)
        addSon(a, newSymNode(c.p.resultSym))
        addSon(a, n.sons[0])
        n.sons[0] = semAsgn(c, a)
        # optimize away ``result = result``:
        if n[0][1].kind == nkSym and n[0][1].sym == c.p.resultSym:
          n.sons[0] = c.graph.emptyNode
      else:
        localError(c.config, n.info, errNoReturnTypeDeclared)
  else:
    localError(c.config, n.info, "'return' not allowed here")

proc semProcBody(c: PContext, n: PNode): PNode =
  openScope(c)
  result = semExpr(c, n)
  if c.p.resultSym != nil and not isEmptyType(result.typ):
    if result.kind == nkNilLit:
      # or ImplicitlyDiscardable(result):
      # new semantic: 'result = x' triggers the void context
      result.typ = nil
    elif result.kind == nkStmtListExpr and result.typ.kind == tyNil:
      # to keep backwards compatibility bodies like:
      #   nil
      #   # comment
      # are not expressions:
      fixNilType(c, result)
    else:
      var a = newNodeI(nkAsgn, n.info, 2)
      a.sons[0] = newSymNode(c.p.resultSym)
      a.sons[1] = result
      result = semAsgn(c, a)
  else:
    discardCheck(c, result, {})

  if c.p.owner.kind notin {skMacro, skTemplate} and
     c.p.resultSym != nil and c.p.resultSym.typ.isMetaType:
    if isEmptyType(result.typ):
      # we inferred a 'void' return type:
      c.p.resultSym.typ = errorType(c)
      c.p.owner.typ.sons[0] = nil
    else:
      localError(c.config, c.p.resultSym.info, errCannotInferReturnType %
        c.p.owner.name.s)
  if isInlineIterator(c.p.owner) and c.p.owner.typ.sons[0] != nil and
      c.p.owner.typ.sons[0].kind == tyUntyped:
    localError(c.config, c.p.owner.info, errCannotInferReturnType %
      c.p.owner.name.s)
  closeScope(c)

proc semYieldVarResult(c: PContext, n: PNode, restype: PType) =
  var t = skipTypes(restype, {tyGenericInst, tyAlias, tySink})
  case t.kind
  of tyVar, tyLent:
    if t.kind == tyVar: t.flags.incl tfVarIsPtr # bugfix for #4048, #4910, #6892
    if n.sons[0].kind in {nkHiddenStdConv, nkHiddenSubConv}:
      n.sons[0] = n.sons[0].sons[1]
    n.sons[0] = takeImplicitAddr(c, n.sons[0], t.kind == tyLent)
  of tyTuple:
    for i in 0..<t.sonsLen:
      var e = skipTypes(t.sons[i], {tyGenericInst, tyAlias, tySink})
      if e.kind in {tyVar, tyLent}:
        if e.kind == tyVar: e.flags.incl tfVarIsPtr # bugfix for #4048, #4910, #6892
        if n.sons[0].kind in {nkPar, nkTupleConstr}:
          n.sons[0].sons[i] = takeImplicitAddr(c, n.sons[0].sons[i], e.kind == tyLent)
        elif n.sons[0].kind in {nkHiddenStdConv, nkHiddenSubConv} and
             n.sons[0].sons[1].kind in {nkPar, nkTupleConstr}:
          var a = n.sons[0].sons[1]
          a.sons[i] = takeImplicitAddr(c, a.sons[i], false)
        else:
          localError(c.config, n.sons[0].info, errXExpected, "tuple constructor")
  else: discard

proc semYield(c: PContext, n: PNode): PNode =
  result = n
  checkSonsLen(n, 1, c.config)
  if c.p.owner == nil or c.p.owner.kind != skIterator:
    localError(c.config, n.info, errYieldNotAllowedHere)
  elif n.sons[0].kind != nkEmpty:
    n.sons[0] = semExprWithType(c, n.sons[0]) # check for type compatibility:
    var iterType = c.p.owner.typ
    let restype = iterType.sons[0]
    if restype != nil:
      if restype.kind != tyUntyped:
        n.sons[0] = fitNode(c, restype, n.sons[0], n.info)
      if n.sons[0].typ == nil: internalError(c.config, n.info, "semYield")

      if resultTypeIsInferrable(restype):
        let inferred = n.sons[0].typ
        iterType.sons[0] = inferred
        if c.p.resultSym != nil:
          c.p.resultSym.typ = inferred

      semYieldVarResult(c, n, restype)
    else:
      localError(c.config, n.info, errCannotReturnExpr)
  elif c.p.owner.typ.sons[0] != nil:
    localError(c.config, n.info, errGenerated, "yield statement must yield a value")

proc lookUpForDefined(c: PContext, i: PIdent, onlyCurrentScope: bool): PSym =
  if onlyCurrentScope:
    result = localSearchInScope(c, i)
  else:
    result = searchInScopes(c, i) # no need for stub loading

proc lookUpForDefined(c: PContext, n: PNode, onlyCurrentScope: bool): PSym =
  case n.kind
  of nkIdent:
    result = lookUpForDefined(c, n.ident, onlyCurrentScope)
  of nkDotExpr:
    result = nil
    if onlyCurrentScope: return
    checkSonsLen(n, 2, c.config)
    var m = lookUpForDefined(c, n.sons[0], onlyCurrentScope)
    if m != nil and m.kind == skModule:
      let ident = considerQuotedIdent(c, n[1], n)
      if m == c.module:
        result = strTableGet(c.topLevelScope.symbols, ident)
      else:
        result = strTableGet(m.tab, ident)
  of nkAccQuoted:
    result = lookUpForDefined(c, considerQuotedIdent(c, n), onlyCurrentScope)
  of nkSym:
    result = n.sym
  of nkOpenSymChoice, nkClosedSymChoice:
    result = n.sons[0].sym
  else:
    localError(c.config, n.info, "identifier expected, but got: " & renderTree(n))
    result = nil

proc semDefined(c: PContext, n: PNode, onlyCurrentScope: bool): PNode =
  checkSonsLen(n, 2, c.config)
  # we replace this node by a 'true' or 'false' node:
  result = newIntNode(nkIntLit, 0)
  if not onlyCurrentScope and considerQuotedIdent(c, n[0], n).s == "defined":
    let d = considerQuotedIdent(c, n[1], n)
    result.intVal = ord isDefined(c.config, d.s)
  elif lookUpForDefined(c, n.sons[1], onlyCurrentScope) != nil:
    result.intVal = 1
  result.info = n.info
  result.typ = getSysType(c.graph, n.info, tyBool)

proc expectMacroOrTemplateCall(c: PContext, n: PNode): PSym =
  ## The argument to the proc should be nkCall(...) or similar
  ## Returns the macro/template symbol
  if isCallExpr(n):
    var expandedSym = qualifiedLookUp(c, n[0], {checkUndeclared})
    if expandedSym == nil:
      errorUndeclaredIdentifier(c, n.info, n[0].renderTree)
      return errorSym(c, n[0])

    if expandedSym.kind notin {skMacro, skTemplate}:
      localError(c.config, n.info, "'$1' is not a macro or template" % expandedSym.name.s)
      return errorSym(c, n[0])

    result = expandedSym
  else:
    localError(c.config, n.info, "'$1' is not a macro or template" % n.renderTree)
    result = errorSym(c, n)

proc expectString(c: PContext, n: PNode): string =
  var n = semConstExpr(c, n)
  if n.kind in nkStrKinds:
    return n.strVal
  else:
    localError(c.config, n.info, errStringLiteralExpected)

proc newAnonSym(c: PContext; kind: TSymKind, info: TLineInfo): PSym =
  result = newSym(kind, c.cache.idAnon, getCurrOwner(c), info)
  result.flags = {sfGenSym}

proc semExpandToAst(c: PContext, n: PNode): PNode =
  let macroCall = n[1]

  when false:
    let expandedSym = expectMacroOrTemplateCall(c, macroCall)
    if expandedSym.kind == skError: return n

    macroCall.sons[0] = newSymNode(expandedSym, macroCall.info)
    markUsed(c, n.info, expandedSym, c.graph.usageSym)
    onUse(n.info, expandedSym)

  if isCallExpr(macroCall):
    for i in 1 ..< macroCall.len:
      #if macroCall.sons[0].typ.sons[i].kind != tyUntyped:
      macroCall.sons[i] = semExprWithType(c, macroCall[i], {})
    # performing overloading resolution here produces too serious regressions:
    let headSymbol = macroCall[0]
    var cands = 0
    var cand: PSym = nil
    var o: TOverloadIter
    var symx = initOverloadIter(o, c, headSymbol)
    while symx != nil:
      if symx.kind in {skTemplate, skMacro} and symx.typ.len == macroCall.len:
        cand = symx
        inc cands
      symx = nextOverloadIter(o, c, headSymbol)
    if cands == 0:
      localError(c.config, n.info, "expected a template that takes " & $(macroCall.len-1) & " arguments")
    elif cands >= 2:
      localError(c.config, n.info, "ambiguous symbol in 'getAst' context: " & $macroCall)
    else:
      let info = macroCall.sons[0].info
      macroCall.sons[0] = newSymNode(cand, info)
      markUsed(c, info, cand, c.graph.usageSym)
      onUse(info, cand)

    # we just perform overloading resolution here:
    #n.sons[1] = semOverloadedCall(c, macroCall, macroCall, {skTemplate, skMacro})
  else:
    localError(c.config, n.info, "getAst takes a call, but got " & n.renderTree)
  # Preserve the magic symbol in order to be handled in evals.nim
  internalAssert c.config, n.sons[0].sym.magic == mExpandToAst
  #n.typ = getSysSym("NimNode").typ # expandedSym.getReturnType
  if n.kind == nkStmtList and n.len == 1: result = n[0]
  else: result = n
  result.typ = sysTypeFromName(c.graph, n.info, "NimNode")

proc semExpandToAst(c: PContext, n: PNode, magicSym: PSym,
                    flags: TExprFlags = {}): PNode =
  if sonsLen(n) == 2:
    n.sons[0] = newSymNode(magicSym, n.info)
    result = semExpandToAst(c, n)
  else:
    result = semDirectOp(c, n, flags)

proc processQuotations(c: PContext; n: var PNode, op: string,
                       quotes: var seq[PNode],
                       ids: var seq[PNode]) =
  template returnQuote(q) =
    quotes.add q
    n = newIdentNode(getIdent(c.cache, $quotes.len), n.info)
    ids.add n
    return


  if n.kind == nkPrefix:
    checkSonsLen(n, 2, c.config)
    if n[0].kind == nkIdent:
      var examinedOp = n[0].ident.s
      if examinedOp == op:
        returnQuote n[1]
      elif examinedOp.startsWith(op):
        n.sons[0] = newIdentNode(getIdent(c.cache, examinedOp.substr(op.len)), n.info)
  elif n.kind == nkAccQuoted and op == "``":
    returnQuote n[0]
  elif n.kind == nkIdent:
    if n.ident.s == "result":
      n = ids[0]

  for i in 0 ..< n.safeLen:
    processQuotations(c, n.sons[i], op, quotes, ids)

proc semQuoteAst(c: PContext, n: PNode): PNode =
  if n.len != 2 and n.len != 3:
    localError(c.config, n.info, "'quote' expects 1 or 2 arguments")
    return n
  # We transform the do block into a template with a param for
  # each interpolation. We'll pass this template to getAst.
  var
    quotedBlock = n[^1]
    op = if n.len == 3: expectString(c, n[1]) else: "``"
    quotes = newSeq[PNode](2)
      # the quotes will be added to a nkCall statement
      # leave some room for the callee symbol and the result symbol
    ids = newSeq[PNode](1)
      # this will store the generated param names
      # leave some room for the result symbol

  if quotedBlock.kind != nkStmtList:
    localError(c.config, n.info, errXExpected, "block")

  # This adds a default first field to pass the result symbol
  ids[0] = newAnonSym(c, skParam, n.info).newSymNode
  processQuotations(c, quotedBlock, op, quotes, ids)

  var dummyTemplate = newProcNode(
    nkTemplateDef, quotedBlock.info, body = quotedBlock,
    params = c.graph.emptyNode,
    name = newAnonSym(c, skTemplate, n.info).newSymNode,
              pattern = c.graph.emptyNode, genericParams = c.graph.emptyNode,
              pragmas = c.graph.emptyNode, exceptions = c.graph.emptyNode)

  if ids.len > 0:
    dummyTemplate.sons[paramsPos] = newNodeI(nkFormalParams, n.info)
    dummyTemplate[paramsPos].add getSysSym(c.graph, n.info, "untyped").newSymNode # return type
    ids.add getSysSym(c.graph, n.info, "untyped").newSymNode # params type
    ids.add c.graph.emptyNode # no default value
    dummyTemplate[paramsPos].add newNode(nkIdentDefs, n.info, ids)

  var tmpl = semTemplateDef(c, dummyTemplate)
  quotes[0] = tmpl[namePos]
  # This adds a call to newIdentNode("result") as the first argument to the template call
  quotes[1] = newNode(nkCall, n.info, @[newIdentNode(getIdent(c.cache, "newIdentNode"), n.info), newStrNode(nkStrLit, "result")])
  result = newNode(nkCall, n.info, @[
     createMagic(c.graph, "getAst", mExpandToAst).newSymNode,
    newNode(nkCall, n.info, quotes)])
  result = semExpandToAst(c, result)

proc tryExpr(c: PContext, n: PNode, flags: TExprFlags = {}): PNode =
  # watch out, hacks ahead:
  let oldErrorCount = c.config.errorCounter
  let oldErrorMax = c.config.errorMax
  let oldCompilesId = c.compilesContextId
  # if this is a nested 'when compiles', do not increase the ID so that
  # generic instantations can still be cached for this level.
  if c.compilesContextId == 0:
    inc c.compilesContextIdGenerator
    c.compilesContextId = c.compilesContextIdGenerator
  # do not halt after first error:
  c.config.errorMax = high(int)

  # open a scope for temporary symbol inclusions:
  let oldScope = c.currentScope
  openScope(c)
  let oldOwnerLen = len(c.graph.owners)
  let oldGenerics = c.generics
  let oldErrorOutputs = c.config.m.errorOutputs
  if efExplain notin flags: c.config.m.errorOutputs = {}
  let oldContextLen = msgs.getInfoContextLen(c.config)

  let oldInGenericContext = c.inGenericContext
  let oldInUnrolledContext = c.inUnrolledContext
  let oldInGenericInst = c.inGenericInst
  let oldInStaticContext = c.inStaticContext
  let oldProcCon = c.p
  c.generics = @[]
  var err: string
  try:
    result = semExpr(c, n, flags)
    if c.config.errorCounter != oldErrorCount: result = nil
  except ERecoverableError:
    discard
  # undo symbol table changes (as far as it's possible):
  c.compilesContextId = oldCompilesId
  c.generics = oldGenerics
  c.inGenericContext = oldInGenericContext
  c.inUnrolledContext = oldInUnrolledContext
  c.inGenericInst = oldInGenericInst
  c.inStaticContext = oldInStaticContext
  c.p = oldProcCon
  msgs.setInfoContextLen(c.config, oldContextLen)
  setLen(c.graph.owners, oldOwnerLen)
  c.currentScope = oldScope
  c.config.m.errorOutputs = oldErrorOutputs
  c.config.errorCounter = oldErrorCount
  c.config.errorMax = oldErrorMax

proc semCompiles(c: PContext, n: PNode, flags: TExprFlags): PNode =
  # we replace this node by a 'true' or 'false' node:
  if sonsLen(n) != 2: return semDirectOp(c, n, flags)

  result = newIntNode(nkIntLit, ord(tryExpr(c, n[1], flags) != nil))
  result.info = n.info
  result.typ = getSysType(c.graph, n.info, tyBool)

proc semShallowCopy(c: PContext, n: PNode, flags: TExprFlags): PNode =
  if sonsLen(n) == 3:
    # XXX ugh this is really a hack: shallowCopy() can be overloaded only
    # with procs that take not 2 parameters:
    result = newNodeI(nkFastAsgn, n.info)
    result.add(n[1])
    result.add(n[2])
    result = semAsgn(c, result)
  else:
    result = semDirectOp(c, n, flags)

proc createFlowVar(c: PContext; t: PType; info: TLineInfo): PType =
  result = newType(tyGenericInvocation, c.module)
  addSonSkipIntLit(result, magicsys.getCompilerProc(c.graph, "FlowVar").typ)
  addSonSkipIntLit(result, t)
  result = instGenericContainer(c, info, result, allowMetaTypes = false)

proc instantiateCreateFlowVarCall(c: PContext; t: PType;
                                  info: TLineInfo): PSym =
  let sym = magicsys.getCompilerProc(c.graph, "nimCreateFlowVar")
  if sym == nil:
    localError(c.config, info, "system needs: nimCreateFlowVar")
  var bindings: TIdTable
  initIdTable(bindings)
  bindings.idTablePut(sym.ast[genericParamsPos].sons[0].typ, t)
  result = c.semGenerateInstance(c, sym, bindings, info)
  # since it's an instantiation, we unmark it as a compilerproc. Otherwise
  # codegen would fail:
  if sfCompilerProc in result.flags:
    result.flags = result.flags - {sfCompilerProc, sfExportc, sfImportc}
    result.loc.r = nil

proc setMs(n: PNode, s: PSym): PNode =
  result = n
  n.sons[0] = newSymNode(s)
  n.sons[0].info = n.info

proc semSizeof(c: PContext, n: PNode): PNode =
  if sonsLen(n) != 2:
    localError(c.config, n.info, errXExpectsTypeOrValue % "sizeof")
  else:
    n.sons[1] = semExprWithType(c, n.sons[1], {efDetermineType})
    #restoreOldStyleType(n.sons[1])
  n.typ = getSysType(c.graph, n.info, tyInt)
  result = foldSizeOf(c.config, n, n)

proc semMagic(c: PContext, n: PNode, s: PSym, flags: TExprFlags): PNode =
  # this is a hotspot in the compiler!
  result = n
  case s.magic # magics that need special treatment
  of mAddr:
    checkSonsLen(n, 2, c.config)
    result[0] = newSymNode(s, n[0].info)
    result[1] = semAddrArg(c, n.sons[1], s.name.s == "unsafeAddr")
    result.typ = makePtrType(c, result[1].typ)
  of mTypeOf:
    result = semTypeOf(c, n)
  #of mArrGet: result = semArrGet(c, n, flags)
  #of mArrPut: result = semArrPut(c, n, flags)
  #of mAsgn: result = semAsgnOpr(c, n)
  of mDefined: result = semDefined(c, setMs(n, s), false)
  of mDefinedInScope: result = semDefined(c, setMs(n, s), true)
  of mCompiles: result = semCompiles(c, setMs(n, s), flags)
  #of mLow: result = semLowHigh(c, setMs(n, s), mLow)
  #of mHigh: result = semLowHigh(c, setMs(n, s), mHigh)
  of mIs: result = semIs(c, setMs(n, s), flags)
  #of mOf: result = semOf(c, setMs(n, s))
  of mShallowCopy: result = semShallowCopy(c, n, flags)
  of mExpandToAst: result = semExpandToAst(c, n, s, flags)
  of mQuoteAst: result = semQuoteAst(c, n)
  of mAstToStr:
    checkSonsLen(n, 2, c.config)
    result = newStrNodeT(renderTree(n[1], {renderNoComments}), n, c.graph)
    result.typ = getSysType(c.graph, n.info, tyString)
  of mParallel:
    if parallel notin c.features:
      localError(c.config, n.info, "use the {.experimental.} pragma to enable 'parallel'")
    result = setMs(n, s)
    var x = n.lastSon
    if x.kind == nkDo: x = x.sons[bodyPos]
    inc c.inParallelStmt
    result.sons[1] = semStmt(c, x, {})
    dec c.inParallelStmt
  of mSpawn:
    when defined(leanCompiler):
      localError(c.config, n.info, "compiler was built without 'spawn' support")
      result = n
    else:
      result = setMs(n, s)
      for i in 1 ..< n.len:
        result.sons[i] = semExpr(c, n.sons[i])
      let typ = result[^1].typ
      if not typ.isEmptyType:
        if spawnResult(typ, c.inParallelStmt > 0) == srFlowVar:
          result.typ = createFlowVar(c, typ, n.info)
        else:
          result.typ = typ
        result.add instantiateCreateFlowVarCall(c, typ, n.info).newSymNode
      else:
        result.add c.graph.emptyNode
  of mProcCall:
    result = setMs(n, s)
    result.sons[1] = semExpr(c, n.sons[1])
    result.typ = n[1].typ
  of mPlugin:
    # semDirectOp with conditional 'afterCallActions':
    let nOrig = n.copyTree
    #semLazyOpAux(c, n)
    result = semOverloadedCallAnalyseEffects(c, n, nOrig, flags)
    if result == nil:
      result = errorNode(c, n)
    else:
      let callee = result.sons[0].sym
      if callee.magic == mNone:
        semFinishOperands(c, result)
      activate(c, result)
      fixAbstractType(c, result)
      analyseIfAddressTakenInCall(c, result)
      if callee.magic != mNone:
        result = magicsAfterOverloadResolution(c, result, flags)
  of mRunnableExamples:
    if c.config.cmd == cmdDoc and n.len >= 2 and n.lastSon.kind == nkStmtList:
      when false:
        # some of this dead code was moved to `prepareExamples`
        if sfMainModule in c.module.flags:
          let inp = toFullPath(c.config, c.module.info)
          if c.runnableExamples == nil:
            c.runnableExamples = newTree(nkStmtList,
              newTree(nkImportStmt, newStrNode(nkStrLit, expandFilename(inp))))
          let imports = newTree(nkStmtList)
          var savedLastSon = copyTree n.lastSon
          extractImports(savedLastSon, imports)
          for imp in imports: c.runnableExamples.add imp
          c.runnableExamples.add newTree(nkBlockStmt, c.graph.emptyNode, copyTree savedLastSon)
      result = setMs(n, s)
    else:
      result = c.graph.emptyNode
  of mSizeOf: result =
    semSizeof(c, setMs(n, s))
  else:
    result = semDirectOp(c, n, flags)

proc semWhen(c: PContext, n: PNode, semCheck = true): PNode =
  # If semCheck is set to false, ``when`` will return the verbatim AST of
  # the correct branch. Otherwise the AST will be passed through semStmt.
  result = nil

  template setResult(e: untyped) =
    if semCheck: result = semExpr(c, e) # do not open a new scope!
    else: result = e

  # Check if the node is "when nimvm"
  # when nimvm:
  #   ...
  # else:
  #   ...
  var whenNimvm = false
  var typ = commonTypeBegin
  if n.sons.len == 2 and n.sons[0].kind == nkElifBranch and
      n.sons[1].kind == nkElse:
    let exprNode = n.sons[0].sons[0]
    if exprNode.kind == nkIdent:
      whenNimvm = lookUp(c, exprNode).magic == mNimvm
    elif exprNode.kind == nkSym:
      whenNimvm = exprNode.sym.magic == mNimvm
    if whenNimvm: n.flags.incl nfLL

  for i in 0 ..< sonsLen(n):
    var it = n.sons[i]
    case it.kind
    of nkElifBranch, nkElifExpr:
      checkSonsLen(it, 2, c.config)
      if whenNimvm:
        if semCheck:
          it.sons[1] = semExpr(c, it.sons[1])
          typ = commonType(typ, it.sons[1].typ)
        result = n # when nimvm is not elimited until codegen
      else:
        let e = forceBool(c, semConstExpr(c, it.sons[0]))
        if e.kind != nkIntLit:
          # can happen for cascading errors, assume false
          # InternalError(n.info, "semWhen")
          discard
        elif e.intVal != 0 and result == nil:
          setResult(it.sons[1])
    of nkElse, nkElseExpr:
      checkSonsLen(it, 1, c.config)
      if result == nil or whenNimvm:
        if semCheck:
          it.sons[0] = semExpr(c, it.sons[0])
          typ = commonType(typ, it.sons[0].typ)
        if result == nil:
          result = it.sons[0]
    else: illFormedAst(n, c.config)
  if result == nil:
    result = newNodeI(nkEmpty, n.info)
  if whenNimvm: result.typ = typ
  # The ``when`` statement implements the mechanism for platform dependent
  # code. Thus we try to ensure here consistent ID allocation after the
  # ``when`` statement.
  idSynchronizationPoint(200)

proc semSetConstr(c: PContext, n: PNode): PNode =
  result = newNodeI(nkCurly, n.info)
  result.typ = newTypeS(tySet, c)
  if sonsLen(n) == 0:
    rawAddSon(result.typ, newTypeS(tyEmpty, c))
  else:
    # only semantic checking for all elements, later type checking:
    var typ: PType = nil
    for i in 0 ..< sonsLen(n):
      if isRange(n.sons[i]):
        checkSonsLen(n.sons[i], 3, c.config)
        n.sons[i].sons[1] = semExprWithType(c, n.sons[i].sons[1])
        n.sons[i].sons[2] = semExprWithType(c, n.sons[i].sons[2])
        if typ == nil:
          typ = skipTypes(n.sons[i].sons[1].typ,
                          {tyGenericInst, tyVar, tyLent, tyOrdinal, tyAlias, tySink})
        n.sons[i].typ = n.sons[i].sons[2].typ # range node needs type too
      elif n.sons[i].kind == nkRange:
        # already semchecked
        if typ == nil:
          typ = skipTypes(n.sons[i].sons[0].typ,
                          {tyGenericInst, tyVar, tyLent, tyOrdinal, tyAlias, tySink})
      else:
        n.sons[i] = semExprWithType(c, n.sons[i])
        if typ == nil:
          typ = skipTypes(n.sons[i].typ, {tyGenericInst, tyVar, tyLent, tyOrdinal, tyAlias, tySink})
    if not isOrdinalType(typ, allowEnumWithHoles=true):
      localError(c.config, n.info, errOrdinalTypeExpected)
      typ = makeRangeType(c, 0, MaxSetElements-1, n.info)
    elif lengthOrd(c.config, typ) > MaxSetElements:
      typ = makeRangeType(c, 0, MaxSetElements-1, n.info)
    addSonSkipIntLit(result.typ, typ)
    for i in 0 ..< sonsLen(n):
      var m: PNode
      let info = n.sons[i].info
      if isRange(n.sons[i]):
        m = newNodeI(nkRange, info)
        addSon(m, fitNode(c, typ, n.sons[i].sons[1], info))
        addSon(m, fitNode(c, typ, n.sons[i].sons[2], info))
      elif n.sons[i].kind == nkRange: m = n.sons[i] # already semchecked
      else:
        m = fitNode(c, typ, n.sons[i], info)
      addSon(result, m)

proc semTableConstr(c: PContext, n: PNode): PNode =
  # we simply transform ``{key: value, key2, key3: value}`` to
  # ``[(key, value), (key2, value2), (key3, value2)]``
  result = newNodeI(nkBracket, n.info)
  var lastKey = 0
  for i in 0..n.len-1:
    var x = n.sons[i]
    if x.kind == nkExprColonExpr and sonsLen(x) == 2:
      for j in lastKey ..< i:
        var pair = newNodeI(nkTupleConstr, x.info)
        pair.add(n.sons[j])
        pair.add(x[1])
        result.add(pair)

      var pair = newNodeI(nkTupleConstr, x.info)
      pair.add(x[0])
      pair.add(x[1])
      result.add(pair)

      lastKey = i+1

  if lastKey != n.len: illFormedAst(n, c.config)
  result = semExpr(c, result)

type
  TParKind = enum
    paNone, paSingle, paTupleFields, paTuplePositions

proc checkPar(c: PContext; n: PNode): TParKind =
  var length = sonsLen(n)
  if length == 0:
    result = paTuplePositions # ()
  elif length == 1:
    if n.sons[0].kind == nkExprColonExpr: result = paTupleFields
    elif n.kind == nkTupleConstr: result = paTuplePositions
    else: result = paSingle         # (expr)
  else:
    if n.sons[0].kind == nkExprColonExpr: result = paTupleFields
    else: result = paTuplePositions
    for i in 0 ..< length:
      if result == paTupleFields:
        if (n.sons[i].kind != nkExprColonExpr) or
            n.sons[i].sons[0].kind notin {nkSym, nkIdent}:
          localError(c.config, n.sons[i].info, errNamedExprExpected)
          return paNone
      else:
        if n.sons[i].kind == nkExprColonExpr:
          localError(c.config, n.sons[i].info, errNamedExprNotAllowed)
          return paNone

proc semTupleFieldsConstr(c: PContext, n: PNode, flags: TExprFlags): PNode =
  result = newNodeI(nkTupleConstr, n.info)
  var typ = newTypeS(tyTuple, c)
  typ.n = newNodeI(nkRecList, n.info) # nkIdentDefs
  var ids = initIntSet()
  for i in 0 ..< sonsLen(n):
    if n[i].kind != nkExprColonExpr or n[i][0].kind notin {nkSym, nkIdent}:
      illFormedAst(n.sons[i], c.config)
    var id: PIdent
    if n.sons[i].sons[0].kind == nkIdent: id = n.sons[i].sons[0].ident
    else: id = n.sons[i].sons[0].sym.name
    if containsOrIncl(ids, id.id):
      localError(c.config, n.sons[i].info, errFieldInitTwice % id.s)
    n.sons[i].sons[1] = semExprWithType(c, n.sons[i].sons[1],
                                        flags*{efAllowDestructor})

    if n.sons[i].sons[1].typ.kind == tyTypeDesc:
      localError(c.config, n.sons[i].sons[1].info, "typedesc not allowed as tuple field.")
      n.sons[i].sons[1].typ = errorType(c)

    var f = newSymS(skField, n.sons[i].sons[0], c)
    f.typ = skipIntLit(n.sons[i].sons[1].typ)
    f.position = i
    rawAddSon(typ, f.typ)
    addSon(typ.n, newSymNode(f))
    n.sons[i].sons[0] = newSymNode(f)
    addSon(result, n.sons[i])
  result.typ = typ

proc semTuplePositionsConstr(c: PContext, n: PNode, flags: TExprFlags): PNode =
  result = n                  # we don't modify n, but compute the type:
  result.kind = nkTupleConstr
  var typ = newTypeS(tyTuple, c)  # leave typ.n nil!
  for i in 0 ..< sonsLen(n):
    n.sons[i] = semExprWithType(c, n.sons[i], flags*{efAllowDestructor})
    addSonSkipIntLit(typ, n.sons[i].typ)
  result.typ = typ

include semobjconstr

proc semBlock(c: PContext, n: PNode; flags: TExprFlags): PNode =
  result = n
  inc(c.p.nestedBlockCounter)
  checkSonsLen(n, 2, c.config)
  openScope(c) # BUGFIX: label is in the scope of block!
  if n.sons[0].kind != nkEmpty:
    var labl = newSymG(skLabel, n.sons[0], c)
    if sfGenSym notin labl.flags:
      addDecl(c, labl)
    elif labl.owner == nil:
      labl.owner = c.p.owner
    n.sons[0] = newSymNode(labl, n.sons[0].info)
    suggestSym(c.config, n.sons[0].info, labl, c.graph.usageSym)
    styleCheckDef(c.config, labl)
    onDef(n[0].info, labl)
  n.sons[1] = semExpr(c, n.sons[1], flags)
  n.typ = n.sons[1].typ
  if isEmptyType(n.typ): n.kind = nkBlockStmt
  else: n.kind = nkBlockExpr
  closeScope(c)
  dec(c.p.nestedBlockCounter)

proc semExportExcept(c: PContext, n: PNode): PNode =
  let moduleName = semExpr(c, n[0])
  if moduleName.kind != nkSym or moduleName.sym.kind != skModule:
    localError(c.config, n.info, "The export/except syntax expects a module name")
    return n
  let exceptSet = readExceptSet(c, n)
  let exported = moduleName.sym
  result = newNodeI(nkExportStmt, n.info)
  strTableAdd(c.module.tab, exported)
  var i: TTabIter
  var s = initTabIter(i, exported.tab)
  while s != nil:
    if s.kind in ExportableSymKinds+{skModule} and
       s.name.id notin exceptSet and sfError notin s.flags:
      strTableAdd(c.module.tab, s)
      result.add newSymNode(s, n.info)
    s = nextIter(i, exported.tab)
  markUsed(c, n.info, exported, c.graph.usageSym)

proc semExport(c: PContext, n: PNode): PNode =
  result = newNodeI(nkExportStmt, n.info)
  for i in 0..<n.len:
    let a = n.sons[i]
    var o: TOverloadIter
    var s = initOverloadIter(o, c, a)
    if s == nil:
      localError(c.config, a.info, errGenerated, "cannot export: " & renderTree(a))
    elif s.kind == skModule:
      # forward everything from that module:
      strTableAdd(c.module.tab, s)
      var ti: TTabIter
      var it = initTabIter(ti, s.tab)
      while it != nil:
        if it.kind in ExportableSymKinds+{skModule}:
          strTableAdd(c.module.tab, it)
          result.add newSymNode(it, a.info)
        it = nextIter(ti, s.tab)
      markUsed(c, n.info, s, c.graph.usageSym)
    else:
      while s != nil:
        if s.kind == skEnumField:
          localError(c.config, a.info, errGenerated, "cannot export: " & renderTree(a) &
            "; enum field cannot be exported individually")
        if s.kind in ExportableSymKinds+{skModule} and sfError notin s.flags:
          result.add(newSymNode(s, a.info))
          strTableAdd(c.module.tab, s)
          markUsed(c, n.info, s, c.graph.usageSym)
        s = nextOverloadIter(o, c, a)

proc semTupleConstr(c: PContext, n: PNode, flags: TExprFlags): PNode =
  var tupexp = semTuplePositionsConstr(c, n, flags)
  var isTupleType: bool
  if tupexp.len > 0: # don't interpret () as type
    isTupleType = tupexp[0].typ.kind == tyTypeDesc
    # check if either everything or nothing is tyTypeDesc
    for i in 1 ..< tupexp.len:
      if isTupleType != (tupexp[i].typ.kind == tyTypeDesc):
        localError(c.config, tupexp[i].info, "Mixing types and values in tuples is not allowed.")
        return(errorNode(c,n))
  if isTupleType: # expressions as ``(int, string)`` are reinterpret as type expressions
    result = n
    var typ = semTypeNode(c, n, nil).skipTypes({tyTypeDesc})
    result.typ = makeTypeDesc(c, typ)
  else:
    result = tupexp

proc shouldBeBracketExpr(n: PNode): bool =
  assert n.kind in nkCallKinds
  let a = n.sons[0]
  if a.kind in nkCallKinds:
    let b = a[0]
    if b.kind in nkSymChoices:
      for i in 0..<b.len:
        if b[i].kind == nkSym and b[i].sym.magic == mArrGet:
          let be = newNodeI(nkBracketExpr, n.info)
          for i in 1..<a.len: be.add(a[i])
          n.sons[0] = be
          return true

proc semExpr(c: PContext, n: PNode, flags: TExprFlags = {}): PNode =
  result = n
  if c.config.cmd == cmdIdeTools: suggestExpr(c, n)
  if nfSem in n.flags: return
  case n.kind
  of nkIdent, nkAccQuoted:
    let checks = if efNoEvaluateGeneric in flags:
        {checkUndeclared, checkPureEnumFields}
      elif efInCall in flags:
        {checkUndeclared, checkModule, checkPureEnumFields}
      else:
        {checkUndeclared, checkModule, checkAmbiguity, checkPureEnumFields}
    var s = qualifiedLookUp(c, n, checks)
    if c.matchedConcept == nil: semCaptureSym(s, c.p.owner)
    if s.kind in {skProc, skFunc, skMethod, skConverter, skIterator}:
      #performProcvarCheck(c, n, s)
      result = symChoice(c, n, s, scClosed)
      if result.kind == nkSym:
        markIndirect(c, result.sym)
        # if isGenericRoutine(result.sym):
        #   localError(c.config, n.info, errInstantiateXExplicitly, s.name.s)
      # "procs literals" are 'owned'
      if optNimV2 in c.config.globalOptions:
        result.typ = makeVarType(c, result.typ, tyOwned)
    else:
      result = semSym(c, n, s, flags)
  of nkSym:
    # because of the changed symbol binding, this does not mean that we
    # don't have to check the symbol for semantics here again!
    result = semSym(c, n, n.sym, flags)
  of nkEmpty, nkNone, nkCommentStmt, nkType:
    discard
  of nkNilLit:
    if result.typ == nil: result.typ = getSysType(c.graph, n.info, tyNil)
  of nkIntLit:
    if result.typ == nil: setIntLitType(c.graph, result)
  of nkInt8Lit:
    if result.typ == nil: result.typ = getSysType(c.graph, n.info, tyInt8)
  of nkInt16Lit:
    if result.typ == nil: result.typ = getSysType(c.graph, n.info, tyInt16)
  of nkInt32Lit:
    if result.typ == nil: result.typ = getSysType(c.graph, n.info, tyInt32)
  of nkInt64Lit:
    if result.typ == nil: result.typ = getSysType(c.graph, n.info, tyInt64)
  of nkUIntLit:
    if result.typ == nil: result.typ = getSysType(c.graph, n.info, tyUInt)
  of nkUInt8Lit:
    if result.typ == nil: result.typ = getSysType(c.graph, n.info, tyUInt8)
  of nkUInt16Lit:
    if result.typ == nil: result.typ = getSysType(c.graph, n.info, tyUInt16)
  of nkUInt32Lit:
    if result.typ == nil: result.typ = getSysType(c.graph, n.info, tyUInt32)
  of nkUInt64Lit:
    if result.typ == nil: result.typ = getSysType(c.graph, n.info, tyUInt64)
  #of nkFloatLit:
  #  if result.typ == nil: result.typ = getFloatLitType(result)
  of nkFloat32Lit:
    if result.typ == nil: result.typ = getSysType(c.graph, n.info, tyFloat32)
  of nkFloat64Lit, nkFloatLit:
    if result.typ == nil: result.typ = getSysType(c.graph, n.info, tyFloat64)
  of nkFloat128Lit:
    if result.typ == nil: result.typ = getSysType(c.graph, n.info, tyFloat128)
  of nkStrLit..nkTripleStrLit:
    if result.typ == nil: result.typ = getSysType(c.graph, n.info, tyString)
  of nkCharLit:
    if result.typ == nil: result.typ = getSysType(c.graph, n.info, tyChar)
  of nkDotExpr:
    result = semFieldAccess(c, n, flags)
    if result.kind == nkDotCall:
      result.kind = nkCall
      result = semExpr(c, result, flags)
  of nkBind:
    message(c.config, n.info, warnDeprecated, "bind is deprecated")
    result = semExpr(c, n.sons[0], flags)
  of nkTypeOfExpr, nkTupleTy, nkTupleClassTy, nkRefTy..nkEnumTy, nkStaticTy:
    if c.matchedConcept != nil and n.len == 1:
      let modifier = n.modifierTypeKindOfNode
      if modifier != tyNone:
        var baseType = semExpr(c, n[0]).typ.skipTypes({tyTypeDesc})
        result.typ = c.makeTypeDesc(c.newTypeWithSons(modifier, @[baseType]))
        return
    var typ = semTypeNode(c, n, nil).skipTypes({tyTypeDesc})
    result.typ = makeTypeDesc(c, typ)
  of nkCall, nkInfix, nkPrefix, nkPostfix, nkCommand, nkCallStrLit:
    # check if it is an expression macro:
    checkMinSonsLen(n, 1, c.config)
    #when defined(nimsuggest):
    #  if gIdeCmd == ideCon and c.config.m.trackPos == n.info: suggestExprNoCheck(c, n)
    let mode = if nfDotField in n.flags: {} else: {checkUndeclared}
    var s = qualifiedLookUp(c, n.sons[0], mode)
    if s != nil:
      #if c.config.cmd == cmdPretty and n.sons[0].kind == nkDotExpr:
      #  pretty.checkUse(n.sons[0].sons[1].info, s)
      case s.kind
      of skMacro, skTemplate:
        result = semDirectOp(c, n, flags)
      of skType:
        # XXX think about this more (``set`` procs)
        let ambig = contains(c.ambiguousSymbols, s.id)
        if not (n[0].kind in {nkClosedSymChoice, nkOpenSymChoice, nkIdent} and ambig) and n.len == 2:
          result = semConv(c, n)
        elif ambig and n.len == 1:
          errorUseQualifier(c, n.info, s)
        elif n.len == 1:
          result = semObjConstr(c, n, flags)
        elif s.magic == mNone: result = semDirectOp(c, n, flags)
        else: result = semMagic(c, n, s, flags)
      of skProc, skFunc, skMethod, skConverter, skIterator:
        if s.magic == mNone: result = semDirectOp(c, n, flags)
        else: result = semMagic(c, n, s, flags)
      else:
        #liMessage(n.info, warnUser, renderTree(n));
        result = semIndirectOp(c, n, flags)
    elif (n[0].kind == nkBracketExpr or shouldBeBracketExpr(n)) and
        isSymChoice(n[0][0]):
      # indirectOp can deal with explicit instantiations; the fixes
      # the 'newSeq[T](x)' bug
      setGenericParams(c, n.sons[0])
      result = semDirectOp(c, n, flags)
    elif isSymChoice(n.sons[0]) or nfDotField in n.flags:
      result = semDirectOp(c, n, flags)
    else:
      result = semIndirectOp(c, n, flags)
  of nkWhen:
    if efWantStmt in flags:
      result = semWhen(c, n, true)
    else:
      result = semWhen(c, n, false)
      if result == n:
        # This is a "when nimvm" stmt.
        result = semWhen(c, n, true)
      else:
        result = semExpr(c, result, flags)
  of nkBracketExpr:
    checkMinSonsLen(n, 1, c.config)
    result = semArrayAccess(c, n, flags)
  of nkCurlyExpr:
    result = semExpr(c, buildOverloadedSubscripts(n, getIdent(c.cache, "{}")), flags)
  of nkPragmaExpr:
    var
      pragma = n[1]
      pragmaName = considerQuotedIdent(c, pragma[0])
      flags = flags
      finalNodeFlags: TNodeFlags = {}

    case whichKeyword(pragmaName)
    of wExplain:
      flags.incl efExplain
    of wExecuteOnReload:
      finalNodeFlags.incl nfExecuteOnReload
    else:
      # what other pragmas are allowed for expressions? `likely`, `unlikely`
      invalidPragma(c, n)

    result = semExpr(c, n[0], flags)
    result.flags.incl finalNodeFlags
  of nkPar, nkTupleConstr:
    case checkPar(c, n)
    of paNone: result = errorNode(c, n)
    of paTuplePositions: result = semTupleConstr(c, n, flags)
    of paTupleFields: result = semTupleFieldsConstr(c, n, flags)
    of paSingle: result = semExpr(c, n.sons[0], flags)
  of nkCurly: result = semSetConstr(c, n)
  of nkBracket: result = semArrayConstr(c, n, flags)
  of nkObjConstr: result = semObjConstr(c, n, flags)
  of nkLambdaKinds: result = semLambda(c, n, flags)
  of nkDerefExpr: result = semDeref(c, n)
  of nkAddr:
    result = n
    checkSonsLen(n, 1, c.config)
    result[0] = semAddrArg(c, n.sons[0])
    result.typ = makePtrType(c, result[0].typ)
  of nkHiddenAddr, nkHiddenDeref:
    checkSonsLen(n, 1, c.config)
    n.sons[0] = semExpr(c, n.sons[0], flags)
  of nkCast: result = semCast(c, n)
  of nkIfExpr, nkIfStmt: result = semIf(c, n, flags)
  of nkHiddenStdConv, nkHiddenSubConv, nkConv, nkHiddenCallConv:
    checkSonsLen(n, 2, c.config)
    considerGenSyms(c, n)
  of nkStringToCString, nkCStringToString, nkObjDownConv, nkObjUpConv:
    checkSonsLen(n, 1, c.config)
    considerGenSyms(c, n)
  of nkChckRangeF, nkChckRange64, nkChckRange:
    checkSonsLen(n, 3, c.config)
    considerGenSyms(c, n)
  of nkCheckedFieldExpr:
    checkMinSonsLen(n, 2, c.config)
    considerGenSyms(c, n)
  of nkTableConstr:
    result = semTableConstr(c, n)
  of nkClosedSymChoice, nkOpenSymChoice:
    # handling of sym choices is context dependent
    # the node is left intact for now
    discard
  of nkStaticExpr: result = semStaticExpr(c, n[0])
  of nkAsgn: result = semAsgn(c, n)
  of nkBlockStmt, nkBlockExpr: result = semBlock(c, n, flags)
  of nkStmtList, nkStmtListExpr: result = semStmtList(c, n, flags)
  of nkRaiseStmt: result = semRaise(c, n)
  of nkVarSection: result = semVarOrLet(c, n, skVar)
  of nkLetSection: result = semVarOrLet(c, n, skLet)
  of nkConstSection: result = semConst(c, n)
  of nkTypeSection: result = semTypeSection(c, n)
  of nkDiscardStmt: result = semDiscard(c, n)
  of nkWhileStmt: result = semWhile(c, n, flags)
  of nkTryStmt, nkHiddenTryStmt: result = semTry(c, n, flags)
  of nkBreakStmt, nkContinueStmt: result = semBreakOrContinue(c, n)
  of nkForStmt, nkParForStmt: result = semFor(c, n, flags)
  of nkCaseStmt: result = semCase(c, n, flags)
  of nkReturnStmt: result = semReturn(c, n)
  of nkUsingStmt: result = semUsing(c, n)
  of nkAsmStmt: result = semAsm(c, n)
  of nkYieldStmt: result = semYield(c, n)
  of nkPragma: pragma(c, c.p.owner, n, stmtPragmas)
  of nkIteratorDef: result = semIterator(c, n)
  of nkProcDef: result = semProc(c, n)
  of nkFuncDef: result = semFunc(c, n)
  of nkMethodDef: result = semMethod(c, n)
  of nkConverterDef: result = semConverterDef(c, n)
  of nkMacroDef: result = semMacroDef(c, n)
  of nkTemplateDef: result = semTemplateDef(c, n)
  of nkImportStmt:
    # this particular way allows 'import' in a 'compiles' context so that
    # template canImport(x): bool =
    #   compiles:
    #     import x
    #
    # works:
    if c.currentScope.depthLevel > 2 + c.compilesContextId:
      localError(c.config, n.info, errXOnlyAtModuleScope % "import")
    result = evalImport(c, n)
  of nkImportExceptStmt:
    if not isTopLevel(c): localError(c.config, n.info, errXOnlyAtModuleScope % "import")
    result = evalImportExcept(c, n)
  of nkFromStmt:
    if not isTopLevel(c): localError(c.config, n.info, errXOnlyAtModuleScope % "from")
    result = evalFrom(c, n)
  of nkIncludeStmt:
    #if not isTopLevel(c): localError(c.config, n.info, errXOnlyAtModuleScope % "include")
    result = evalInclude(c, n)
  of nkExportStmt:
    if not isTopLevel(c): localError(c.config, n.info, errXOnlyAtModuleScope % "export")
    result = semExport(c, n)
  of nkExportExceptStmt:
    if not isTopLevel(c): localError(c.config, n.info, errXOnlyAtModuleScope % "export")
    result = semExportExcept(c, n)
  of nkPragmaBlock:
    result = semPragmaBlock(c, n)
  of nkStaticStmt:
    result = semStaticStmt(c, n)
  of nkDefer:
    if c.currentScope == c.topLevelScope:
      localError(c.config, n.info, "defer statement not supported at top level")
    n.sons[0] = semExpr(c, n.sons[0])
    if not n.sons[0].typ.isEmptyType and not implicitlyDiscardable(n.sons[0]):
      localError(c.config, n.info, "'defer' takes a 'void' expression")
    #localError(c.config, n.info, errGenerated, "'defer' not allowed in this context")
  of nkGotoState, nkState:
    if n.len != 1 and n.len != 2: illFormedAst(n, c.config)
    for i in 0 ..< n.len:
      n.sons[i] = semExpr(c, n.sons[i])
  of nkComesFrom: discard "ignore the comes from information for now"
  else:
    localError(c.config, n.info, "invalid expression: " &
               renderTree(n, {renderNoComments}))
  if result != nil: incl(result.flags, nfSem)
