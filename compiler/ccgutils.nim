#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module declares some helpers for the C code generator.

import
  ast, astalgo, ropes, hashes, strutils, types, msgs, wordrecg,
  platform, trees, options

proc getPragmaStmt*(n: PNode, w: TSpecialWord): PNode =
  case n.kind
  of nkStmtList:
    for i in 0 ..< n.len:
      result = getPragmaStmt(n[i], w)
      if result != nil: break
  of nkPragma:
    for i in 0 ..< n.len:
      if whichPragma(n[i]) == w: return n[i]
  else: discard

proc stmtsContainPragma*(n: PNode, w: TSpecialWord): bool =
  result = getPragmaStmt(n, w) != nil

proc hashString*(conf: ConfigRef; s: string): BiggestInt =
  # has to be the same algorithm as system.hashString!
  if CPU[conf.target.targetCPU].bit == 64:
    # we have to use the same bitwidth
    # as the target CPU
    var b = 0'i64
    for i in 0 ..< len(s):
      b = b +% ord(s[i])
      b = b +% `shl`(b, 10)
      b = b xor `shr`(b, 6)
    b = b +% `shl`(b, 3)
    b = b xor `shr`(b, 11)
    b = b +% `shl`(b, 15)
    result = b
  else:
    var a = 0'i32
    for i in 0 ..< len(s):
      a = a +% ord(s[i]).int32
      a = a +% `shl`(a, 10'i32)
      a = a xor `shr`(a, 6'i32)
    a = a +% `shl`(a, 3'i32)
    a = a xor `shr`(a, 11'i32)
    a = a +% `shl`(a, 15'i32)
    result = a

template getUniqueType*(key: PType): PType = key

proc makeSingleLineCString*(s: string): string =
  result = "\""
  for c in items(s):
    c.toCChar(result)
  result.add('\"')

proc mangle*(name: string): string =
  result = newStringOfCap(name.len)
  var start = 0
  if name[0] in Digits:
    result.add("X" & name[0])
    start = 1
  var requiresUnderscore = false
  template special(x) =
    result.add x
    requiresUnderscore = true
  for i in start..(name.len-1):
    let c = name[i]
    case c
    of 'a'..'z', '0'..'9', 'A'..'Z':
      add(result, c)
    of '_':
      # we generate names like 'foo_9' for scope disambiguations and so
      # disallow this here:
      if i > 0 and i < name.len-1 and name[i+1] in Digits:
        discard
      else:
        add(result, c)
    of '$': special "dollar"
    of '%': special "percent"
    of '&': special "amp"
    of '^': special "roof"
    of '!': special "emark"
    of '?': special "qmark"
    of '*': special "star"
    of '+': special "plus"
    of '-': special "minus"
    of '/': special "slash"
    of '\\': special "backslash"
    of '=': special "eq"
    of '<': special "lt"
    of '>': special "gt"
    of '~': special "tilde"
    of ':': special "colon"
    of '.': special "dot"
    of '@': special "at"
    of '|': special "bar"
    else:
      add(result, "X" & toHex(ord(c), 2))
      requiresUnderscore = true
  if requiresUnderscore:
    result.add "_"
