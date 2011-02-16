#
#
#           The Nimrod Compiler
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This file implements features required for IDE support.

import ast, astalgo, semdata, msgs, types

const
  sep = '\t'

proc SymToStr(s: PSym, isLocal: bool): string = 
  result = ""
  result.add($s.kind)
  result.add(sep)
  if not isLocal: 
    if s.kind != skModule and s.owner != nil: 
      result.add(s.owner.name.s)
      result.add('.')
  result.add(s.name.s)
  result.add(sep)
  if s.typ != nil: 
    result.add(typeToString(s.typ))
  result.add(sep)
  result.add(toFilename(s.info))
  result.add(sep)
  result.add($ToLinenumber(s.info))
  result.add(sep)
  result.add($ToColumn(s.info))

proc suggestExpr*(c: PContext, n: PNode) = 
  if not msgs.inCheckpoint(n.info): return

  for i in countdown(c.tab.tos-1, 0): 
    for it in items(c.tab.stack[i]): 
      MessageOut(SymToStr(it, i > ModuleTablePos))
  quit(0)

proc suggestStmt*(c: PContext, n: PNode) = 
  suggestExpr(c, n) 


proc suggestFieldAccess*(c: PContext, n: PNode) =
  suggestExpr(c, n) 
  # XXX provide a better implementation based on n[0].typ

