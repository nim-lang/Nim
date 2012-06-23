#
#
#           The Nimrod Compiler
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
    filename: string
  PGen = ref TGen

proc close(p: PPassContext, n: PNode): PNode =
  var g = PGen(p)
  writeOutput(g.doc, g.filename, HtmlExt)
  generateIndex(g.doc)

proc processNode(c: PPassContext, n: PNode): PNode = 
  result = n
  var g = PGen(c)
  generateDoc(g.doc, n)

proc myOpen(module: PSym, filename: string): PPassContext = 
  var g: PGen
  new(g)
  g.module = module
  g.filename = filename
  var d = newDocumentor(filename, options.gConfigVars)
  d.hasToc = true
  g.doc = d
  result = g

proc docgen2Pass*(): TPass = 
  initPass(result)
  result.open = myOpen
  result.process = processNode
  result.close = close

proc finishDoc2Pass*(project: string) = 
  nil
