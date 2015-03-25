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

proc semTemplateExpr(c: PContext, n: PNode, s: PSym,
                     flags: TExprFlags = {}): PNode =
  markUsed(n.info, s)
  styleCheckUse(n.info, s)
  pushInfoContext(n.info)
  result = evalTemplate(n, s, getCurrOwner())
  if efNoSemCheck notin flags: result = semAfterMacroCall(c, result, s, flags)
  popInfoContext()

proc semFieldAccess(c: PContext, n: PNode, flags: TExprFlags = {}): PNode

proc semOperand(c: PContext, n: PNode, flags: TExprFlags = {}): PNode =
  # same as 'semExprWithType' but doesn't check for proc vars
  result = semExpr(c, n, flags + {efOperand})
  if result.kind == nkEmpty:
    # do not produce another redundant error message:
    #raiseRecoverableError("")
    result = errorNode(c, n)
  if result.typ != nil:
    # XXX tyGenericInst here?
    if result.typ.kind == tyVar: result = newDeref(result)
  elif efWantStmt in flags:
    result.typ = newTypeS(tyEmpty, c)
  else:
    localError(n.info, errExprXHasNoType,
               renderTree(result, {renderNoComments}))
    result.typ = errorType(c)

proc semExprWithType(c: PContext, n: PNode, flags: TExprFlags = {}): PNode =
  result = semExpr(c, n, flags+{efWantValue})
  if result.isNil or result.kind == nkEmpty:
    # do not produce another redundant error message:
    #raiseRecoverableError("")
    result = errorNode(c, n)
  if result.typ == nil or result.typ == enforceVoidContext:
    # we cannot check for 'void' in macros ...
    localError(n.info, errExprXHasNoType,
               renderTree(result, {renderNoComments}))
    result.typ = errorType(c)
  else:
    # XXX tyGenericInst here?
    semProcvarCheck(c, result)
    if result.typ.kind == tyVar: result = newDeref(result)
    semDestructorCheck(c, result, flags)

proc semExprNoDeref(c: PContext, n: PNode, flags: TExprFlags = {}): PNode =
  result = semExpr(c, n, flags)
  if result.kind == nkEmpty:
    # do not produce another redundant error message:
    result = errorNode(c, n)
  if result.typ == nil:
    localError(n.info, errExprXHasNoType,
               renderTree(result, {renderNoComments}))
    result.typ = errorType(c)
  else:
    semProcvarCheck(c, result)
    semDestructorCheck(c, result, flags)

proc semSymGenericInstantiation(c: PContext, n: PNode, s: PSym): PNode =
  result = symChoice(c, n, s, scClosed)

proc inlineConst(n: PNode, s: PSym): PNode {.inline.} =
  result = copyTree(s.ast)
  result.typ = s.typ
  result.info = n.info

proc semSym(c: PContext, n: PNode, s: PSym, flags: TExprFlags): PNode =
  case s.kind
  of skConst:
    markUsed(n.info, s)
    styleCheckUse(n.info, s)
    case skipTypes(s.typ, abstractInst-{tyTypeDesc}).kind
    of  tyNil, tyChar, tyInt..tyInt64, tyFloat..tyFloat128,
        tyTuple, tySet, tyUInt..tyUInt64:
      if s.magic == mNone: result = inlineConst(n, s)
      else: result = newSymNode(s, n.info)
    of tyArrayConstr, tySequence:
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
      if s.ast.len == 0: result = inlineConst(n, s)
      else: result = newSymNode(s, n.info)
    else:
      result = newSymNode(s, n.info)
  of skMacro: result = semMacroExpr(c, n, n, s, flags)
  of skTemplate: result = semTemplateExpr(c, n, s, flags)
  of skParam:
    markUsed(n.info, s)
    styleCheckUse(n.info, s)
    if s.typ.kind == tyStatic and s.typ.n != nil:
      # XXX see the hack in sigmatch.nim ...
      return s.typ.n
    elif sfGenSym in s.flags:
      if c.p.wasForwarded:
        # gensym'ed parameters that nevertheless have been forward declared
        # need a special fixup:
        let realParam = c.p.owner.typ.n[s.position+1]
        internalAssert realParam.kind == nkSym and realParam.sym.kind == skParam
        return newSymNode(c.p.owner.typ.n[s.position+1].sym, n.info)
      elif c.p.owner.kind == skMacro:
        # gensym'ed macro parameters need a similar hack (see bug #1944):
        var u = searchInScopes(c, s.name)
        internalAssert u != nil and u.kind == skParam and u.owner == s.owner
        return newSymNode(u, n.info)
    result = newSymNode(s, n.info)
  of skVar, skLet, skResult, skForVar:
    markUsed(n.info, s)
    styleCheckUse(n.info, s)
    # if a proc accesses a global variable, it is not side effect free:
    if sfGlobal in s.flags:
      incl(c.p.owner.flags, sfSideEffect)
    result = newSymNode(s, n.info)
    # We cannot check for access to outer vars for example because it's still
    # not sure the symbol really ends up being used:
    # var len = 0 # but won't be called
    # genericThatUsesLen(x) # marked as taking a closure?
  of skGenericParam:
    styleCheckUse(n.info, s)
    if s.typ.kind == tyStatic:
      result = newSymNode(s, n.info)
      result.typ = s.typ
    elif s.ast != nil:
      result = semExpr(c, s.ast)
    else:
      n.typ = s.typ
      return n
  of skType:
    markUsed(n.info, s)
    styleCheckUse(n.info, s)
    if s.typ.kind == tyStatic and s.typ.n != nil:
      return s.typ.n
    result = newSymNode(s, n.info)
    result.typ = makeTypeDesc(c, s.typ)
  else:
    markUsed(n.info, s)
    styleCheckUse(n.info, s)
    result = newSymNode(s, n.info)

type
  TConvStatus = enum
    convOK,
    convNotNeedeed,
    convNotLegal

proc checkConversionBetweenObjects(castDest, src: PType): TConvStatus =
  return if inheritanceDiff(castDest, src) == high(int):
      convNotLegal
    else:
      convOK

const
  IntegralTypes = {tyBool, tyEnum, tyChar, tyInt..tyUInt64}

proc checkConvertible(c: PContext, castDest, src: PType): TConvStatus =
  result = convOK
  if sameType(castDest, src) and castDest.sym == src.sym:
    # don't annoy conversions that may be needed on another processor:
    if castDest.kind notin IntegralTypes+{tyRange}:
      result = convNotNeedeed
    return
  var d = skipTypes(castDest, abstractVar)
  var s = skipTypes(src, abstractVar-{tyTypeDesc})
  while (d != nil) and (d.kind in {tyPtr, tyRef}) and (d.kind == s.kind):
    d = d.lastSon
    s = s.lastSon
  if d == nil:
    result = convNotLegal
  elif d.kind == tyObject and s.kind == tyObject:
    result = checkConversionBetweenObjects(d, s)
  elif (skipTypes(castDest, abstractVarRange).kind in IntegralTypes) and
      (skipTypes(src, abstractVarRange-{tyTypeDesc}).kind in IntegralTypes):
    # accept conversion between integral types
    discard
  else:
    # we use d, s here to speed up that operation a bit:
    case cmpTypes(c, d, s)
    of isNone, isGeneric:
      if not compareTypes(castDest, src, dcEqIgnoreDistinct):
        result = convNotLegal
    else:
      discard

proc isCastable(dst, src: PType): bool =
  ## Checks whether the source type can be casted to the destination type.
  ## Casting is very unrestrictive; casts are allowed as long as
  ## castDest.size >= src.size, and typeAllowed(dst, skParam)
  #const
  #  castableTypeKinds = {tyInt, tyPtr, tyRef, tyCstring, tyString,
  #                       tySequence, tyPointer, tyNil, tyOpenArray,
  #                       tyProc, tySet, tyEnum, tyBool, tyChar}
  if skipTypes(dst, abstractInst-{tyOpenArray}).kind == tyOpenArray:
    return false
  var dstSize, srcSize: BiggestInt

  dstSize = computeSize(dst)
  srcSize = computeSize(src)
  if dstSize < 0:
    result = false
  elif srcSize < 0:
    result = false
  elif typeAllowed(dst, skParam) != nil:
    result = false
  else:
    result = (dstSize >= srcSize) or
        (skipTypes(dst, abstractInst).kind in IntegralTypes) or
        (skipTypes(src, abstractInst-{tyTypeDesc}).kind in IntegralTypes)
  if result and src.kind == tyNil:
    result = dst.size <= platform.ptrSize

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

proc semConv(c: PContext, n: PNode): PNode =
  if sonsLen(n) != 2:
    localError(n.info, errConvNeedsOneArg)
    return n

  result = newNodeI(nkConv, n.info)
  var targetType = semTypeNode(c, n.sons[0], nil).skipTypes({tyTypeDesc})
  maybeLiftType(targetType, c, n[0].info)
  result.addSon copyTree(n.sons[0])
  var op = semExprWithType(c, n.sons[1])

  if targetType.isMetaType:
    let final = inferWithMetatype(c, targetType, op, true)
    result.addSon final
    result.typ = final.typ
    return

  result.typ = targetType
  addSon(result, op)

  if not isSymChoice(op):
    let status = checkConvertible(c, result.typ, op.typ)
    case status
    of convOK:
      # handle SomeProcType(SomeGenericProc)
      # XXX: This needs fixing. checkConvertible uses typeRel internally, but
      # doesn't bother to perform the work done in paramTypeMatchAux/fitNode
      # so we are redoing the typeRel work here. Why does semConv exist as a
      # separate proc from fitNode?
      if op.kind == nkSym and op.sym.isGenericRoutine:
        result.sons[1] = fitNode(c, result.typ, result.sons[1])
    of convNotNeedeed:
      message(n.info, hintConvFromXtoItselfNotNeeded, result.typ.typeToString)
    of convNotLegal:
      localError(n.info, errGenerated, msgKindToString(errIllegalConvFromXtoY)%
        [op.typ.typeToString, result.typ.typeToString])
  else:
    for i in countup(0, sonsLen(op) - 1):
      let it = op.sons[i]
      let status = checkConvertible(c, result.typ, it.typ)
      if status in {convOK, convNotNeedeed}:
        markUsed(n.info, it.sym)
        styleCheckUse(n.info, it.sym)
        markIndirect(c, it.sym)
        return it
    localError(n.info, errUseQualifier, op.sons[0].sym.name.s)

proc semCast(c: PContext, n: PNode): PNode =
  ## Semantically analyze a casting ("cast[type](param)")
  if optSafeCode in gGlobalOptions: localError(n.info, errCastNotInSafeMode)
  #incl(c.p.owner.flags, sfSideEffect)
  checkSonsLen(n, 2)
  result = newNodeI(nkCast, n.info)
  result.typ = semTypeNode(c, n.sons[0], nil)
  addSon(result, copyTree(n.sons[0]))
  addSon(result, semExprWithType(c, n.sons[1]))
  if not isCastable(result.typ, result.sons[1].typ):
    localError(result.info, errExprCannotBeCastedToX,
               typeToString(result.typ))

