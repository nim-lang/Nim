#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements a dependency file generator.

import options, ast, ropes, passes, pathutils, msgs, lineinfos

import modulegraphs

import std/[os, strutils, parseutils]
import std/private/globs

type
  TGen = object of PPassContext
    module: PSym
    config: ConfigRef
    graph: ModuleGraph
  PGen = ref TGen

  Backend = ref object of RootRef
    dotGraph: Rope

proc addDependencyAux(b: Backend; importing, imported: string) =
  b.dotGraph.addf("\"$1\" -> \"$2\";$n", [rope(importing), rope(imported)])
  # s1 -> s2_4[label="[0-9]"];

proc toNimblePath(s: string, isStdlib: bool): string =
  const stdPrefix = "std/"
  const pkgPrefix = "pkg/"
  if isStdlib:
    let sub = "lib/"
    var start = s.find(sub)
    if start < 0:
      doAssert false
    else:
      start += sub.len
      let base = s[start..^1]

      if base.startsWith("system") or base.startsWith("std"):
        result = base
      else:
        for dir in stdlibDirs:
          if base.startsWith(dir):
            return stdPrefix & base.splitFile.name

        result = stdPrefix & base
  else:
    var sub = getEnv("NIMBLE_DIR")
    if sub.len == 0:
      sub = ".nimble/pkgs/"
    else:
      sub.add "/pkgs/"
    var start = s.find(sub)
    if start < 0:
      result = s
    else:
      start += sub.len
      start += skipUntil(s, '/', start)
      start += 1
      result = pkgPrefix & s[start..^1]

proc addDependency(c: PPassContext, g: PGen, b: Backend, n: PNode) =
  doAssert n.kind == nkSym, $n.kind

  let path = splitFile(toProjPath(g.config, n.sym.position.FileIndex))
  let modulePath = splitFile(toProjPath(g.config, g.module.position.FileIndex))
  let parent = nativeToUnixPath(modulePath.dir / modulePath.name).toNimblePath(belongsToStdlib(g.graph, g.module))
  let child = nativeToUnixPath(path.dir / path.name).toNimblePath(belongsToStdlib(g.graph, n.sym))
  addDependencyAux(b, parent, child)

proc addDotDependency(c: PPassContext, n: PNode): PNode =
  result = n
  let g = PGen(c)
  let b = Backend(g.graph.backend)
  case n.kind
  of nkImportStmt:
    for i in 0..<n.len:
      addDependency(c, g, b, n[i])
  of nkFromStmt, nkImportExceptStmt:
    addDependency(c, g, b, n[0])
  of nkStmtList, nkBlockStmt, nkStmtListExpr, nkBlockExpr:
    for i in 0..<n.len: discard addDotDependency(c, n[i])
  else:
    discard

proc generateDot*(graph: ModuleGraph; project: AbsoluteFile) =
  let b = Backend(graph.backend)
  discard writeRope("digraph $1 {$n$2}$n" % [
      rope(project.splitFile.name), b.dotGraph],
            changeFileExt(project, "dot"))

when not defined(nimHasSinkInference):
  {.pragma: nosinks.}

proc myOpen(graph: ModuleGraph; module: PSym; idgen: IdGenerator): PPassContext {.nosinks.} =
  var g: PGen
  new(g)
  g.module = module
  g.config = graph.config
  g.graph = graph
  if graph.backend == nil:
    graph.backend = Backend(dotGraph: nil)
  result = g

const gendependPass* = makePass(open = myOpen, process = addDotDependency)

