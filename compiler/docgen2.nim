#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements a new documentation generator that runs after
# semantic checking.

import
  os, options, ast, astalgo, msgs, ropes, idents, passes, docgen, lineinfos,
  pathutils

from modulegraphs import ModuleGraph, PPassContext

type
  TGen = object of PPassContext
    doc: PDoc
    module: PSym
  PGen = ref TGen

template shouldProcess(g): bool =
  (g.module.owner.id == g.doc.conf.mainPackageId and optWholeProject in g.doc.conf.globalOptions) or
      sfMainModule in g.module.flags

template closeImpl(body: untyped) {.dirty.} =
  var g = PGen(p)
  let useWarning = sfMainModule notin g.module.flags
  if shouldProcess(g):
    body
    try:
      generateIndex(g.doc)
    except IOError:
      discard

proc close(graph: ModuleGraph; p: PPassContext, n: PNode): PNode =
  closeImpl:
    writeOutput(g.doc, useWarning)

proc closeJson(graph: ModuleGraph; p: PPassContext, n: PNode): PNode =
  closeImpl:
    writeOutputJson(g.doc, useWarning)

proc processNode(c: PPassContext, n: PNode): PNode =
  result = n
  var g = PGen(c)
  if shouldProcess(g):
    generateDoc(g.doc, n, n)

proc processNodeJson(c: PPassContext, n: PNode): PNode =
  result = n
  var g = PGen(c)
  if shouldProcess(g):
    generateJson(g.doc, n, false)

template myOpenImpl(ext: untyped) {.dirty.} =
  var g: PGen
  new(g)
  g.module = module
  var d = newDocumentor(AbsoluteFile toFullPath(graph.config, FileIndex module.position),
      graph.cache, graph.config, ext)
  d.hasToc = true
  g.doc = d
  result = g

proc myOpen(graph: ModuleGraph; module: PSym): PPassContext =
  myOpenImpl(HtmlExt)

proc myOpenJson(graph: ModuleGraph; module: PSym): PPassContext =
  myOpenImpl(JsonExt)

const docgen2Pass* = makePass(open = myOpen, process = processNode, close = close)
const docgen2JsonPass* = makePass(open = myOpenJson, process = processNodeJson,
                                  close = closeJson)

proc finishDoc2Pass*(project: string) =
  discard