proc semLowHigh(c: PContext, n: PNode, m: TMagic): PNode =
  const
    opToStr: array[mLow..mHigh, string] = ["low", "high"]
  if sonsLen(n) != 2:
    localError(n.info, errXExpectsTypeOrValue, opToStr[m])
  else:
    n.sons[1] = semExprWithType(c, n.sons[1], {efDetermineType})
    var typ = skipTypes(n.sons[1].typ, abstractVarRange +
                                       {tyTypeDesc, tyFieldAccessor})
    case typ.kind
    of tySequence, tyString, tyCString, tyOpenArray, tyVarargs:
      n.typ = getSysType(tyInt)
    of tyArrayConstr, tyArray:
      n.typ = typ.sons[0] # indextype
    of tyInt..tyInt64, tyChar, tyBool, tyEnum, tyUInt8, tyUInt16, tyUInt32:
      # do not skip the range!
      n.typ = n.sons[1].typ.skipTypes(abstractVar + {tyFieldAccessor})
    of tyGenericParam:
      # prepare this for resolving in semtypinst:
      # we must use copyTree here in order to avoid creating a cycle
      # that could easily turn into an infinite recursion in semtypinst
      n.typ = makeTypeFromExpr(c, n.copyTree)
    else:
      localError(n.info, errInvalidArgForX, opToStr[m])
  result = n

proc semSizeof(c: PContext, n: PNode): PNode =
  if sonsLen(n) != 2:
    localError(n.info, errXExpectsTypeOrValue, "sizeof")
  else:
    n.sons[1] = semExprWithType(c, n.sons[1], {efDetermineType})
    #restoreOldStyleType(n.sons[1])
  n.typ = getSysType(tyInt)
  result = n

proc semOf(c: PContext, n: PNode): PNode =
  if sonsLen(n) == 3:
    n.sons[1] = semExprWithType(c, n.sons[1])
    n.sons[2] = semExprWithType(c, n.sons[2], {efDetermineType})
    #restoreOldStyleType(n.sons[1])
    #restoreOldStyleType(n.sons[2])
    let a = skipTypes(n.sons[1].typ, abstractPtrs)
    let b = skipTypes(n.sons[2].typ, abstractPtrs)
    let x = skipTypes(n.sons[1].typ, abstractPtrs-{tyTypeDesc})
    let y = skipTypes(n.sons[2].typ, abstractPtrs-{tyTypeDesc})

    if x.kind == tyTypeDesc or y.kind != tyTypeDesc:
      localError(n.info, errXExpectsObjectTypes, "of")
    elif b.kind != tyObject or a.kind != tyObject:
      localError(n.info, errXExpectsObjectTypes, "of")
    else:
      let diff = inheritanceDiff(a, b)
      # | returns: 0 iff `a` == `b`
      # | returns: -x iff `a` is the x'th direct superclass of `b`
      # | returns: +x iff `a` is the x'th direct subclass of `b`
      # | returns: `maxint` iff `a` and `b` are not compatible at all
      if diff <= 0:
        # optimize to true:
        message(n.info, hintConditionAlwaysTrue, renderTree(n))
        result = newIntNode(nkIntLit, 1)
        result.info = n.info
        result.typ = getSysType(tyBool)
        return result
      elif diff == high(int):
        localError(n.info, errXcanNeverBeOfThisSubtype, typeToString(a))
  else:
    localError(n.info, errXExpectsTwoArguments, "of")
  n.typ = getSysType(tyBool)
  result = n

proc isOpImpl(c: PContext, n: PNode): PNode =
  internalAssert n.sonsLen == 3 and
    n[1].typ != nil and n[1].typ.kind == tyTypeDesc and
    n[2].kind in {nkStrLit..nkTripleStrLit, nkType}

  let t1 = n[1].typ.skipTypes({tyTypeDesc, tyFieldAccessor})

  if n[2].kind in {nkStrLit..nkTripleStrLit}:
    case n[2].strVal.normalize
    of "closure":
      let t = skipTypes(t1, abstractRange)
      result = newIntNode(nkIntLit, ord(t.kind == tyProc and
                                        t.callConv == ccClosure and
                                        tfIterator notin t.flags))
    else: discard
  else:
    var t2 = n[2].typ.skipTypes({tyTypeDesc})
    maybeLiftType(t2, c, n.info)
    var m: TCandidate
    initCandidate(c, m, t2)
    let match = typeRel(m, t2, t1) != isNone
    result = newIntNode(nkIntLit, ord(match))

  result.typ = n.typ

proc semIs(c: PContext, n: PNode): PNode =
  if sonsLen(n) != 3:
    localError(n.info, errXExpectsTwoArguments, "is")

  result = n
  n.typ = getSysType(tyBool)

  n.sons[1] = semExprWithType(c, n[1], {efDetermineType, efWantIterator})
  if n[2].kind notin {nkStrLit..nkTripleStrLit}:
    let t2 = semTypeNode(c, n[2], nil)
    n.sons[2] = newNodeIT(nkType, n[2].info, t2)

  let lhsType = n[1].typ
  if lhsType.kind != tyTypeDesc:
    n.sons[1] = makeTypeSymNode(c, lhsType, n[1].info)
  elif lhsType.base.kind == tyNone:
    # this is a typedesc variable, leave for evals
    return

  # BUGFIX: don't evaluate this too early: ``T is void``
  if not n[1].typ.base.containsGenericType: result = isOpImpl(c, n)

proc semOpAux(c: PContext, n: PNode) =
  const flags = {efDetermineType}
  for i in countup(1, n.sonsLen-1):
    var a = n.sons[i]
    if a.kind == nkExprEqExpr and sonsLen(a) == 2:
      var info = a.sons[0].info
      a.sons[0] = newIdentNode(considerQuotedIdent(a.sons[0]), info)
      a.sons[1] = semExprWithType(c, a.sons[1], flags)
      a.typ = a.sons[1].typ
    else:
      n.sons[i] = semExprWithType(c, a, flags)

proc overloadedCallOpr(c: PContext, n: PNode): PNode =
  # quick check if there is *any* () operator overloaded:
  var par = getIdent("()")
  if searchInScopes(c, par) == nil:
    result = nil
  else:
    result = newNodeI(nkCall, n.info)
    addSon(result, newIdentNode(par, n.info))
    for i in countup(0, sonsLen(n) - 1): addSon(result, n.sons[i])
    result = semExpr(c, result)

proc changeType(n: PNode, newType: PType, check: bool) =
  case n.kind
  of nkCurly, nkBracket:
    for i in countup(0, sonsLen(n) - 1):
      changeType(n.sons[i], elemType(newType), check)
  of nkPar:
    let tup = newType.skipTypes({tyGenericInst})
    if tup.kind != tyTuple:
      internalError(n.info, "changeType: no tuple type for constructor")
    elif sonsLen(n) > 0 and n.sons[0].kind == nkExprColonExpr:
      # named tuple?
      for i in countup(0, sonsLen(n) - 1):
        var m = n.sons[i].sons[0]
        if m.kind != nkSym:
          internalError(m.info, "changeType(): invalid tuple constr")
          return
        if tup.n != nil:
          var f = getSymFromList(tup.n, m.sym.name)
          if f == nil:
            internalError(m.info, "changeType(): invalid identifier")
            return
          changeType(n.sons[i].sons[1], f.typ, check)
        else:
          changeType(n.sons[i].sons[1], tup.sons[i], check)
    else:
      for i in countup(0, sonsLen(n) - 1):
        changeType(n.sons[i], tup.sons[i], check)
        when false:
          var m = n.sons[i]
          var a = newNodeIT(nkExprColonExpr, m.info, newType.sons[i])
          addSon(a, newSymNode(newType.n.sons[i].sym))
          addSon(a, m)
          changeType(m, tup.sons[i], check)
  of nkCharLit..nkUInt64Lit:
    if check:
      let value = n.intVal
      if value < firstOrd(newType) or value > lastOrd(newType):
        localError(n.info, errGenerated, "cannot convert " & $value &
                                         " to " & typeToString(newType))
  else: discard
  n.typ = newType

proc arrayConstrType(c: PContext, n: PNode): PType =
  var typ = newTypeS(tyArrayConstr, c)
  rawAddSon(typ, nil)     # index type
  if sonsLen(n) == 0:
    rawAddSon(typ, newTypeS(tyEmpty, c)) # needs an empty basetype!
  else:
    var x = n.sons[0]
    var lastIndex: BiggestInt = sonsLen(n) - 1
    var t = skipTypes(n.sons[0].typ, {tyGenericInst, tyVar, tyOrdinal})
    addSonSkipIntLit(typ, t)
  typ.sons[0] = makeRangeType(c, 0, sonsLen(n) - 1, n.info)
  result = typ

proc semArrayConstr(c: PContext, n: PNode, flags: TExprFlags): PNode =
  result = newNodeI(nkBracket, n.info)
  result.typ = newTypeS(tyArrayConstr, c)
  rawAddSon(result.typ, nil)     # index type
  if sonsLen(n) == 0:
    rawAddSon(result.typ, newTypeS(tyEmpty, c)) # needs an empty basetype!
  else:
    var x = n.sons[0]
    var lastIndex: BiggestInt = 0
    var indexType = getSysType(tyInt)
    if x.kind == nkExprColonExpr and sonsLen(x) == 2:
      var idx = semConstExpr(c, x.sons[0])
      lastIndex = getOrdValue(idx)
      indexType = idx.typ
      x = x.sons[1]

    let yy = semExprWithType(c, x)
    var typ = yy.typ
    addSon(result, yy)
    #var typ = skipTypes(result.sons[0].typ, {tyGenericInst, tyVar, tyOrdinal})
    for i in countup(1, sonsLen(n) - 1):
      x = n.sons[i]
      if x.kind == nkExprColonExpr and sonsLen(x) == 2:
        var idx = semConstExpr(c, x.sons[0])
        idx = fitNode(c, indexType, idx)
        if lastIndex+1 != getOrdValue(idx):
          localError(x.info, errInvalidOrderInArrayConstructor)
        x = x.sons[1]

      let xx = semExprWithType(c, x, flags*{efAllowDestructor})
      result.add xx
      typ = commonType(typ, xx.typ)
      #n.sons[i] = semExprWithType(c, x, flags*{efAllowDestructor})
      #addSon(result, fitNode(c, typ, n.sons[i]))
      inc(lastIndex)
    addSonSkipIntLit(result.typ, typ)
    for i in 0 .. <result.len:
      result.sons[i] = fitNode(c, typ, result.sons[i])
  result.typ.sons[0] = makeRangeType(c, 0, sonsLen(result) - 1, n.info)

