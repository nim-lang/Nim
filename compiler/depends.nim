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
  os, options, ast, astalgo, msgs, ropes, idents, passes, modulepaths,
  pathutils

from modulegraphs import ModuleGraph, PPassContext

type
  TGen = object of PPassContext
    module: PSym
    config: ConfigRef
    graph: ModuleGraph
  PGen = ref TGen

  Backend = ref object of RootRef
    dotGraph: Rope

proc addDependencyAux(b: Backend; importing, imported: string) =
  addf(b.dotGraph, "$1 -> \"$2\";$n", [rope(importing), rope(imported)])
  # s1 -> s2_4[label="[0-9]"];

proc addDotDependency(c: PPassContext, n: PNode): PNode =
  result = n
  let g = PGen(c)
  let b = Backend(g.graph.backend)
  case n.kind
  of nkImportStmt:
    for i in 0 ..< sonsLen(n):
      var imported = getModuleName(g.config, n.sons[i])
      addDependencyAux(b, g.module.name.s, imported)
  of nkFromStmt, nkImportExceptStmt:
    var imported = getModuleName(g.config, n.sons[0])
    addDependencyAux(b, g.module.name.s, imported)
  of nkStmtList, nkBlockStmt, nkStmtListExpr, nkBlockExpr:
    for i in 0 ..< sonsLen(n): discard addDotDependency(c, n.sons[i])
  else:
    discard

proc generateDot*(graph: ModuleGraph; project: AbsoluteFile) =
  let b = Backend(graph.backend)
  discard writeRope("digraph $1 {$n$2}$n" % [
      rope(project.splitFile.name), b.dotGraph],
            changeFileExt(project, "dot"))

proc myOpen(graph: ModuleGraph; module: PSym): PPassContext =
  var g: PGen
  new(g)
  g.module = module
  g.config = graph.config
  g.graph = graph
  if graph.backend == nil:
    graph.backend = Backend(dotGraph: nil)
  result = g

const gendependPass* = makePass(open = myOpen, process = addDotDependency)

