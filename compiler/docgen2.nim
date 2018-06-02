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
  os, options, ast, astalgo, msgs, ropes, idents, passes, docgen, lineinfos

from modulegraphs import ModuleGraph

type
  TGen = object of TPassContext
    doc: PDoc
    module: PSym
  PGen = ref TGen

template closeImpl(body: untyped) {.dirty.} =
  var g = PGen(p)
  let useWarning = sfMainModule notin g.module.flags
  #echo g.module.name.s, " ", g.module.owner.id, " ", gMainPackageId
  if (g.module.owner.id == g.doc.conf.mainPackageId and optWholeProject in g.doc.conf.globalOptions) or
      sfMainModule in g.module.flags:
    body
    try:
      generateIndex(g.doc)
    except IOError:
      discard

proc close(graph: ModuleGraph; p: PPassContext, n: PNode): PNode =
  closeImpl:
    writeOutput(g.doc, toFilename(graph.config, FileIndex g.module.position), HtmlExt, useWarning)

proc closeJson(graph: ModuleGraph; p: PPassContext, n: PNode): PNode =
  closeImpl:
    writeOutputJson(g.doc, toFilename(graph.config, FileIndex g.module.position), ".json", useWarning)

proc processNode(c: PPassContext, n: PNode): PNode =
  result = n
  var g = PGen(c)
  generateDoc(g.doc, n)

proc processNodeJson(c: PPassContext, n: PNode): PNode =
  result = n
  var g = PGen(c)
  generateJson(g.doc, n)

proc myOpen(graph: ModuleGraph; module: PSym): PPassContext =
  var g: PGen
  new(g)
  g.module = module
  var d = newDocumentor(toFilename(graph.config, FileIndex module.position), graph.cache, graph.config)
  d.hasToc = true
  g.doc = d
  result = g

const docgen2Pass* = makePass(open = myOpen, process = processNode, close = close)
const docgen2JsonPass* = makePass(open = myOpen, process = processNodeJson,
                                  close = closeJson)

proc finishDoc2Pass*(project: string) =
  discard
