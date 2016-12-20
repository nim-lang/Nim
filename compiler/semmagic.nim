#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This include file implements the semantic checking for magics.
# included from sem.nim

proc semAddr(c: PContext; n: PNode; isUnsafeAddr=false): PNode =
  result = newNodeI(nkAddr, n.info)
  let x = semExprWithType(c, n)
  if x.kind == nkSym:
    x.sym.flags.incl(sfAddrTaken)
  if isAssignable(c, x, isUnsafeAddr) notin {arLValue, arLocalLValue}:
    localError(n.info, errExprHasNoAddress)
  result.add x
  result.typ = makePtrType(c, x.typ)

proc semTypeOf(c: PContext; n: PNode): PNode =
  result = newNodeI(nkTypeOfExpr, n.info)
  let typExpr = semExprWithType(c, n, {efInTypeof})
  result.add typExpr
  result.typ = makeTypeDesc(c, typExpr.typ.skipTypes({tyTypeDesc}))

type
  SemAsgnMode = enum asgnNormal, noOverloadedSubscript, noOverloadedAsgn

proc semAsgn(c: PContext, n: PNode; mode=asgnNormal): PNode
proc semSubscript(c: PContext, n: PNode, flags: TExprFlags): PNode

proc skipAddr(n: PNode): PNode {.inline.} =
  (if n.kind == nkHiddenAddr: n.sons[0] else: n)

proc semArrGet(c: PContext; n: PNode; flags: TExprFlags): PNode =
  result = newNodeI(nkBracketExpr, n.info)
  for i in 1..<n.len: result.add(n[i])
  let oldBracketExpr = c.p.bracketExpr
  result = semSubscript(c, result, flags)
  c.p.bracketExpr = oldBracketExpr
  if result.isNil:
    let x = copyTree(n)
    x.sons[0] = newIdentNode(getIdent"[]", n.info)
    bracketNotFoundError(c, x)
    #localError(n.info, "could not resolve: " & $n)
    result = n

proc semArrPut(c: PContext; n: PNode; flags: TExprFlags): PNode =
  # rewrite `[]=`(a, i, x)  back to ``a[i] = x``.
  let b = newNodeI(nkBracketExpr, n.info)
  b.add(n[1].skipAddr)
  for i in 2..n.len-2: b.add(n[i])
  result = newNodeI(nkAsgn, n.info, 2)
  result.sons[0] = b
  result.sons[1] = n.lastSon
  result = semAsgn(c, result, noOverloadedSubscript)

proc semAsgnOpr(c: PContext; n: PNode): PNode =
  result = newNodeI(nkAsgn, n.info, 2)
  result.sons[0] = n[1]
  result.sons[1] = n[2]
  result = semAsgn(c, result, noOverloadedAsgn)

proc semIsPartOf(c: PContext, n: PNode, flags: TExprFlags): PNode =
  var r = isPartOf(n[1], n[2])
  result = newIntNodeT(ord(r), n)

proc expectIntLit(c: PContext, n: PNode): int =
  let x = c.semConstExpr(c, n)
  case x.kind
  of nkIntLit..nkInt64Lit: result = int(x.intVal)
  else: localError(n.info, errIntLiteralExpected)

proc semInstantiationInfo(c: PContext, n: PNode): PNode =
  result = newNodeIT(nkPar, n.info, n.typ)
  let idx = expectIntLit(c, n.sons[1])
  let useFullPaths = expectIntLit(c, n.sons[2])
  let info = getInfoContext(idx)
  var filename = newNodeIT(nkStrLit, n.info, getSysType(tyString))
  filename.strVal = if useFullPaths != 0: info.toFullPath else: info.toFilename
  var line = newNodeIT(nkIntLit, n.info, getSysType(tyInt))
  line.intVal = toLinenumber(info)
  result.add(filename)
  result.add(line)

proc evalTypeTrait(trait: PNode, operand: PType, context: PSym): PNode =
  let typ = operand.skipTypes({tyTypeDesc})
  case trait.sym.name.s.normalize
  of "name":
    result = newStrNode(nkStrLit, typ.typeToString(preferName))
    result.typ = newType(tyString, context)
    result.info = trait.info
  of "arity":
    result = newIntNode(nkIntLit, typ.len - ord(typ.kind==tyProc))
    result.typ = newType(tyInt, context)
    result.info = trait.info
  else:
    internalAssert false

proc semTypeTraits(c: PContext, n: PNode): PNode =
  checkMinSonsLen(n, 2)
  let t = n.sons[1].typ
  internalAssert t != nil and t.kind == tyTypeDesc
  if t.sonsLen > 0:
    # This is either a type known to sem or a typedesc
    # param to a regular proc (again, known at instantiation)
    result = evalTypeTrait(n[0], t, getCurrOwner())
  else:
    # a typedesc variable, pass unmodified to evals
    result = n