proc fixAbstractType(c: PContext, n: PNode) =
  # XXX finally rewrite that crap!
  for i in countup(1, sonsLen(n) - 1):
    var it = n.sons[i]
    case it.kind
    of nkHiddenStdConv, nkHiddenSubConv:
      if it.sons[1].kind == nkBracket:
        it.sons[1].typ = arrayConstrType(c, it.sons[1])
        #it.sons[1] = semArrayConstr(c, it.sons[1])
      if skipTypes(it.typ, abstractVar).kind in {tyOpenArray, tyVarargs}:
        #if n.sons[0].kind == nkSym and IdentEq(n.sons[0].sym.name, "[]="):
        #  debug(n)

        var s = skipTypes(it.sons[1].typ, abstractVar)
        if s.kind == tyArrayConstr and s.sons[1].kind == tyEmpty:
          s = copyType(s, getCurrOwner(), false)
          skipTypes(s, abstractVar).sons[1] = elemType(
              skipTypes(it.typ, abstractVar))
          it.sons[1].typ = s
        elif s.kind == tySequence and s.sons[0].kind == tyEmpty:
          s = copyType(s, getCurrOwner(), false)
          skipTypes(s, abstractVar).sons[0] = elemType(
              skipTypes(it.typ, abstractVar))
          it.sons[1].typ = s

      elif skipTypes(it.sons[1].typ, abstractVar).kind in
          {tyNil, tyArrayConstr, tyTuple, tySet}:
        var s = skipTypes(it.typ, abstractVar)
        if s.kind != tyExpr:
          changeType(it.sons[1], s, check=true)
        n.sons[i] = it.sons[1]
    of nkBracket:
      # an implicitly constructed array (passed to an open array):
      n.sons[i] = semArrayConstr(c, it, {})
    else:
      discard
      #if (it.typ == nil):
      #  InternalError(it.info, "fixAbstractType: " & renderTree(it))

proc skipObjConv(n: PNode): PNode =
  case n.kind
  of nkHiddenStdConv, nkHiddenSubConv, nkConv:
    if skipTypes(n.sons[1].typ, abstractPtrs).kind in {tyTuple, tyObject}:
      result = n.sons[1]
    else:
      result = n
  of nkObjUpConv, nkObjDownConv: result = n.sons[0]
  else: result = n

proc isAssignable(c: PContext, n: PNode): TAssignableResult =
  result = parampatterns.isAssignable(c.p.owner, n)

proc newHiddenAddrTaken(c: PContext, n: PNode): PNode =
  if n.kind == nkHiddenDeref and not (gCmd == cmdCompileToCpp or
                                      sfCompileToCpp in c.module.flags):
    checkSonsLen(n, 1)
    result = n.sons[0]
  else:
    result = newNodeIT(nkHiddenAddr, n.info, makeVarType(c, n.typ))
    addSon(result, n)
    if isAssignable(c, n) notin {arLValue, arLocalLValue}:
      localError(n.info, errVarForOutParamNeeded)

proc analyseIfAddressTaken(c: PContext, n: PNode): PNode =
  result = n
  case n.kind
  of nkSym:
    # n.sym.typ can be nil in 'check' mode ...
    if n.sym.typ != nil and
        skipTypes(n.sym.typ, abstractInst-{tyTypeDesc}).kind != tyVar:
      incl(n.sym.flags, sfAddrTaken)
      result = newHiddenAddrTaken(c, n)
  of nkDotExpr:
    checkSonsLen(n, 2)
    if n.sons[1].kind != nkSym:
      internalError(n.info, "analyseIfAddressTaken")
      return
    if skipTypes(n.sons[1].sym.typ, abstractInst-{tyTypeDesc}).kind != tyVar:
      incl(n.sons[1].sym.flags, sfAddrTaken)
      result = newHiddenAddrTaken(c, n)
  of nkBracketExpr:
    checkMinSonsLen(n, 1)
    if skipTypes(n.sons[0].typ, abstractInst-{tyTypeDesc}).kind != tyVar:
      if n.sons[0].kind == nkSym: incl(n.sons[0].sym.flags, sfAddrTaken)
      result = newHiddenAddrTaken(c, n)
  else:
    result = newHiddenAddrTaken(c, n)

proc analyseIfAddressTakenInCall(c: PContext, n: PNode) =
  checkMinSonsLen(n, 1)
  const
    FakeVarParams = {mNew, mNewFinalize, mInc, ast.mDec, mIncl, mExcl,
      mSetLengthStr, mSetLengthSeq, mAppendStrCh, mAppendStrStr, mSwap,
      mAppendSeqElem, mNewSeq, mReset, mShallowCopy, mDeepCopy}

  # get the real type of the callee
  # it may be a proc var with a generic alias type, so we skip over them
  var t = n.sons[0].typ.skipTypes({tyGenericInst})

  if n.sons[0].kind == nkSym and n.sons[0].sym.magic in FakeVarParams:
    # BUGFIX: check for L-Value still needs to be done for the arguments!
    # note sometimes this is eval'ed twice so we check for nkHiddenAddr here:
    for i in countup(1, sonsLen(n) - 1):
      if i < sonsLen(t) and t.sons[i] != nil and
          skipTypes(t.sons[i], abstractInst-{tyTypeDesc}).kind == tyVar:
        if isAssignable(c, n.sons[i]) notin {arLValue, arLocalLValue}:
          if n.sons[i].kind != nkHiddenAddr:
            localError(n.sons[i].info, errVarForOutParamNeeded)
    return
  for i in countup(1, sonsLen(n) - 1):
    if n.sons[i].kind == nkHiddenCallConv:
      # we need to recurse explicitly here as converters can create nested
      # calls and then they wouldn't be analysed otherwise
      analyseIfAddressTakenInCall(c, n.sons[i])
    semProcvarCheck(c, n.sons[i])
    if i < sonsLen(t) and
        skipTypes(t.sons[i], abstractInst-{tyTypeDesc}).kind == tyVar:
      if n.sons[i].kind != nkHiddenAddr:
        n.sons[i] = analyseIfAddressTaken(c, n.sons[i])

include semmagic

proc evalAtCompileTime(c: PContext, n: PNode): PNode =
  result = n
  if n.kind notin nkCallKinds or n.sons[0].kind != nkSym: return
  var callee = n.sons[0].sym

  # constant folding that is necessary for correctness of semantic pass:
  if callee.magic != mNone and callee.magic in ctfeWhitelist and n.typ != nil:
    var call = newNodeIT(nkCall, n.info, n.typ)
    call.add(n.sons[0])
    var allConst = true
    for i in 1 .. < n.len:
      var a = getConstExpr(c.module, n.sons[i])
      if a == nil:
        allConst = false
        a = n.sons[i]
        if a.kind == nkHiddenStdConv: a = a.sons[1]
      call.add(a)
    if allConst:
      result = semfold.getConstExpr(c.module, call)
      if result.isNil: result = n
      else: return result
    result.typ = semfold.getIntervalType(callee.magic, call)

  block maybeLabelAsStatic:
    # XXX: temporary work-around needed for tlateboundstatic.
    # This is certainly not correct, but it will get the job
    # done until we have a more robust infrastructure for
    # implicit statics.
    if n.len > 1:
      for i in 1 .. <n.len:
        # see bug #2113, it's possible that n[i].typ for errornous code:
        if n[i].typ.isNil or n[i].typ.kind != tyStatic or
            tfUnresolved notin n[i].typ.flags:
          break maybeLabelAsStatic
      n.typ = newTypeWithSons(c, tyStatic, @[n.typ])
      n.typ.flags.incl tfUnresolved

  # optimization pass: not necessary for correctness of the semantic pass
  if {sfNoSideEffect, sfCompileTime} * callee.flags != {} and
     {sfForward, sfImportc} * callee.flags == {} and n.typ != nil:
    if sfCompileTime notin callee.flags and
        optImplicitStatic notin gOptions: return

    if callee.magic notin ctfeWhitelist: return
    if callee.kind notin {skProc, skConverter} or callee.isGenericRoutine:
      return

    if n.typ != nil and typeAllowed(n.typ, skConst) != nil: return

    var call = newNodeIT(nkCall, n.info, n.typ)
    call.add(n.sons[0])
    for i in 1 .. < n.len:
      let a = getConstExpr(c.module, n.sons[i])
      if a == nil: return n
      call.add(a)
    #echo "NOW evaluating at compile time: ", call.renderTree
    if sfCompileTime in callee.flags:
      result = evalStaticExpr(c.module, call, c.p.owner)
      if result.isNil:
        localError(n.info, errCannotInterpretNodeX, renderTree(call))
      else: result = fixupTypeAfterEval(c, result, n)
    else:
      result = evalConstExpr(c.module, call)
      if result.isNil: result = n
      else: result = fixupTypeAfterEval(c, result, n)
    #if result != n:
    #  echo "SUCCESS evaluated at compile time: ", call.renderTree

proc semStaticExpr(c: PContext, n: PNode): PNode =
  let a = semExpr(c, n.sons[0])
  result = evalStaticExpr(c.module, a, c.p.owner)
  if result.isNil:
    localError(n.info, errCannotInterpretNodeX, renderTree(n))
    result = emptyNode
  else:
    result = fixupTypeAfterEval(c, result, a)

proc semOverloadedCallAnalyseEffects(c: PContext, n: PNode, nOrig: PNode,
                                     flags: TExprFlags): PNode =
  if flags*{efInTypeof, efWantIterator} != {}:
    # consider: 'for x in pReturningArray()' --> we don't want the restriction
    # to 'skIterators' anymore; skIterators are preferred in sigmatch already
    # for typeof support.
    # for ``type(countup(1,3))``, see ``tests/ttoseq``.
    result = semOverloadedCall(c, n, nOrig,
      {skProc, skMethod, skConverter, skMacro, skTemplate}+skIterators)
  else:
    result = semOverloadedCall(c, n, nOrig,
      {skProc, skMethod, skConverter, skMacro, skTemplate})

  if result != nil:
    if result.sons[0].kind != nkSym:
      internalError("semOverloadedCallAnalyseEffects")
      return
    let callee = result.sons[0].sym
    case callee.kind
    of skMacro, skTemplate: discard
    else:
      if callee.kind in skIterators and callee.id == c.p.owner.id:
        localError(n.info, errRecursiveDependencyX, callee.name.s)
        # error correction, prevents endless for loop elimination in transf.
        # See bug #2051:
        result.sons[0] = newSymNode(errorSym(c, n))
      if sfNoSideEffect notin callee.flags:
        if {sfImportc, sfSideEffect} * callee.flags != {}:
          incl(c.p.owner.flags, sfSideEffect)

proc semObjConstr(c: PContext, n: PNode, flags: TExprFlags): PNode

proc resolveIndirectCall(c: PContext; n, nOrig: PNode;
                         t: PType): TCandidate =
  initCandidate(c, result, t)
  matches(c, n, nOrig, result)
  if result.state != csMatch:
    # try to deref the first argument:
    if experimentalMode(c) and canDeref(n):
      n.sons[1] = n.sons[1].tryDeref
      initCandidate(c, result, t)
      matches(c, n, nOrig, result)

