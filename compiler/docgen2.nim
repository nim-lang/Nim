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

from modulegraphs import ModuleGraph

type
  TGen = object of TPassContext
    doc: PDoc
    module: PSym
  PGen = ref TGen

template shouldProcess(g): bool =
  (g.module.owner.id == g.doc.conf.mainPackageId and optWholeProject in g.doc.conf.globalOptions) or
      sfMainModule in g.module.flags

template closeImpl(body: untyped) {.dirty.} =
  var g = PGen(p)
  let useWarning = sfMainModule notin g.module.flags
  #echo g.module.name.s, " ", g.module.owner.id, " ", gMainPackageId
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

proc closePot(graph: ModuleGraph; p: PPassContext, n: PNode): PNode =
  closeImpl:
    writeOutputPot(g.doc, toFilename(graph.config, FileIndex g.module.position), ".pot", useWarning)

proc processNode(c: PPassContext, n: PNode): PNode =
  result = n
  var g = PGen(c)
  if shouldProcess(g):
    generateDoc(g.doc, n, n)

proc processNodeJson(c: PPassContext, n: PNode): PNode =
  result = n
  var g = PGen(c)
  if shouldProcess(g):
    generateJson(g.doc, n)

proc processNodeExtractPot(c: PPassContext, n: PNode): PNode =
  result = n
  var g = PGen(c)
  generatePotEntry(g.doc, n)

proc myOpen(graph: ModuleGraph; module: PSym): PPassContext =
  var g: PGen
  new(g)
  g.module = module
  var d = newDocumentor(AbsoluteFile toFullPath(graph.config, FileIndex module.position),
      graph.cache, graph.config)
  d.hasToc = true
  g.doc = d
  d.translations = loadTranslationData(graph.config)
  result = g

const docgen2Pass* = makePass(open = myOpen, process = processNode, close = close)
const docgen2JsonPass* = makePass(open = myOpen, process = processNodeJson,
                                  close = closeJson)
const docgen2PotPass* = makePass(
  open = myOpen,
  process = processNodeExtractPot,
  close = closePot
)

proc finishDoc2Pass*(project: string) =
  discard
