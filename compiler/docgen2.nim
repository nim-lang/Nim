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

type
  TGen = object of TPassContext
    doc: PDoc
    module: PSym
  PGen = ref TGen

proc close(p: PPassContext, n: PNode): PNode =
  var g = PGen(p)
  let useWarning = sfMainModule notin g.module.flags
  if gWholeProject or sfMainModule in g.module.flags:
    writeOutput(g.doc, g.module.filename, HtmlExt, useWarning)
    try:
      generateIndex(g.doc)
    except IOError:
      discard

proc processNode(c: PPassContext, n: PNode): PNode =
  result = n
  var g = PGen(c)
  generateDoc(g.doc, n)

proc myOpen(module: PSym): PPassContext =
  var g: PGen
  new(g)
  g.module = module
  var d = newDocumentor(module.filename, options.gConfigVars)
  d.hasToc = true
  g.doc = d
  result = g

const docgen2Pass* = makePass(open = myOpen, process = processNode, close = close)

proc finishDoc2Pass*(project: string) =
  discard