proc semIndirectOp(c: PContext, n: PNode, flags: TExprFlags): PNode =
  result = nil
  checkMinSonsLen(n, 1)
  var prc = n.sons[0]
  if n.sons[0].kind == nkDotExpr:
    checkSonsLen(n.sons[0], 2)
    n.sons[0] = semFieldAccess(c, n.sons[0])
    if n.sons[0].kind == nkDotCall:
      # it is a static call!
      result = n.sons[0]
      result.kind = nkCall
      result.flags.incl nfExplicitCall
      for i in countup(1, sonsLen(n) - 1): addSon(result, n.sons[i])
      return semExpr(c, result, flags)
  else:
    n.sons[0] = semExpr(c, n.sons[0])
  let nOrig = n.copyTree
  semOpAux(c, n)
  var t: PType = nil
  if n.sons[0].typ != nil:
    t = skipTypes(n.sons[0].typ, abstractInst-{tyTypeDesc})
  if t != nil and t.kind == tyProc:
    # This is a proc variable, apply normal overload resolution
    let m = resolveIndirectCall(c, n, nOrig, t)
    if m.state != csMatch:
      if c.inCompilesContext > 0:
        # speed up error generation:
        globalError(n.info, errTypeMismatch, "")
        return emptyNode
      else:
        var hasErrorType = false
        var msg = msgKindToString(errTypeMismatch)
        for i in countup(1, sonsLen(n) - 1):
          if i > 1: add(msg, ", ")
          let nt = n.sons[i].typ
          add(msg, typeToString(nt))
          if nt.kind == tyError:
            hasErrorType = true
            break
        if not hasErrorType:
          add(msg, ")\n" & msgKindToString(errButExpected) & "\n" &
              typeToString(n.sons[0].typ))
          localError(n.info, errGenerated, msg)
        return errorNode(c, n)
      result = nil
    else:
      result = m.call
      instGenericConvertersSons(c, result, m)
    # we assume that a procedure that calls something indirectly
    # has side-effects:
    if tfNoSideEffect notin t.flags: incl(c.p.owner.flags, sfSideEffect)
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
  fixAbstractType(c, result)
  analyseIfAddressTakenInCall(c, result)
  if result.sons[0].kind == nkSym and result.sons[0].sym.magic != mNone:
    result = magicsAfterOverloadResolution(c, result, flags)
  result = evalAtCompileTime(c, result)

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
  if c.inTypeClass == 0:
    result = evalAtCompileTime(c, result)

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
  var e = strTableGet(magicsys.systemModule.tab, getIdent"echo")
  if e != nil:
    add(result, newSymNode(e))
  else:
    localError(n.info, errSystemNeeds, "echo")
    add(result, errorNode(c, n))
  add(result, n)
  result = semExpr(c, result)

proc semExprNoType(c: PContext, n: PNode): PNode =
  result = semExpr(c, n, {efWantStmt})
  discardCheck(c, result)

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
    for i in countup(0, sonsLen(r) - 1):
      result = lookupInRecordAndBuildCheck(c, n, r.sons[i], field, check)
      if result != nil: return
  of nkRecCase:
    checkMinSonsLen(r, 2)
    if (r.sons[0].kind != nkSym): illFormedAst(r)
    result = lookupInRecordAndBuildCheck(c, n, r.sons[0], field, check)
    if result != nil: return
    let setType = createSetType(c, r.sons[0].typ)
    var s = newNodeIT(nkCurly, r.info, setType)
    for i in countup(1, sonsLen(r) - 1):
      var it = r.sons[i]
      case it.kind
      of nkOfBranch:
        result = lookupInRecordAndBuildCheck(c, n, lastSon(it), field, check)
        if result == nil:
          for j in 0..sonsLen(it)-2: addSon(s, copyTree(it.sons[j]))
        else:
          if check == nil:
            check = newNodeI(nkCheckedFieldExpr, n.info)
            addSon(check, ast.emptyNode) # make space for access node
          s = newNodeIT(nkCurly, n.info, setType)
          for j in countup(0, sonsLen(it) - 2): addSon(s, copyTree(it.sons[j]))
          var inExpr = newNodeIT(nkCall, n.info, getSysType(tyBool))
          addSon(inExpr, newSymNode(ast.opContains, n.info))
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
            addSon(check, ast.emptyNode) # make space for access node
          var inExpr = newNodeIT(nkCall, n.info, getSysType(tyBool))
          addSon(inExpr, newSymNode(ast.opContains, n.info))
          addSon(inExpr, s)
          addSon(inExpr, copyTree(r.sons[0]))
          var notExpr = newNodeIT(nkCall, n.info, getSysType(tyBool))
          addSon(notExpr, newSymNode(ast.opNot, n.info))
          addSon(notExpr, inExpr)
          addSon(check, notExpr)
          return
      else: illFormedAst(it)
  of nkSym:
    if r.sym.name.id == field.id: result = r.sym
  else: illFormedAst(n)

proc makeDeref(n: PNode): PNode =
  var t = skipTypes(n.typ, {tyGenericInst})
  result = n
  if t.kind == tyVar:
    result = newNodeIT(nkHiddenDeref, n.info, t.sons[0])
    addSon(result, n)
    t = skipTypes(t.sons[0], {tyGenericInst})
  while t.kind in {tyPtr, tyRef}:
    var a = result
    let baseTyp = t.lastSon
    result = newNodeIT(nkHiddenDeref, n.info, baseTyp)
    addSon(result, a)
    t = skipTypes(baseTyp, {tyGenericInst})

const
  tyTypeParamsHolders = {tyGenericInst, tyCompositeTypeClass}
  tyDotOpTransparent = {tyVar, tyPtr, tyRef}

proc readTypeParameter(c: PContext, typ: PType,
                       paramName: PIdent, info: TLineInfo): PNode =
  let ty = if typ.kind == tyGenericInst: typ.skipGenericAlias
           else: (internalAssert(typ.kind == tyCompositeTypeClass);
                  typ.sons[1].skipGenericAlias)
  let tbody = ty.sons[0]
  for s in countup(0, tbody.len-2):
    let tParam = tbody.sons[s]
    if tParam.sym.name.id == paramName.id:
      let rawTyp = ty.sons[s + 1]
      if rawTyp.kind == tyStatic:
        return rawTyp.n
      else:
        let foundTyp = makeTypeDesc(c, rawTyp)
        return newSymNode(copySym(tParam.sym).linkTo(foundTyp), info)
  #echo "came here: returned nil"

proc builtinFieldAccess(c: PContext, n: PNode, flags: TExprFlags): PNode =
  ## returns nil if it's not a built-in field access
  checkSonsLen(n, 2)
  # tests/bind/tbindoverload.nim wants an early exit here, but seems to
  # work without now. template/tsymchoicefield doesn't like an early exit
  # here at all!
  #if isSymChoice(n.sons[1]): return

  var s = qualifiedLookUp(c, n, {checkAmbiguity, checkUndeclared})
  if s != nil:
    if s.kind in OverloadableSyms:
      result = symChoice(c, n, s, scClosed)
      if result.kind == nkSym: result = semSym(c, n, s, flags)
    else:
      markUsed(n.sons[1].info, s)
      result = semSym(c, n, s, flags)
    styleCheckUse(n.sons[1].info, s)
    return

  n.sons[0] = semExprWithType(c, n.sons[0], flags+{efDetermineType})
  #restoreOldStyleType(n.sons[0])
  var i = considerQuotedIdent(n.sons[1])
  var ty = n.sons[0].typ
  var f: PSym = nil
  result = nil
  if isTypeExpr(n.sons[0]) or (ty.kind == tyTypeDesc and ty.base.kind != tyNone):
    if ty.kind == tyTypeDesc: ty = ty.base
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
        markUsed(n.info, f)
        styleCheckUse(n.info, f)
        return
    of tyTypeParamsHolders:
      return readTypeParameter(c, ty, i, n.info)
    of tyObject, tyTuple:
      if ty.n != nil and ty.n.kind == nkRecList:
        for field in ty.n:
          if field.sym.name == i:
            n.typ = newTypeWithSons(c, tyFieldAccessor, @[ty, field.sym.typ])
            n.typ.n = copyTree(n)
            return n
    else:
      # echo "TYPE FIELD ACCESS"
      # debug ty
      return
    # XXX: This is probably not relevant any more
    # reset to prevent 'nil' bug: see "tests/reject/tenumitems.nim":
    ty = n.sons[0].typ
    return nil
  ty = skipTypes(ty, {tyGenericInst, tyVar, tyPtr, tyRef})
  while tfBorrowDot in ty.flags: ty = ty.skipTypes({tyDistinct})
  var check: PNode = nil
  if ty.kind == tyObject:
    while true:
      check = nil
      f = lookupInRecordAndBuildCheck(c, n, ty.n, i, check)
      if f != nil: break
      if ty.sons[0] == nil: break
      ty = skipTypes(ty.sons[0], {tyGenericInst})
    if f != nil:
      if fieldVisible(c, f):
        # is the access to a public field or in the same module or in a friend?
        markUsed(n.sons[1].info, f)
        styleCheckUse(n.sons[1].info, f)
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
      markUsed(n.sons[1].info, f)
      styleCheckUse(n.sons[1].info, f)
      n.sons[0] = makeDeref(n.sons[0])
      n.sons[1] = newSymNode(f)
      n.typ = f.typ
      result = n

  # we didn't find any field, let's look for a generic param
  if result == nil:
    let t = n.sons[0].typ.skipTypes(tyDotOpTransparent)
    if t.kind in tyTypeParamsHolders:
      result = readTypeParameter(c, t, i, n.info)

proc dotTransformation(c: PContext, n: PNode): PNode =
  if isSymChoice(n.sons[1]):
    result = newNodeI(nkDotCall, n.info)
    addSon(result, n.sons[1])
    addSon(result, copyTree(n[0]))
  else:
    var i = considerQuotedIdent(n.sons[1])
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
  checkSonsLen(n, 1)
  n.sons[0] = semExprWithType(c, n.sons[0])
  result = n
  var t = skipTypes(n.sons[0].typ, {tyGenericInst, tyVar})
  case t.kind
  of tyRef, tyPtr: n.typ = t.lastSon
  else: result = nil
  #GlobalError(n.sons[0].info, errCircumNeedsPointer)

