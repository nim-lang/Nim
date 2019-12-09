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
  ast, hashes, strutils, msgs, wordrecg,
  platform, trees, options

proc getPragmaStmt*(n: PNode, w: TSpecialWord): PNode =
  case n.kind
  of nkStmtList:
    for i in 0..<n.len:
      result = getPragmaStmt(n[i], w)
      if result != nil: break
  of nkPragma:
    for i in 0..<n.len:
      if whichPragma(n[i]) == w: return n[i]
  else: discard

proc stmtsContainPragma*(n: PNode, w: TSpecialWord): bool =
  result = getPragmaStmt(n, w) != nil

proc hashString*(conf: ConfigRef; s: string): BiggestInt =
  # has to be the same algorithm as strmantle.hashString!
  if CPU[conf.target.targetCPU].bit == 64:
    # we have to use the same bitwidth
    # as the target CPU
    var b = 0'u64
    for i in 0..<s.len:
      b = b + uint(s[i])
      b = b + (b shl 10)
      b = b xor (b shr 6)
    b = b + (b shl 3)
    b = b xor (b shr 11)
    b = b + (b shl 15)
    result = cast[Hash](b)
  else:
    var a = 0'u32
    for i in 0..<s.len:
      a = a + uint32(s[i])
      a = a + (a shl 10)
      a = a xor (a shr 6)
    a = a + (a shl 3)
    a = a xor (a shr 11)
    a = a + (a shl 15)
    result = cast[Hash](a)

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
  for i in start..<name.len:
    let c = name[i]
    case c
    of 'a'..'z', '0'..'9', 'A'..'Z':
      result.add(c)
    of '_':
      # we generate names like 'foo_9' for scope disambiguations and so
      # disallow this here:
      if i > 0 and i < name.len-1 and name[i+1] in Digits:
        discard
      else:
        result.add(c)
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
      result.add("X" & toHex(ord(c), 2))
      requiresUnderscore = true
  if requiresUnderscore:
    result.add "_"
