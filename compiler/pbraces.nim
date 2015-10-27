#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import
  llstream, lexer, parser, idents, strutils, ast, msgs

proc parseAll*(p: var TParser): PNode =
  result = nil

proc parseTopLevelStmt*(p: var TParser): PNode =
  result = nil