proc semSubscript(c: PContext, n: PNode, flags: TExprFlags): PNode =
  ## returns nil if not a built-in subscript operator; also called for the
  ## checking of assignments
  if sonsLen(n) == 1:
    var x = semDeref(c, n)
    if x == nil: return nil
    result = newNodeIT(nkDerefExpr, x.info, x.typ)
    result.add(x[0])
    return
  checkMinSonsLen(n, 2)
  n.sons[0] = semExprWithType(c, n.sons[0])
  var arr = skipTypes(n.sons[0].typ, {tyGenericInst, tyVar, tyPtr, tyRef})
  case arr.kind
  of tyArray, tyOpenArray, tyVarargs, tyArrayConstr, tySequence, tyString,
     tyCString:
    if n.len != 2: return nil
    n.sons[0] = makeDeref(n.sons[0])
    for i in countup(1, sonsLen(n) - 1):
      n.sons[i] = semExprWithType(c, n.sons[i],
                                  flags*{efInTypeof, efDetermineType})
    var indexType = if arr.kind == tyArray: arr.sons[0] else: getSysType(tyInt)
    var arg = indexTypesMatch(c, indexType, n.sons[1].typ, n.sons[1])
    if arg != nil:
      n.sons[1] = arg
      result = n
      result.typ = elemType(arr)
    #GlobalError(n.info, errIndexTypesDoNotMatch)
  of tyTypeDesc:
    # The result so far is a tyTypeDesc bound
    # a tyGenericBody. The line below will substitute
    # it with the instantiated type.
    result = n
    result.typ = makeTypeDesc(c, semTypeNode(c, n, nil))
    #result = symNodeFromType(c, semTypeNode(c, n, nil), n.info)
  of tyTuple:
    checkSonsLen(n, 2)
    n.sons[0] = makeDeref(n.sons[0])
    # [] operator for tuples requires constant expression:
    n.sons[1] = semConstExpr(c, n.sons[1])
    if skipTypes(n.sons[1].typ, {tyGenericInst, tyRange, tyOrdinal}).kind in
        {tyInt..tyInt64}:
      var idx = getOrdValue(n.sons[1])
      if idx >= 0 and idx < sonsLen(arr): n.typ = arr.sons[int(idx)]
      else: localError(n.info, errInvalidIndexValueForTuple)
    else:
      localError(n.info, errIndexTypesDoNotMatch)
    result = n
  else: discard

proc semArrayAccess(c: PContext, n: PNode, flags: TExprFlags): PNode =
  result = semSubscript(c, n, flags)
  if result == nil:
    # overloaded [] operator:
    result = semExpr(c, buildOverloadedSubscripts(n, getIdent"[]"))

proc propertyWriteAccess(c: PContext, n, nOrig, a: PNode): PNode =
  var id = considerQuotedIdent(a[1])
  var setterId = newIdentNode(getIdent(id.s & '='), n.info)
  # a[0] is already checked for semantics, that does ``builtinFieldAccess``
  # this is ugly. XXX Semantic checking should use the ``nfSem`` flag for
  # nodes?
  let aOrig = nOrig[0]
  result = newNode(nkCall, n.info, sons = @[setterId, a[0], semExpr(c, n[1])])
  result.flags.incl nfDotSetter
  let orig = newNode(nkCall, n.info, sons = @[setterId, aOrig[0], nOrig[1]])
  result = semOverloadedCallAnalyseEffects(c, result, orig, {})

  if result != nil:
    result = afterCallActions(c, result, nOrig, {})
    #fixAbstractType(c, result)
    #analyseIfAddressTakenInCall(c, result)

proc takeImplicitAddr(c: PContext, n: PNode): PNode =
  case n.kind
  of nkHiddenAddr, nkAddr: return n
  of nkHiddenDeref, nkDerefExpr: return n.sons[0]
  of nkBracketExpr:
    if len(n) == 1: return n.sons[0]
  else: discard
  var valid = isAssignable(c, n)
  if valid != arLValue:
    if valid == arLocalLValue:
      localError(n.info, errXStackEscape, renderTree(n, {renderNoComments}))
    else:
      localError(n.info, errExprHasNoAddress)
  result = newNodeIT(nkHiddenAddr, n.info, makePtrType(c, n.typ))
  result.add(n)

proc asgnToResultVar(c: PContext, n, le, ri: PNode) {.inline.} =
  if le.kind == nkHiddenDeref:
    var x = le.sons[0]
    if x.typ.kind == tyVar and x.kind == nkSym and x.sym.kind == skResult:
      n.sons[0] = x # 'result[]' --> 'result'
      n.sons[1] = takeImplicitAddr(c, ri)
      x.typ.flags.incl tfVarIsPtr

template resultTypeIsInferrable(typ: PType): expr =
  typ.isMetaType and typ.kind != tyTypeDesc

proc semAsgn(c: PContext, n: PNode): PNode =
  checkSonsLen(n, 2)
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
      result = buildOverloadedSubscripts(n.sons[0], getIdent"[]=")
      add(result, n[1])
      return semExprNoType(c, result)
  of nkCurlyExpr:
    # a{i} = x -->  `{}=`(a, i, x)
    result = buildOverloadedSubscripts(n.sons[0], getIdent"{}=")
    add(result, n[1])
    return semExprNoType(c, result)
  else:
    a = semExprWithType(c, a, {efLValue})
  n.sons[0] = a
  # a = b # both are vars, means: a[] = b[]
  # a = b # b no 'var T' means: a = addr(b)
  var le = a.typ
  if skipTypes(le, {tyGenericInst}).kind != tyVar and
      isAssignable(c, a) == arNone:
    # Direct assignment to a discriminant is allowed!
    localError(a.info, errXCannotBeAssignedTo,
               renderTree(a, {renderNoComments}))
  else:
    let
      lhs = n.sons[0]
      lhsIsResult = lhs.kind == nkSym and lhs.sym.kind == skResult
    var
      rhs = semExprWithType(c, n.sons[1],
        if lhsIsResult: {efAllowDestructor} else: {})
    if lhsIsResult:
      n.typ = enforceVoidContext
      if c.p.owner.kind != skMacro and resultTypeIsInferrable(lhs.sym.typ):
        if cmpTypes(c, lhs.typ, rhs.typ) == isGeneric:
          internalAssert c.p.resultSym != nil
          lhs.typ = rhs.typ
          c.p.resultSym.typ = rhs.typ
          c.p.owner.typ.sons[0] = rhs.typ
        else:
          typeMismatch(n, lhs.typ, rhs.typ)

    n.sons[1] = fitNode(c, le, rhs)
    fixAbstractType(c, n)
    asgnToResultVar(c, n, n.sons[0], n.sons[1])
  result = n

proc semReturn(c: PContext, n: PNode): PNode =
  result = n
  checkSonsLen(n, 1)
  if c.p.owner.kind in {skConverter, skMethod, skProc, skMacro,
                        skClosureIterator}:
    if n.sons[0].kind != nkEmpty:
      # transform ``return expr`` to ``result = expr; return``
      if c.p.resultSym != nil:
        var a = newNodeI(nkAsgn, n.sons[0].info)
        addSon(a, newSymNode(c.p.resultSym))
        addSon(a, n.sons[0])
        n.sons[0] = semAsgn(c, a)
        # optimize away ``result = result``:
        if n[0][1].kind == nkSym and n[0][1].sym == c.p.resultSym:
          n.sons[0] = ast.emptyNode
      else:
        localError(n.info, errNoReturnTypeDeclared)
  else:
    localError(n.info, errXNotAllowedHere, "\'return\'")

proc semProcBody(c: PContext, n: PNode): PNode =
  openScope(c)

  result = semExpr(c, n)
  if c.p.resultSym != nil and not isEmptyType(result.typ):
    # transform ``expr`` to ``result = expr``, but not if the expr is already
    # ``result``:
    if result.kind == nkSym and result.sym == c.p.resultSym:
      discard
    elif result.kind == nkNilLit:
      # or ImplicitlyDiscardable(result):
      # new semantic: 'result = x' triggers the void context
      result.typ = nil
    elif result.kind == nkStmtListExpr and result.typ.kind == tyNil:
      # to keep backwards compatibility bodies like:
      #   nil
      #   # comment
      # are not expressions:
      fixNilType(result)
    else:
      var a = newNodeI(nkAsgn, n.info, 2)
      a.sons[0] = newSymNode(c.p.resultSym)
      a.sons[1] = result
      result = semAsgn(c, a)
  else:
    discardCheck(c, result)

  if c.p.owner.kind notin {skMacro, skTemplate} and
     c.p.resultSym != nil and c.p.resultSym.typ.isMetaType:
    if isEmptyType(result.typ):
      # we inferred a 'void' return type:
      c.p.resultSym.typ = nil
      c.p.owner.typ.sons[0] = nil
    else:
      localError(c.p.resultSym.info, errCannotInferReturnType)

  closeScope(c)

proc semYieldVarResult(c: PContext, n: PNode, restype: PType) =
  var t = skipTypes(restype, {tyGenericInst})
  case t.kind
  of tyVar:
    n.sons[0] = takeImplicitAddr(c, n.sons[0])
  of tyTuple:
    for i in 0.. <t.sonsLen:
      var e = skipTypes(t.sons[i], {tyGenericInst})
      if e.kind == tyVar:
        if n.sons[0].kind == nkPar:
          n.sons[0].sons[i] = takeImplicitAddr(c, n.sons[0].sons[i])
        elif n.sons[0].kind in {nkHiddenStdConv, nkHiddenSubConv} and
             n.sons[0].sons[1].kind == nkPar:
          var a = n.sons[0].sons[1]
          a.sons[i] = takeImplicitAddr(c, a.sons[i])
        else:
          localError(n.sons[0].info, errXExpected, "tuple constructor")
  else: discard

proc semYield(c: PContext, n: PNode): PNode =
  result = n
  checkSonsLen(n, 1)
  if c.p.owner == nil or c.p.owner.kind notin skIterators:
    localError(n.info, errYieldNotAllowedHere)
  elif c.p.inTryStmt > 0 and c.p.owner.typ.callConv != ccInline:
    localError(n.info, errYieldNotAllowedInTryStmt)
  elif n.sons[0].kind != nkEmpty:
    n.sons[0] = semExprWithType(c, n.sons[0]) # check for type compatibility:
    var iterType = c.p.owner.typ
    let restype = iterType.sons[0]
    if restype != nil:
      let adjustedRes = if restype.kind == tyIter: restype.base
                        else: restype
      if adjustedRes.kind != tyExpr:
        n.sons[0] = fitNode(c, adjustedRes, n.sons[0])
      if n.sons[0].typ == nil: internalError(n.info, "semYield")

      if resultTypeIsInferrable(adjustedRes):
        let inferred = n.sons[0].typ
        if restype.kind == tyIter:
          restype.sons[0] = inferred
        else:
          iterType.sons[0] = inferred

      semYieldVarResult(c, n, adjustedRes)
    else:
      localError(n.info, errCannotReturnExpr)
  elif c.p.owner.typ.sons[0] != nil:
    localError(n.info, errGenerated, "yield statement must yield a value")

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
    checkSonsLen(n, 2)
    var m = lookUpForDefined(c, n.sons[0], onlyCurrentScope)
    if m != nil and m.kind == skModule:
      let ident = considerQuotedIdent(n[1])
      if m == c.module:
        result = strTableGet(c.topLevelScope.symbols, ident)
      else:
        result = strTableGet(m.tab, ident)
  of nkAccQuoted:
    result = lookUpForDefined(c, considerQuotedIdent(n), onlyCurrentScope)
  of nkSym:
    result = n.sym
  of nkOpenSymChoice, nkClosedSymChoice:
    result = n.sons[0].sym
  else:
    localError(n.info, errIdentifierExpected, renderTree(n))
    result = nil

