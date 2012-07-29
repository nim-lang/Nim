#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
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
  let info = getInfoContext(idx)
  var filename = newNodeIT(nkStrLit, n.info, getSysType(tyString))
  filename.strVal = ToFilename(info)
  var line = newNodeIT(nkIntLit, n.info, getSysType(tyInt))
  line.intVal = ToLinenumber(info)
  result.add(filename)
  result.add(line)

proc semTypeTraits(c: PContext, n: PNode): PNode =
  checkMinSonsLen(n, 2)
  internalAssert n.sons[1].kind == nkSym
  if n.sons[1].sym.kind == skType:
    result = evalTypeTrait(n, GetCurrOwner())
  else:
    # pass unmodified to evals
    result = n

proc semOrd(c: PContext, n: PNode): PNode =
  result = n
  result.typ = makeRangeType(c, firstOrd(n.sons[1].typ),
                                lastOrd(n.sons[1].typ), n.info)

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
  of mShallowCopy: result = semShallowCopy(c, n, flags)
  else: result = n

