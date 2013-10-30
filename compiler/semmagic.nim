#
#
#           The Nimrod Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This include file implements the semantic checking for magics.
# included from sem.nim

proc semIsPartOf(c: PContext, n: PNode, flags: TExprFlags): PNode =
  var r = isPartOf(n[1], n[2])
  result = newIntNodeT(ord(r), n)

proc expectIntLit(c: PContext, n: PNode): int =
  let x = c.semConstExpr(c, n)
  case x.kind
  of nkIntLit..nkInt64Lit: result = int(x.intVal)
  else: LocalError(n.info, errIntLiteralExpected)

proc semInstantiationInfo(c: PContext, n: PNode): PNode =
  result = newNodeIT(nkPar, n.info, n.typ)
  let idx = expectIntLit(c, n.sons[1])
  let useFullPaths = expectIntLit(c, n.sons[2])
  let info = getInfoContext(idx)
  var filename = newNodeIT(nkStrLit, n.info, getSysType(tyString))
  filename.strVal = if useFullPaths != 0: info.toFullPath else: info.ToFilename
  var line = newNodeIT(nkIntLit, n.info, getSysType(tyInt))
  line.intVal = ToLinenumber(info)
  result.add(filename)
  result.add(line)

proc semTypeTraits(c: PContext, n: PNode): PNode =
  checkMinSonsLen(n, 2)
  internalAssert n.sons[1].kind == nkSym
  let typArg = n.sons[1].sym
  if typArg.kind == skType or
    (typArg.kind == skParam and typArg.typ.sonsLen > 0):
    # This is either a type known to sem or a typedesc
    # param to a regular proc (again, known at instantiation)
    result = evalTypeTrait(n[0], n[1], GetCurrOwner())
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
    LocalError(n.sons[1].info, errStringLiteralExpected)
    return errorNode(c, n)

  let isMixin = semConstExpr(c, n.sons[2])
  if isMixin.kind != nkIntLit or isMixin.intVal < 0 or
      isMixin.intVal > high(TSymChoiceRule).int:
    LocalError(n.sons[2].info, errConstExprExpected)
    return errorNode(c, n)

  let id = newIdentNode(getIdent(sl.strVal), n.info)
  let s = QualifiedLookUp(c, id)
  if s != nil:
    # we need to mark all symbols:
    var sc = symChoice(c, id, s, TSymChoiceRule(isMixin.intVal))
    result.add(sc)
  else:
    LocalError(n.sons[1].info, errUndeclaredIdentifier, sl.strVal)

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
              {tyVarargs, tyOpenArray, tyTypeDesc, tyExpr, tyStmt, tyEmpty}:

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
  of mIsPartOf: result = semIsPartOf(c, n, flags)
  of mTypeTrait: result = semTypeTraits(c, n)
  of mAstToStr:
    result = newStrNodeT(renderTree(n[1], {renderNoComments}), n)
    result.typ = getSysType(tyString)
  of mInstantiationInfo: result = semInstantiationInfo(c, n)
  of mOrd: result = semOrd(c, n)
  of mHigh: result = semLowHigh(c, n, mHigh)
  of mShallowCopy: result = semShallowCopy(c, n, flags)
  of mNBindSym: result = semBindSym(c, n)
  of mLocals: result = semLocals(c, n)
  else: result = n