proc semDefined(c: PContext, n: PNode, onlyCurrentScope: bool): PNode =
  checkSonsLen(n, 2)
  # we replace this node by a 'true' or 'false' node:
  result = newIntNode(nkIntLit, 0)
  if not onlyCurrentScope and considerQuotedIdent(n[0]).s == "defined":
    if n.sons[1].kind != nkIdent:
      localError(n.info, "obsolete usage of 'defined', use 'declared' instead")
    elif condsyms.isDefined(n.sons[1].ident):
      result.intVal = 1
  elif lookUpForDefined(c, n.sons[1], onlyCurrentScope) != nil:
    result.intVal = 1
  result.info = n.info
  result.typ = getSysType(tyBool)

proc expectMacroOrTemplateCall(c: PContext, n: PNode): PSym =
  ## The argument to the proc should be nkCall(...) or similar
  ## Returns the macro/template symbol
  if isCallExpr(n):
    var expandedSym = qualifiedLookUp(c, n[0], {checkUndeclared})
    if expandedSym == nil:
      localError(n.info, errUndeclaredIdentifier, n[0].renderTree)
      return errorSym(c, n[0])

    if expandedSym.kind notin {skMacro, skTemplate}:
      localError(n.info, errXisNoMacroOrTemplate, expandedSym.name.s)
      return errorSym(c, n[0])

    result = expandedSym
  else:
    localError(n.info, errXisNoMacroOrTemplate, n.renderTree)
    result = errorSym(c, n)

proc expectString(c: PContext, n: PNode): string =
  var n = semConstExpr(c, n)
  if n.kind in nkStrKinds:
    return n.strVal
  else:
    localError(n.info, errStringLiteralExpected)

proc getMagicSym(magic: TMagic): PSym =
  result = newSym(skProc, getIdent($magic), systemModule, gCodegenLineInfo)
  result.magic = magic

proc newAnonSym(kind: TSymKind, info: TLineInfo,
                owner = getCurrOwner()): PSym =
  result = newSym(kind, idAnon, owner, info)
  result.flags = {sfGenSym}

proc semUsing(c: PContext, n: PNode): PNode =
  result = newNodeI(nkEmpty, n.info)
  if not experimentalMode(c):
    localError(n.info, "use the {.experimental.} pragma to enable 'using'")
  for e in n.sons:
    let usedSym = semExpr(c, e)
    if usedSym.kind == nkSym:
      case usedSym.sym.kind
      of skLocalVars + {skConst}:
        c.currentScope.usingSyms.safeAdd(usedSym)
        continue
      of skProcKinds:
        addDeclAt(c.currentScope, usedSym.sym)
        continue
      else: discard

    localError(e.info, errUsingNoSymbol, e.renderTree)

proc semExpandToAst(c: PContext, n: PNode): PNode =
  var macroCall = n[1]
  var expandedSym = expectMacroOrTemplateCall(c, macroCall)
  if expandedSym.kind == skError: return n

  macroCall.sons[0] = newSymNode(expandedSym, macroCall.info)
  markUsed(n.info, expandedSym)
  styleCheckUse(n.info, expandedSym)

  for i in countup(1, macroCall.len-1):
    macroCall.sons[i] = semExprWithType(c, macroCall[i], {})

  # Preserve the magic symbol in order to be handled in evals.nim
  internalAssert n.sons[0].sym.magic == mExpandToAst
  #n.typ = getSysSym("PNimrodNode").typ # expandedSym.getReturnType
  n.typ = if getCompilerProc("NimNode") != nil: sysTypeFromName"NimNode"
          else: sysTypeFromName"PNimrodNode"
  result = n

proc semExpandToAst(c: PContext, n: PNode, magicSym: PSym,
                    flags: TExprFlags = {}): PNode =
  if sonsLen(n) == 2:
    n.sons[0] = newSymNode(magicSym, n.info)
    result = semExpandToAst(c, n)
  else:
    result = semDirectOp(c, n, flags)

proc processQuotations(n: var PNode, op: string,
                       quotes: var seq[PNode],
                       ids: var seq[PNode]) =
  template returnQuote(q) =
    quotes.add q
    n = newIdentNode(getIdent($quotes.len), n.info)
    ids.add n
    return

  if n.kind == nkPrefix:
    checkSonsLen(n, 2)
    if n[0].kind == nkIdent:
      var examinedOp = n[0].ident.s
      if examinedOp == op:
        returnQuote n[1]
      elif examinedOp.startsWith(op):
        n.sons[0] = newIdentNode(getIdent(examinedOp.substr(op.len)), n.info)
  elif n.kind == nkAccQuoted and op == "``":
    returnQuote n[0]

  for i in 0 .. <n.safeLen:
    processQuotations(n.sons[i], op, quotes, ids)

proc semQuoteAst(c: PContext, n: PNode): PNode =
  internalAssert n.len == 2 or n.len == 3
  # We transform the do block into a template with a param for
  # each interpolation. We'll pass this template to getAst.
  var
    doBlk = n{-1}
    op = if n.len == 3: expectString(c, n[1]) else: "``"
    quotes = newSeq[PNode](1)
      # the quotes will be added to a nkCall statement
      # leave some room for the callee symbol
    ids = newSeq[PNode]()
      # this will store the generated param names

  if doBlk.kind != nkDo:
    localError(n.info, errXExpected, "block")

  processQuotations(doBlk.sons[bodyPos], op, quotes, ids)

  doBlk.sons[namePos] = newAnonSym(skTemplate, n.info).newSymNode
  if ids.len > 0:
    doBlk.sons[paramsPos] = newNodeI(nkFormalParams, n.info)
    doBlk[paramsPos].add getSysSym("stmt").newSymNode # return type
    ids.add getSysSym("expr").newSymNode # params type
    ids.add emptyNode # no default value
    doBlk[paramsPos].add newNode(nkIdentDefs, n.info, ids)

  var tmpl = semTemplateDef(c, doBlk)
  quotes[0] = tmpl[namePos]
  result = newNode(nkCall, n.info, @[
    getMagicSym(mExpandToAst).newSymNode,
    newNode(nkCall, n.info, quotes)])
  result = semExpandToAst(c, result)

proc tryExpr(c: PContext, n: PNode, flags: TExprFlags = {}): PNode =
  # watch out, hacks ahead:
  let oldErrorCount = msgs.gErrorCounter
  let oldErrorMax = msgs.gErrorMax
  inc c.inCompilesContext
  # do not halt after first error:
  msgs.gErrorMax = high(int)

  # open a scope for temporary symbol inclusions:
  let oldScope = c.currentScope
  openScope(c)
  let oldOwnerLen = len(gOwners)
  let oldGenerics = c.generics
  let oldErrorOutputs = errorOutputs
  errorOutputs = {}
  let oldContextLen = msgs.getInfoContextLen()

  let oldInGenericContext = c.inGenericContext
  let oldInUnrolledContext = c.inUnrolledContext
  let oldInGenericInst = c.inGenericInst
  let oldProcCon = c.p
  c.generics = @[]
  try:
    result = semExpr(c, n, flags)
    if msgs.gErrorCounter != oldErrorCount: result = nil
  except ERecoverableError:
    discard
  # undo symbol table changes (as far as it's possible):
  c.generics = oldGenerics
  c.inGenericContext = oldInGenericContext
  c.inUnrolledContext = oldInUnrolledContext
  c.inGenericInst = oldInGenericInst
  c.p = oldProcCon
  msgs.setInfoContextLen(oldContextLen)
  setLen(gOwners, oldOwnerLen)
  c.currentScope = oldScope
  dec c.inCompilesContext
  errorOutputs = oldErrorOutputs
  msgs.gErrorCounter = oldErrorCount
  msgs.gErrorMax = oldErrorMax

proc semCompiles(c: PContext, n: PNode, flags: TExprFlags): PNode =
  # we replace this node by a 'true' or 'false' node:
  if sonsLen(n) != 2: return semDirectOp(c, n, flags)

  result = newIntNode(nkIntLit, ord(tryExpr(c, n[1], flags) != nil))
  result.info = n.info
  result.typ = getSysType(tyBool)

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
  addSonSkipIntLit(result, magicsys.getCompilerProc("FlowVar").typ)
  addSonSkipIntLit(result, t)
  result = instGenericContainer(c, info, result, allowMetaTypes = false)

proc instantiateCreateFlowVarCall(c: PContext; t: PType;
                                  info: TLineInfo): PSym =
  let sym = magicsys.getCompilerProc("nimCreateFlowVar")
  if sym == nil:
    localError(info, errSystemNeeds, "nimCreateFlowVar")
  var bindings: TIdTable
  initIdTable(bindings)
  bindings.idTablePut(sym.ast[genericParamsPos].sons[0].typ, t)
  result = c.semGenerateInstance(c, sym, bindings, info)
  # since it's an instantiation, we unmark it as a compilerproc. Otherwise
  # codegen would fail:
  if sfCompilerProc in result.flags:
    result.flags = result.flags - {sfCompilerProc, sfExportC, sfImportC}
    result.loc.r = nil

proc setMs(n: PNode, s: PSym): PNode =
  result = n
  n.sons[0] = newSymNode(s)
  n.sons[0].info = n.info

proc semMagic(c: PContext, n: PNode, s: PSym, flags: TExprFlags): PNode =
  # this is a hotspot in the compiler!
  # DON'T forget to update ast.SpecialSemMagics if you add a magic here!
  result = n
  case s.magic # magics that need special treatment
  of mAddr:
    checkSonsLen(n, 2)
    result = semAddr(c, n.sons[1])
  of mTypeOf:
    checkSonsLen(n, 2)
    result = semTypeOf(c, n.sons[1])
  of mDefined: result = semDefined(c, setMs(n, s), false)
  of mDefinedInScope: result = semDefined(c, setMs(n, s), true)
  of mCompiles: result = semCompiles(c, setMs(n, s), flags)
  of mLow: result = semLowHigh(c, setMs(n, s), mLow)
  of mHigh: result = semLowHigh(c, setMs(n, s), mHigh)
  of mSizeOf: result = semSizeof(c, setMs(n, s))
  of mIs: result = semIs(c, setMs(n, s))
  of mOf: result = semOf(c, setMs(n, s))
  of mShallowCopy: result = semShallowCopy(c, n, flags)
  of mExpandToAst: result = semExpandToAst(c, n, s, flags)
  of mQuoteAst: result = semQuoteAst(c, n)
  of mAstToStr:
    checkSonsLen(n, 2)
    result = newStrNodeT(renderTree(n[1], {renderNoComments}), n)
    result.typ = getSysType(tyString)
  of mParallel:
    result = setMs(n, s)
    var x = n.lastSon
    if x.kind == nkDo: x = x.sons[bodyPos]
    inc c.inParallelStmt
    result.sons[1] = semStmt(c, x)
    dec c.inParallelStmt
  of mSpawn:
    result = setMs(n, s)
    result.sons[1] = semExpr(c, n.sons[1])
    if not result[1].typ.isEmptyType:
      if spawnResult(result[1].typ, c.inParallelStmt > 0) == srFlowVar:
        result.typ = createFlowVar(c, result[1].typ, n.info)
      else:
        result.typ = result[1].typ
      result.add instantiateCreateFlowVarCall(c, result[1].typ, n.info).newSymNode
  of mProcCall:
    result = setMs(n, s)
    result.sons[1] = semExpr(c, n.sons[1])
    result.typ = n[1].typ
  else: result = semDirectOp(c, n, flags)

