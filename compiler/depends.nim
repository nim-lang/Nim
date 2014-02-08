#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements a dependency file generator.

import 
  os, options, ast, astalgo, msgs, ropes, idents, passes, importer

proc generateDot*(project: string)

type 
  TGen = object of TPassContext
    module*: PSym
  PGen = ref TGen

var gDotGraph: PRope # the generated DOT file; we need a global variable

proc addDependencyAux(importing, imported: string) = 
  appf(gDotGraph, "$1 -> $2;$n", [toRope(importing), toRope(imported)]) 
  # s1 -> s2_4[label="[0-9]"];
  
proc addDotDependency(c: PPassContext, n: PNode): PNode = 
  result = n
  var g = PGen(c)
  case n.kind
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
    discard

proc generateDot(project: string) = 
  writeRope(ropef("digraph $1 {$n$2}$n", [
      toRope(changeFileExt(extractFilename(project), "")), gDotGraph]), 
            changeFileExt(project, "dot"))

proc myOpen(module: PSym): PPassContext =
  var g: PGen
  new(g)
  g.module = module
  result = g

const gendependPass* = makePass(open = myOpen, process = addDotDependency)

