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

proc semAddr(c: PContext; n: PNode): PNode =
  result = newNodeI(nkAddr, n.info)
  let x = semExprWithType(c, n)
  if isAssignable(c, x) notin {arLValue, arLocalLValue}:
    localError(n.info, errExprHasNoAddress)
  result.add x
  result.typ = makePtrType(c, x.typ)

proc semTypeOf(c: PContext; n: PNode): PNode =
  result = newNodeI(nkTypeOfExpr, n.info)
  let typExpr = semExprWithType(c, n, {efInTypeof})
  result.add typExpr
  result.typ = makeTypeDesc(c, typExpr.typ.skipTypes({tyTypeDesc, tyIter}))

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
    result = newIntNode(nkIntLit, typ.n.len-1)
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
  result.typ = makeRangeType(c, firstOrd(n.sons[1].typ),
                                lastOrd(n.sons[1].typ), n.info)

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
  let s = qualifiedLookUp(c, id)
  if s != nil:
    # we need to mark all symbols:
    var sc = symChoice(c, id, s, TSymChoiceRule(isMixin.intVal))
    result.add(sc)
  else:
    localError(n.sons[1].info, errUndeclaredIdentifier, sl.strVal)

proc semLocals(c: PContext, n: PNode): PNode =
  var counter = 0
  var tupleType = newTypeS(tyTuple, c)
  result = newNodeIT(nkPar, n.info, tupleType)
  tupleType.n = newNodeI(nkRecList, n.info)
  # for now we skip openarrays ...
  for scope in walkScopes(c.currentScope):
    if scope == c.topLevelScope: break
    for it in items(scope.symbols):
      # XXX parameters' owners are wrong for generics; this caused some pain
      # for closures too; we should finally fix it.
      #if it.owner != c.p.owner: return result
      if it.kind in skLocalVars and
          it.typ.skipTypes({tyGenericInst, tyVar}).kind notin
            {tyVarargs, tyOpenArray, tyTypeDesc, tyStatic, tyExpr, tyStmt, tyEmpty}:

        var field = newSym(skField, it.name, getCurrOwner(), n.info)
        field.typ = it.typ.skipTypes({tyGenericInst, tyVar})
        field.position = counter
        inc(counter)

        addSon(tupleType.n, newSymNode(field))
        addSonSkipIntLit(tupleType, field.typ)

        var a = newSymNode(it, result.info)
        if it.typ.skipTypes({tyGenericInst}).kind == tyVar: a = newDeref(a)
        result.add(a)

proc semShallowCopy(c: PContext, n: PNode, flags: TExprFlags): PNode
proc magicsAfterOverloadResolution(c: PContext, n: PNode,
                                   flags: TExprFlags): PNode =
  case n[0].sym.magic
  of mAddr:
    checkSonsLen(n, 2)
    result = semAddr(c, n.sons[1])
  of mTypeOf:
    checkSonsLen(n, 2)
    result = semTypeOf(c, n.sons[1])
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
  of mLocals: result = semLocals(c, n)
  of mProcCall:
    result = n
    result.typ = n[1].typ
  else: result = n
