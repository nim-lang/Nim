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
  os, options, ast, astalgo, msgs, ropes, idents, passes, docgen

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
  if (g.module.owner.id == gMainPackageId and gWholeProject) or
    sfMainModule in g.module.flags:
    body
    try:
      generateIndex(g.doc)
    except IOError:
      discard

proc close(p: PPassContext, n: PNode): PNode =
  closeImpl:
    writeOutput(g.doc, g.module.filename, HtmlExt, useWarning)

proc closeJson(p: PPassContext, n: PNode): PNode =
  closeImpl:
    writeOutputJson(g.doc, g.module.filename, ".json", useWarning)

proc processNode(c: PPassContext, n: PNode): PNode =
  result = n
  var g = PGen(c)
  generateDoc(g.doc, n)

proc processNodeJson(c: PPassContext, n: PNode): PNode =
  result = n
  var g = PGen(c)
  generateJson(g.doc, n)

proc myOpen(graph: ModuleGraph; module: PSym; cache: IdentCache): PPassContext =
  var g: PGen
  new(g)
  g.module = module
  var d = newDocumentor(module.filename, options.gConfigVars)
  d.hasToc = true
  g.doc = d
  result = g

const docgen2Pass* = makePass(open = myOpen, process = processNode, close = close)
const docgen2JsonPass* = makePass(open = myOpen, process = processNodeJson,
                                  close = closeJson)

proc finishDoc2Pass*(project: string) =
  discard