proc semOrd(c: PContext, n: PNode): PNode =
  result = n
  let parType = n.sons[1].typ
  if isOrdinalType(parType) or parType.kind == tySet:
    result.typ = makeRangeType(c, firstOrd(parType), lastOrd(parType), n.info)
  else:
    localError(n.info, errOrdinalTypeExpected)
    result.typ = errorType(c)

proc semBindSym(c: PContext, n: PNode): PNode =
  result = copyNode(n)
  result.add(n.sons[0])

  let sl = semConstExpr(c, n.sons[1])
  if sl.kind notin {nkStrLit, nkRStrLit, nkTripleStrLit}:
    localError(n.sons[1].info, errStringLiteralExpected)
    return errorNode(c, n)

  let isMixin = semConstExpr(c, n.sons[2])
  if isMixin.kind != nkIntLit or isMixin.intVal < 0 or
      isMixin.intVal > high(TSymChoiceRule).int:
    localError(n.sons[2].info, errConstExprExpected)
    return errorNode(c, n)

  let id = newIdentNode(getIdent(sl.strVal), n.info)
  let s = qualifiedLookUp(c, id, {checkUndeclared})
  if s != nil:
    # we need to mark all symbols:
    var sc = symChoice(c, id, s, TSymChoiceRule(isMixin.intVal))
    result.add(sc)
  else:
    errorUndeclaredIdentifier(c, n.sons[1].info, sl.strVal)

proc semShallowCopy(c: PContext, n: PNode, flags: TExprFlags): PNode

proc isStrangeArray(t: PType): bool =
  let t = t.skipTypes(abstractInst)
  result = t.kind == tyArray and t.firstOrd != 0

proc magicsAfterOverloadResolution(c: PContext, n: PNode,
                                   flags: TExprFlags): PNode =
  case n[0].sym.magic
  of mAddr:
    checkSonsLen(n, 2)
    result = semAddr(c, n.sons[1], n[0].sym.name.s == "unsafeAddr")
  of mTypeOf:
    checkSonsLen(n, 2)
    result = semTypeOf(c, n.sons[1])
  of mArrGet: result = semArrGet(c, n, flags)
  of mArrPut: result = semArrPut(c, n, flags)
  of mAsgn: result = semAsgnOpr(c, n)
  of mIsPartOf: result = semIsPartOf(c, n, flags)
  of mTypeTrait: result = semTypeTraits(c, n)
  of mAstToStr:
    result = newStrNodeT(renderTree(n[1], {renderNoComments}), n)
    result.typ = getSysType(tyString)
  of mInstantiationInfo: result = semInstantiationInfo(c, n)
  of mOrd: result = semOrd(c, n)
  of mHigh, mLow: result = semLowHigh(c, n, n[0].sym.magic)
  of mShallowCopy: result = semShallowCopy(c, n, flags)
  of mNBindSym: result = semBindSym(c, n)
  of mProcCall:
    result = n
    result.typ = n[1].typ
  of mDotDot:
    result = n
  of mRoof:
    let bracketExpr = if n.len == 3: n.sons[2] else: c.p.bracketExpr
    if bracketExpr.isNil:
      localError(n.info, "no surrounding array access context for '^'")
      result = n.sons[1]
    elif bracketExpr.checkForSideEffects != seNoSideEffect:
      localError(n.info, "invalid context for '^' as '$#' has side effects" %
        renderTree(bracketExpr))
      result = n.sons[1]
    elif bracketExpr.typ.isStrangeArray:
      localError(n.info, "invalid context for '^' as len!=high+1 for '$#'" %
        renderTree(bracketExpr))
      result = n.sons[1]
    else:
      # ^x  is rewritten to: len(a)-x
      let lenExpr = newNodeI(nkCall, n.info)
      lenExpr.add newIdentNode(getIdent"len", n.info)
      lenExpr.add bracketExpr
      let lenExprB = semExprWithType(c, lenExpr)
      if lenExprB.typ.isNil or not isOrdinalType(lenExprB.typ):
        localError(n.info, "'$#' has to be of an ordinal type for '^'" %
          renderTree(lenExpr))
        result = n.sons[1]
      else:
        result = newNodeIT(nkCall, n.info, getSysType(tyInt))
        let subi = getSysMagic("-", mSubI)
        #echo "got ", typeToString(subi.typ)
        result.add newSymNode(subi, n.info)
        result.add lenExprB
        result.add n.sons[1]
  of mPlugin:
    let plugin = getPlugin(n[0].sym)
    if plugin.isNil:
      localError(n.info, "cannot find plugin " & n[0].sym.name.s)
      result = n
    else:
      result = plugin(c, n)
  else: result = n