proc semWhen(c: PContext, n: PNode, semCheck = true): PNode =
  # If semCheck is set to false, ``when`` will return the verbatim AST of
  # the correct branch. Otherwise the AST will be passed through semStmt.
  result = nil

  template setResult(e: expr) =
    if semCheck: result = semStmt(c, e) # do not open a new scope!
    else: result = e

  for i in countup(0, sonsLen(n) - 1):
    var it = n.sons[i]
    case it.kind
    of nkElifBranch, nkElifExpr:
      checkSonsLen(it, 2)
      var e = semConstExpr(c, it.sons[0])
      if e.kind != nkIntLit:
        # can happen for cascading errors, assume false
        # InternalError(n.info, "semWhen")
        discard
      elif e.intVal != 0 and result == nil:
        setResult(it.sons[1])
    of nkElse, nkElseExpr:
      checkSonsLen(it, 1)
      if result == nil:
        setResult(it.sons[0])
    else: illFormedAst(n)
  if result == nil:
    result = newNodeI(nkEmpty, n.info)
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
    for i in countup(0, sonsLen(n) - 1):
      if isRange(n.sons[i]):
        checkSonsLen(n.sons[i], 3)
        n.sons[i].sons[1] = semExprWithType(c, n.sons[i].sons[1])
        n.sons[i].sons[2] = semExprWithType(c, n.sons[i].sons[2])
        if typ == nil:
          typ = skipTypes(n.sons[i].sons[1].typ,
                          {tyGenericInst, tyVar, tyOrdinal})
        n.sons[i].typ = n.sons[i].sons[2].typ # range node needs type too
      elif n.sons[i].kind == nkRange:
        # already semchecked
        if typ == nil:
          typ = skipTypes(n.sons[i].sons[0].typ,
                          {tyGenericInst, tyVar, tyOrdinal})
      else:
        n.sons[i] = semExprWithType(c, n.sons[i])
        if typ == nil:
          typ = skipTypes(n.sons[i].typ, {tyGenericInst, tyVar, tyOrdinal})
    if not isOrdinalType(typ):
      localError(n.info, errOrdinalTypeExpected)
      typ = makeRangeType(c, 0, MaxSetElements-1, n.info)
    elif lengthOrd(typ) > MaxSetElements:
      typ = makeRangeType(c, 0, MaxSetElements-1, n.info)
    addSonSkipIntLit(result.typ, typ)
    for i in countup(0, sonsLen(n) - 1):
      var m: PNode
      if isRange(n.sons[i]):
        m = newNodeI(nkRange, n.sons[i].info)
        addSon(m, fitNode(c, typ, n.sons[i].sons[1]))
        addSon(m, fitNode(c, typ, n.sons[i].sons[2]))
      elif n.sons[i].kind == nkRange: m = n.sons[i] # already semchecked
      else:
        m = fitNode(c, typ, n.sons[i])
      addSon(result, m)

proc semTableConstr(c: PContext, n: PNode): PNode =
  # we simply transform ``{key: value, key2, key3: value}`` to
  # ``[(key, value), (key2, value2), (key3, value2)]``
  result = newNodeI(nkBracket, n.info)
  var lastKey = 0
  for i in 0..n.len-1:
    var x = n.sons[i]
    if x.kind == nkExprColonExpr and sonsLen(x) == 2:
      for j in countup(lastKey, i-1):
        var pair = newNodeI(nkPar, x.info)
        pair.add(n.sons[j])
        pair.add(x[1])
        result.add(pair)

      var pair = newNodeI(nkPar, x.info)
      pair.add(x[0])
      pair.add(x[1])
      result.add(pair)

      lastKey = i+1

  if lastKey != n.len: illFormedAst(n)
  result = semExpr(c, result)

type
  TParKind = enum
    paNone, paSingle, paTupleFields, paTuplePositions

proc checkPar(n: PNode): TParKind =
  var length = sonsLen(n)
  if length == 0:
    result = paTuplePositions # ()
  elif length == 1:
    if n.sons[0].kind == nkExprColonExpr: result = paTupleFields
    else: result = paSingle         # (expr)
  else:
    if n.sons[0].kind == nkExprColonExpr: result = paTupleFields
    else: result = paTuplePositions
    for i in countup(0, length - 1):
      if result == paTupleFields:
        if (n.sons[i].kind != nkExprColonExpr) or
            not (n.sons[i].sons[0].kind in {nkSym, nkIdent}):
          localError(n.sons[i].info, errNamedExprExpected)
          return paNone
      else:
        if n.sons[i].kind == nkExprColonExpr:
          localError(n.sons[i].info, errNamedExprNotAllowed)
          return paNone

proc semTupleFieldsConstr(c: PContext, n: PNode, flags: TExprFlags): PNode =
  result = newNodeI(nkPar, n.info)
  var typ = newTypeS(tyTuple, c)
  typ.n = newNodeI(nkRecList, n.info) # nkIdentDefs
  var ids = initIntSet()
  for i in countup(0, sonsLen(n) - 1):
    if n[i].kind != nkExprColonExpr or n[i][0].kind notin {nkSym, nkIdent}:
      illFormedAst(n.sons[i])
    var id: PIdent
    if n.sons[i].sons[0].kind == nkIdent: id = n.sons[i].sons[0].ident
    else: id = n.sons[i].sons[0].sym.name
    if containsOrIncl(ids, id.id):
      localError(n.sons[i].info, errFieldInitTwice, id.s)
    n.sons[i].sons[1] = semExprWithType(c, n.sons[i].sons[1],
                                        flags*{efAllowDestructor})
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
  var typ = newTypeS(tyTuple, c)  # leave typ.n nil!
  for i in countup(0, sonsLen(n) - 1):
    n.sons[i] = semExprWithType(c, n.sons[i], flags*{efAllowDestructor})
    addSonSkipIntLit(typ, n.sons[i].typ)
  result.typ = typ

proc isTupleType(n: PNode): bool =
  if n.len == 0:
    return false # don't interpret () as type
  for i in countup(0, n.len - 1):
    if n[i].typ == nil or n[i].typ.kind != tyTypeDesc:
      return false
  return true

proc checkInitialized(n: PNode, ids: IntSet, info: TLineInfo) =
  case n.kind
  of nkRecList:
    for i in countup(0, sonsLen(n) - 1):
      checkInitialized(n.sons[i], ids, info)
  of nkRecCase:
    if (n.sons[0].kind != nkSym): internalError(info, "checkInitialized")
    checkInitialized(n.sons[0], ids, info)
    when false:
      # XXX we cannot check here, as we don't know the branch!
      for i in countup(1, sonsLen(n) - 1):
        case n.sons[i].kind
        of nkOfBranch, nkElse: checkInitialized(lastSon(n.sons[i]), ids, info)
        else: internalError(info, "checkInitialized")
  of nkSym:
    if tfNeedsInit in n.sym.typ.flags and n.sym.name.id notin ids:
      message(info, errGenerated, "field not initialized: " & n.sym.name.s)
  else: internalError(info, "checkInitialized")

proc semObjConstr(c: PContext, n: PNode, flags: TExprFlags): PNode =
  var t = semTypeNode(c, n.sons[0], nil)
  result = n
  result.typ = t
  result.kind = nkObjConstr
  t = skipTypes(t, {tyGenericInst})
  if t.kind == tyRef: t = skipTypes(t.sons[0], {tyGenericInst})
  if t.kind != tyObject:
    localError(n.info, errGenerated, "object constructor needs an object type")
    return
  var objType = t
  var ids = initIntSet()
  for i in 1.. <n.len:
    let it = n.sons[i]
    if it.kind != nkExprColonExpr:
      localError(n.info, errNamedExprExpected)
      break
    let id = considerQuotedIdent(it.sons[0])

    if containsOrIncl(ids, id.id):
      localError(it.info, errFieldInitTwice, id.s)
    var e = semExprWithType(c, it.sons[1], flags*{efAllowDestructor})
    var
      check: PNode = nil
      f: PSym
    t = objType
    while true:
      check = nil
      f = lookupInRecordAndBuildCheck(c, it, t.n, id, check)
      if f != nil: break
      if t.sons[0] == nil: break
      t = skipTypes(t.sons[0], {tyGenericInst})
    if f != nil and fieldVisible(c, f):
      it.sons[0] = newSymNode(f)
      e = fitNode(c, f.typ, e)
      # small hack here in a nkObjConstr the ``nkExprColonExpr`` node can have
      # 3 children the last being the field check
      if check != nil:
        check.sons[0] = it.sons[0]
        it.add(check)
    else:
      localError(it.info, errUndeclaredFieldX, id.s)
    it.sons[1] = e
    # XXX object field name check for 'case objects' if the kind is static?
  if tfNeedsInit in objType.flags:
    while true:
      checkInitialized(objType.n, ids, n.info)
      if objType.sons[0] == nil: break
      objType = skipTypes(objType.sons[0], {tyGenericInst})

proc semBlock(c: PContext, n: PNode): PNode =
  result = n
  inc(c.p.nestedBlockCounter)
  checkSonsLen(n, 2)
  openScope(c) # BUGFIX: label is in the scope of block!
  if n.sons[0].kind != nkEmpty:
    var labl = newSymG(skLabel, n.sons[0], c)
    if sfGenSym notin labl.flags:
      addDecl(c, labl)
      n.sons[0] = newSymNode(labl, n.sons[0].info)
    suggestSym(n.sons[0].info, labl)
    styleCheckDef(labl)
  n.sons[1] = semExpr(c, n.sons[1])
  n.typ = n.sons[1].typ
  if isEmptyType(n.typ): n.kind = nkBlockStmt
  else: n.kind = nkBlockExpr
  closeScope(c)
  dec(c.p.nestedBlockCounter)

proc semExport(c: PContext, n: PNode): PNode =
  var x = newNodeI(n.kind, n.info)
  #let L = if n.kind == nkExportExceptStmt: L = 1 else: n.len
  for i in 0.. <n.len:
    let a = n.sons[i]
    var o: TOverloadIter
    var s = initOverloadIter(o, c, a)
    if s == nil:
      localError(a.info, errGenerated, "cannot export: " & renderTree(a))
    elif s.kind == skModule:
      # forward everything from that module:
      strTableAdd(c.module.tab, s)
      x.add(newSymNode(s, a.info))
      var ti: TTabIter
      var it = initTabIter(ti, s.tab)
      while it != nil:
        if it.kind in ExportableSymKinds+{skModule}:
          strTableAdd(c.module.tab, it)
        it = nextIter(ti, s.tab)
    else:
      while s != nil:
        if s.kind in ExportableSymKinds+{skModule}:
          x.add(newSymNode(s, a.info))
          strTableAdd(c.module.tab, s)
        s = nextOverloadIter(o, c, a)
  when false:
    if c.module.ast.isNil:
      c.module.ast = newNodeI(nkStmtList, n.info)
    assert c.module.ast.kind == nkStmtList
    c.module.ast.add x
  result = n

