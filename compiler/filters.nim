#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements Nimrod's simple filters and helpers for filters.

import
  llstream, os, wordrecg, idents, strutils, ast, astalgo, msgs, options, 
  renderer

proc filterReplace*(stdin: PLLStream, filename: string, call: PNode): PLLStream
proc filterStrip*(stdin: PLLStream, filename: string, call: PNode): PLLStream
  # helpers to retrieve arguments:
proc charArg*(n: PNode, name: string, pos: int, default: char): char
proc strArg*(n: PNode, name: string, pos: int, default: string): string
proc boolArg*(n: PNode, name: string, pos: int, default: bool): bool
# implementation

proc invalidPragma(n: PNode) = 
  localError(n.info, errXNotAllowedHere, renderTree(n, {renderNoComments}))

proc getArg(n: PNode, name: string, pos: int): PNode = 
  result = nil
  if n.kind in {nkEmpty..nkNilLit}: return 
  for i in countup(1, sonsLen(n) - 1): 
    if n.sons[i].kind == nkExprEqExpr: 
      if n.sons[i].sons[0].kind != nkIdent: invalidPragma(n)
      if identEq(n.sons[i].sons[0].ident, name): 
        return n.sons[i].sons[1]
    elif i == pos: 
      return n.sons[i]
  
proc charArg(n: PNode, name: string, pos: int, default: Char): Char = 
  var x = getArg(n, name, pos)
  if x == nil: result = default
  elif x.kind == nkCharLit: result = chr(int(x.intVal))
  else: invalidPragma(n)
  
proc strArg(n: PNode, name: string, pos: int, default: string): string = 
  var x = getArg(n, name, pos)
  if x == nil: result = default
  elif x.kind in {nkStrLit..nkTripleStrLit}: result = x.strVal
  else: invalidPragma(n)
  
proc boolArg(n: PNode, name: string, pos: int, default: bool): bool = 
  var x = getArg(n, name, pos)
  if x == nil: result = default
  elif (x.kind == nkIdent) and identEq(x.ident, "true"): result = true
  elif (x.kind == nkIdent) and identEq(x.ident, "false"): result = false
  else: invalidPragma(n)
  
proc filterStrip(stdin: PLLStream, filename: string, call: PNode): PLLStream = 
  var pattern = strArg(call, "startswith", 1, "")
  var leading = boolArg(call, "leading", 2, true)
  var trailing = boolArg(call, "trailing", 3, true)
  result = llStreamOpen("")
  var line = newStringOfCap(80)
  while llStreamReadLine(stdin, line):
    var stripped = strip(line, leading, trailing)
    if (len(pattern) == 0) or startsWith(stripped, pattern): 
      llStreamWriteln(result, stripped)
    else: 
      llStreamWriteln(result, line)
  llStreamClose(stdin)

proc filterReplace(stdin: PLLStream, filename: string, call: PNode): PLLStream = 
  var sub = strArg(call, "sub", 1, "")
  if len(sub) == 0: invalidPragma(call)
  var by = strArg(call, "by", 2, "")
  result = llStreamOpen("")
  var line = newStringOfCap(80)
  while llStreamReadLine(stdin, line):
    llStreamWriteln(result, replace(line, sub, by))
  llStreamClose(stdin)
