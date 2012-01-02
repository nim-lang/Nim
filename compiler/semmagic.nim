#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This include file implements the semantic checking for magics.

proc semIsPartOf(c: PContext, n: PNode, flags: TExprFlags): PNode =
  var r = isPartOf(n[1], n[2])
  result = newIntNodeT(ord(r), n)
  
proc semSlurp(c: PContext, n: PNode, flags: TExprFlags): PNode = 
  assert sonsLen(n) == 2
  var a = expectStringArg(c, n, 0)
  try:
    var filename = a.strVal.FindFile
    var content = readFile(filename)
    result = newStrNode(nkStrLit, content)
    result.typ = getSysType(tyString)
    result.info = n.info
    c.slurpedFiles.add(filename)
  except EIO:
    GlobalError(a.info, errCannotOpenFile, a.strVal)

proc magicsAfterOverloadResolution(c: PContext, n: PNode, 
                                   flags: TExprFlags): PNode =
  case n[0].sym.magic
  of mSlurp: result = semSlurp(c, n, flags)
  of mIsPartOf: result = semIsPartOf(c, n, flags)
  of mAstToStr:
    result = newStrNodeT(renderTree(n[1], {renderNoComments}), n)
    result.typ = getSysType(tyString)
  else: result = n

