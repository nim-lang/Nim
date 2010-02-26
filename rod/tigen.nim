#
#
#           The Nimrod Compiler
#        (c) Copyright 2008 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Type information generator. It transforms types into the AST of walker
# procs. This is used by the code generators.

import 
  ast, astalgo, strutils, nhashes, trees, treetab, platform, magicsys, options, 
  msgs, crc, idents, lists, types, rnimsyn

proc gcWalker*(t: PType): PNode
proc initWalker*(t: PType): PNode
proc asgnWalker*(t: PType): PNode
proc reprWalker*(t: PType): PNode
# implementation

proc gcWalker(t: PType): PNode = 
  nil

proc initWalker(t: PType): PNode = 
  nil

proc asgnWalker(t: PType): PNode = 
  nil

proc reprWalker(t: PType): PNode = 
  nil
