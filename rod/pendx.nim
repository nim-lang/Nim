#
#
#           The Nimrod Compiler
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import 
  llstream, scanner, idents, strutils, ast, msgs, pnimsyn

proc ParseAll*(p: var TParser): PNode
proc parseTopLevelStmt*(p: var TParser): PNode
  # implements an iterator. Returns the next top-level statement or nil if end
  # of stream.
# implementation

proc ParseAll(p: var TParser): PNode = 
  result = nil

proc parseTopLevelStmt(p: var TParser): PNode = 
  result = nil
