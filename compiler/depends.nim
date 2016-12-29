#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements a dependency file generator.

import
  os, options, ast, astalgo, msgs, ropes, idents, passes, importer

from modulegraphs import ModuleGraph

proc generateDot*(project: string)
proc generateDepList*(project: string)

type
  TGen = object of TPassContext
    module*: PSym
  PGen = ref TGen

var gDotGraph: Rope # the generated DOT file; we need a global variable

proc addDependencyAux(importing, imported: string) =
  addf(gDotGraph, "$1 -> \"$2\";$n", [rope(importing), rope(imported)])
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
  writeRope("digraph $1 {$n$2}$n" % [
      rope(changeFileExt(extractFilename(project), "")), gDotGraph],
            changeFileExt(project, "dot"))

proc myOpen(graph: ModuleGraph; module: PSym; cache: IdentCache): PPassContext =
  var g: PGen
  new(g)
  g.module = module
  result = g

const gendependPass* = makePass(open = myOpen, process = addDotDependency)

# set of file dependences
var gDepSet: Rope

proc generateDepList(project: string) =
  let depfile = changeFileExt(project, "deps")
  writeRope(gDepSet, depfile)
  rawMessage(hintExecuting, "Wrote " & depfile)

proc addDepFileByNode(n: PNode) =
  let fidx = checkModuleName(n)
  if fidx != InvalidFileIDX:
    let ndf = toFullPath(fidx) & "\n"
    # Check for uniqueness
    for df in gDepSet.leaves:
      if df == ndf:
        return

    gDepSet.add(ndf)

proc addDepFile(c: PPassContext, n: PNode): PNode =
  result = n
  var g = PGen(c)
  case n.kind
  of nkImportStmt:
    for i in countup(0, sonsLen(n) - 1):
      addDepFileByNode(n.sons[i])
  of nkFromStmt, nkImportExceptStmt:
    addDepFileByNode(n.sons[0])
  of nkStmtList, nkBlockStmt, nkStmtListExpr, nkBlockExpr:
    for i in countup(0, sonsLen(n) - 1):
      discard addDepFile(c, n.sons[i])
  else:
    discard

const deplistPass* = makePass(open = myOpen, process = addDepFile)
