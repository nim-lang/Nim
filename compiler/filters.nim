#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements Nim's simple filters and helpers for filters.

import
  llstream, os, wordrecg, idents, strutils, ast, astalgo, msgs, options,
  renderer, pathutils

proc invalidPragma(conf: ConfigRef; n: PNode) =
  localError(conf, n.info,
      "'$1' not allowed here" % renderTree(n, {renderNoComments}))

proc getArg(conf: ConfigRef; n: PNode, name: string, pos: int): PNode =
  result = nil
  if n.kind in {nkEmpty..nkNilLit}: return
  for i in 1 ..< sonsLen(n):
    if n.sons[i].kind == nkExprEqExpr:
      if n.sons[i].sons[0].kind != nkIdent: invalidPragma(conf, n)
      if cmpIgnoreStyle(n.sons[i].sons[0].ident.s, name) == 0:
        return n.sons[i].sons[1]
    elif i == pos:
      return n.sons[i]

proc charArg*(conf: ConfigRef; n: PNode, name: string, pos: int, default: char): char =
  var x = getArg(conf, n, name, pos)
  if x == nil: result = default
  elif x.kind == nkCharLit: result = chr(int(x.intVal))
  else: invalidPragma(conf, n)

proc strArg*(conf: ConfigRef; n: PNode, name: string, pos: int, default: string): string =
  var x = getArg(conf, n, name, pos)
  if x == nil: result = default
  elif x.kind in {nkStrLit..nkTripleStrLit}: result = x.strVal
  else: invalidPragma(conf, n)

proc boolArg*(conf: ConfigRef; n: PNode, name: string, pos: int, default: bool): bool =
  var x = getArg(conf, n, name, pos)
  if x == nil: result = default
  elif x.kind == nkIdent and cmpIgnoreStyle(x.ident.s, "true") == 0: result = true
  elif x.kind == nkIdent and cmpIgnoreStyle(x.ident.s, "false") == 0: result = false
  else: invalidPragma(conf, n)

proc filterStrip*(conf: ConfigRef; stdin: PLLStream, filename: AbsoluteFile, call: PNode): PLLStream =
  var pattern = strArg(conf, call, "startswith", 1, "")
  var leading = boolArg(conf, call, "leading", 2, true)
  var trailing = boolArg(conf, call, "trailing", 3, true)
  result = llStreamOpen("")
  var line = newStringOfCap(80)
  while llStreamReadLine(stdin, line):
    var stripped = strip(line, leading, trailing)
    if len(pattern) == 0 or startsWith(stripped, pattern):
      llStreamWriteln(result, stripped)
    else:
      llStreamWriteln(result, line)
  llStreamClose(stdin)

proc filterReplace*(conf: ConfigRef; stdin: PLLStream, filename: AbsoluteFile, call: PNode): PLLStream =
  var sub = strArg(conf, call, "sub", 1, "")
  if len(sub) == 0: invalidPragma(conf, call)
  var by = strArg(conf, call, "by", 2, "")
  result = llStreamOpen("")
  var line = newStringOfCap(80)
  while llStreamReadLine(stdin, line):
    llStreamWriteln(result, replace(line, sub, by))
  llStreamClose(stdin)
