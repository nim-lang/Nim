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
  options, ast, msgs, docgen, lineinfos, pathutils, packages

from modulegraphs import ModuleGraph, PPassContext

type
  TGen = object of PPassContext
    doc: PDoc
    module: PSym
    config: ConfigRef
  PGen = ref TGen

proc shouldProcess(g: PGen): bool =
  (optWholeProject in g.doc.conf.globalOptions and g.doc.conf.belongsToProjectPackage(g.module)) or
      sfMainModule in g.module.flags or g.config.projectMainIdx == g.module.info.fileIndex

template closeImpl(body: untyped) {.dirty.} =
  var g = PGen(p)
  let useWarning = sfMainModule notin g.module.flags
  let groupedToc = true
  if shouldProcess(g):
    finishGenerateDoc(g.doc)
    body
    try:
      generateIndex(g.doc)
    except IOError:
      discard

proc closeDoc*(graph: ModuleGraph; p: PPassContext, n: PNode): PNode =
  closeImpl:
    writeOutput(g.doc, useWarning, groupedToc)

proc closeJson*(graph: ModuleGraph; p: PPassContext, n: PNode): PNode =
  closeImpl:
    writeOutputJson(g.doc, useWarning)

proc processNode*(c: PPassContext, n: PNode): PNode =
  result = n
  var g = PGen(c)
  if shouldProcess(g):
    generateDoc(g.doc, n, n, g.config)

proc processNodeJson*(c: PPassContext, n: PNode): PNode =
  result = n
  var g = PGen(c)
  if shouldProcess(g):
    generateJson(g.doc, n, g.config, false)

template myOpenImpl(ext: untyped) {.dirty.} =
  var g: PGen
  new(g)
  g.module = module
  g.config = graph.config
  var d = newDocumentor(AbsoluteFile toFullPath(graph.config, FileIndex module.position),
      graph.cache, graph.config, ext, module, hasToc = true)
  g.doc = d
  result = g

proc openHtml*(graph: ModuleGraph; module: PSym; idgen: IdGenerator): PPassContext =
  myOpenImpl(HtmlExt)

proc openTex*(graph: ModuleGraph; module: PSym; idgen: IdGenerator): PPassContext =
  myOpenImpl(TexExt)

proc openJson*(graph: ModuleGraph; module: PSym; idgen: IdGenerator): PPassContext =
  myOpenImpl(JsonExt)