proc setGenericParams(c: PContext, n: PNode) =
  for i in 1 .. <n.len:
    n[i].typ = semTypeNode(c, n[i], nil)

proc semExpr(c: PContext, n: PNode, flags: TExprFlags = {}): PNode =
  result = n
  if gCmd == cmdIdeTools: suggestExpr(c, n)
  if nfSem in n.flags: return
  case n.kind
  of nkIdent, nkAccQuoted:
    var s = lookUp(c, n)
    if c.inTypeClass == 0: semCaptureSym(s, c.p.owner)
    result = semSym(c, n, s, flags)
    if s.kind in {skProc, skMethod, skConverter}+skIterators:
      #performProcvarCheck(c, n, s)
      result = symChoice(c, n, s, scClosed)
      if result.kind == nkSym:
        markIndirect(c, result.sym)
        # if isGenericRoutine(result.sym):
        #   localError(n.info, errInstantiateXExplicitly, s.name.s)
  of nkSym:
    # because of the changed symbol binding, this does not mean that we
    # don't have to check the symbol for semantics here again!
    result = semSym(c, n, n.sym, flags)
  of nkEmpty, nkNone, nkCommentStmt:
    discard
  of nkNilLit:
    result.typ = getSysType(tyNil)
  of nkIntLit:
    if result.typ == nil: setIntLitType(result)
  of nkInt8Lit:
    if result.typ == nil: result.typ = getSysType(tyInt8)
  of nkInt16Lit:
    if result.typ == nil: result.typ = getSysType(tyInt16)
  of nkInt32Lit:
    if result.typ == nil: result.typ = getSysType(tyInt32)
  of nkInt64Lit:
    if result.typ == nil: result.typ = getSysType(tyInt64)
  of nkUIntLit:
    if result.typ == nil: result.typ = getSysType(tyUInt)
  of nkUInt8Lit:
    if result.typ == nil: result.typ = getSysType(tyUInt8)
  of nkUInt16Lit:
    if result.typ == nil: result.typ = getSysType(tyUInt16)
  of nkUInt32Lit:
    if result.typ == nil: result.typ = getSysType(tyUInt32)
  of nkUInt64Lit:
    if result.typ == nil: result.typ = getSysType(tyUInt64)
  of nkFloatLit:
    if result.typ == nil: result.typ = getFloatLitType(result)
  of nkFloat32Lit:
    if result.typ == nil: result.typ = getSysType(tyFloat32)
  of nkFloat64Lit:
    if result.typ == nil: result.typ = getSysType(tyFloat64)
  of nkFloat128Lit:
    if result.typ == nil: result.typ = getSysType(tyFloat128)
  of nkStrLit..nkTripleStrLit:
    if result.typ == nil: result.typ = getSysType(tyString)
  of nkCharLit:
    if result.typ == nil: result.typ = getSysType(tyChar)
  of nkDotExpr:
    result = semFieldAccess(c, n, flags)
    if result.kind == nkDotCall:
      result.kind = nkCall
      result = semExpr(c, result, flags)
  of nkBind:
    message(n.info, warnDeprecated, "bind")
    result = semExpr(c, n.sons[0], flags)
  of nkTypeOfExpr, nkTupleTy, nkTupleClassTy, nkRefTy..nkEnumTy, nkStaticTy:
    var typ = semTypeNode(c, n, nil).skipTypes({tyTypeDesc, tyIter})
    result.typ = makeTypeDesc(c, typ)
    #result = symNodeFromType(c, typ, n.info)
  of nkCall, nkInfix, nkPrefix, nkPostfix, nkCommand, nkCallStrLit:
    # check if it is an expression macro:
    checkMinSonsLen(n, 1)
    let mode = if nfDotField in n.flags: {} else: {checkUndeclared}
    var s = qualifiedLookUp(c, n.sons[0], mode)
    if s != nil:
      #if gCmd == cmdPretty and n.sons[0].kind == nkDotExpr:
      #  pretty.checkUse(n.sons[0].sons[1].info, s)
      case s.kind
      of skMacro:
        if sfImmediate notin s.flags:
          result = semDirectOp(c, n, flags)
        else:
          result = semMacroExpr(c, n, n, s, flags)
      of skTemplate:
        if sfImmediate notin s.flags:
          result = semDirectOp(c, n, flags)
        else:
          result = semTemplateExpr(c, n, s, flags)
      of skType:
        # XXX think about this more (``set`` procs)
        if n.len == 2:
          result = semConv(c, n)
        elif n.len == 1:
          result = semObjConstr(c, n, flags)
        elif contains(c.ambiguousSymbols, s.id):
          localError(n.info, errUseQualifier, s.name.s)
        elif s.magic == mNone: result = semDirectOp(c, n, flags)
        else: result = semMagic(c, n, s, flags)
      of skProc, skMethod, skConverter, skIterators:
        if s.magic == mNone: result = semDirectOp(c, n, flags)
        else: result = semMagic(c, n, s, flags)
      else:
        #liMessage(n.info, warnUser, renderTree(n));
        result = semIndirectOp(c, n, flags)
    elif n[0].kind == nkBracketExpr and isSymChoice(n[0][0]):
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
      result = semExpr(c, result, flags)
  of nkBracketExpr:
    checkMinSonsLen(n, 1)
    var s = qualifiedLookUp(c, n.sons[0], {checkUndeclared})
    if (s != nil and s.kind in {skProc, skMethod, skConverter}+skIterators) or
        n[0].kind in nkSymChoices:
      # type parameters: partial generic specialization
      n.sons[0] = semSymGenericInstantiation(c, n.sons[0], s)
      result = explicitGenericInstantiation(c, n, s)
    elif s != nil and s.kind in {skType}:
      result = symNodeFromType(c, semTypeNode(c, n, nil), n.info)
    else:
      result = semArrayAccess(c, n, flags)
  of nkCurlyExpr:
    result = semExpr(c, buildOverloadedSubscripts(n, getIdent"{}"), flags)
  of nkPragmaExpr:
    # which pragmas are allowed for expressions? `likely`, `unlikely`
    internalError(n.info, "semExpr() to implement") # XXX: to implement
  of nkPar:
    case checkPar(n)
    of paNone: result = errorNode(c, n)
    of paTuplePositions:
      var tupexp = semTuplePositionsConstr(c, n, flags)
      if isTupleType(tupexp):
        # reinterpret as type
        var typ = semTypeNode(c, n, nil).skipTypes({tyTypeDesc, tyIter})
        result.typ = makeTypeDesc(c, typ)
      else:
        result = tupexp
    of paTupleFields: result = semTupleFieldsConstr(c, n, flags)
    of paSingle: result = semExpr(c, n.sons[0], flags)
  of nkCurly: result = semSetConstr(c, n)
  of nkBracket: result = semArrayConstr(c, n, flags)
  of nkObjConstr: result = semObjConstr(c, n, flags)
  of nkLambda: result = semLambda(c, n, flags)
  of nkDo: result = semDo(c, n, flags)
  of nkDerefExpr: result = semDeref(c, n)
  of nkAddr:
    result = n
    checkSonsLen(n, 1)
    result = semAddr(c, n.sons[0])
  of nkHiddenAddr, nkHiddenDeref:
    checkSonsLen(n, 1)
    n.sons[0] = semExpr(c, n.sons[0], flags)
  of nkCast: result = semCast(c, n)
  of nkIfExpr, nkIfStmt: result = semIf(c, n)
  of nkHiddenStdConv, nkHiddenSubConv, nkConv, nkHiddenCallConv:
    checkSonsLen(n, 2)
  of nkStringToCString, nkCStringToString, nkObjDownConv, nkObjUpConv:
    checkSonsLen(n, 1)
  of nkChckRangeF, nkChckRange64, nkChckRange:
    checkSonsLen(n, 3)
  of nkCheckedFieldExpr:
    checkMinSonsLen(n, 2)
  of nkTableConstr:
    result = semTableConstr(c, n)
  of nkClosedSymChoice, nkOpenSymChoice:
    # handling of sym choices is context dependent
    # the node is left intact for now
    discard
  of nkStaticExpr:
    result = semStaticExpr(c, n)
  of nkAsgn: result = semAsgn(c, n)
  of nkBlockStmt, nkBlockExpr: result = semBlock(c, n)
  of nkStmtList, nkStmtListExpr: result = semStmtList(c, n, flags)
  of nkRaiseStmt: result = semRaise(c, n)
  of nkVarSection: result = semVarOrLet(c, n, skVar)
  of nkLetSection: result = semVarOrLet(c, n, skLet)
  of nkConstSection: result = semConst(c, n)
  of nkTypeSection: result = semTypeSection(c, n)
  of nkDiscardStmt: result = semDiscard(c, n)
  of nkWhileStmt: result = semWhile(c, n)
  of nkTryStmt: result = semTry(c, n)
  of nkBreakStmt, nkContinueStmt: result = semBreakOrContinue(c, n)
  of nkForStmt, nkParForStmt: result = semFor(c, n)
  of nkCaseStmt: result = semCase(c, n)
  of nkReturnStmt: result = semReturn(c, n)
  of nkUsingStmt: result = semUsing(c, n)
  of nkAsmStmt: result = semAsm(c, n)
  of nkYieldStmt: result = semYield(c, n)
  of nkPragma: pragma(c, c.p.owner, n, stmtPragmas)
  of nkIteratorDef: result = semIterator(c, n)
  of nkProcDef: result = semProc(c, n)
  of nkMethodDef: result = semMethod(c, n)
  of nkConverterDef: result = semConverterDef(c, n)
  of nkMacroDef: result = semMacroDef(c, n)
  of nkTemplateDef: result = semTemplateDef(c, n)
  of nkImportStmt:
    if not isTopLevel(c): localError(n.info, errXOnlyAtModuleScope, "import")
    result = evalImport(c, n)
  of nkImportExceptStmt:
    if not isTopLevel(c): localError(n.info, errXOnlyAtModuleScope, "import")
    result = evalImportExcept(c, n)
  of nkFromStmt:
    if not isTopLevel(c): localError(n.info, errXOnlyAtModuleScope, "from")
    result = evalFrom(c, n)
  of nkIncludeStmt:
    if not isTopLevel(c): localError(n.info, errXOnlyAtModuleScope, "include")
    result = evalInclude(c, n)
  of nkExportStmt, nkExportExceptStmt:
    if not isTopLevel(c): localError(n.info, errXOnlyAtModuleScope, "export")
    result = semExport(c, n)
  of nkPragmaBlock:
    result = semPragmaBlock(c, n)
  of nkStaticStmt:
    result = semStaticStmt(c, n)
  of nkDefer:
    localError(n.info, errGenerated, "'defer' not allowed in this context")
  else:
    localError(n.info, errInvalidExpressionX,
               renderTree(n, {renderNoComments}))
  if result != nil: incl(result.flags, nfSem)
