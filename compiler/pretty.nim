#
#
#           The Nimrod Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the code "prettifier". This is part of the toolchain
## to convert Nimrod code into a consistent style.

import 
  os, options, ast, astalgo, msgs, ropes, idents, passes, importer

type 
  TGen = object of TPassContext
    module*: PSym
  PGen = ref TGen
  
  TSourceFile = object
    lines: seq[string]
    dirty: bool
    fullpath: string

proc addSourceLine(fileIdx: int32, line: string) =
  fileInfos[fileIdx].lines.add line

proc sourceLine(i: TLineInfo): PRope =
  if i.fileIndex < 0: return nil
  
  if not optPreserveOrigSource and fileInfos[i.fileIndex].lines.len == 0:
    try:
      for line in lines(i.toFullPath):
        addSourceLine i.fileIndex, line.string
    except EIO:
      discard
  InternalAssert i.fileIndex < fileInfos.len
  # can happen if the error points to EOF:
  if i.line > fileInfos[i.fileIndex].lines.len: return nil

  result = fileInfos[i.fileIndex].lines[i.line-1]

proc addDependencyAux(importing, imported: string) = 
  appf(gDotGraph, "$1 -> $2;$n", [toRope(importing), toRope(imported)]) 
  # s1 -> s2_4[label="[0-9]"];
  
proc addDotDependency(c: PPassContext, n: PNode): PNode = 
  result = n
  var g = PGen(c)
  case n.kind
  of nkSym:
    
  of nkTypeSection:
    # we need to figure out whether the PType or the TType should become
    # Type. The other then is either TypePtr/TypeRef or TypeDesc.
    
  of nkImportStmt: 
    for i in countup(0, sonsLen(n) - 1): 
      var imported = getModuleName(n.sons[i])
      addDependencyAux(g.module.name.s, imported)
  of nkFromStmt, nkImportExceptStmt: 
    var imported = getModuleName(n.sons[0])
    addDependencyAux(g.module.name.s, imported)
  of nkStmtList, nkBlockStmt, nkStmtListExpr, nkBlockExpr: 
    for i in countup(0, sonsLen(n) - 1): discard addDotDependency(c, n.sons[i])
  else: 
    nil

proc generateRefactorScript*(project: string) = 
  writeRope(ropef("digraph $1 {$n$2}$n", [
      toRope(changeFileExt(extractFileName(project), "")), gDotGraph]), 
            changeFileExt(project, "dot"))

proc myOpen(module: PSym): PPassContext =
  var g: PGen
  new(g)
  g.module = module
  result = g

const prettyPass* = makePass(open = myOpen, process = addDotDependency)

