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
  ast, types, hashes, strutils, msgs, wordrecg,
  platform, trees, options, cgendata

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

proc mapSetType(conf: ConfigRef; typ: PType): TCTypeKind =
  case int(getSize(conf, typ))
  of 1: result = ctInt8
  of 2: result = ctInt16
  of 4: result = ctInt32
  of 8: result = ctInt64
  else: result = ctArray

proc ccgIntroducedPtr*(conf: ConfigRef; s: PSym, retType: PType): bool =
  var pt = skipTypes(s.typ, typedescInst)
  assert skResult != s.kind

  if tfByRef in pt.flags: return true
  elif tfByCopy in pt.flags: return false
  case pt.kind
  of tyObject:
    if s.typ.sym != nil and sfForward in s.typ.sym.flags:
      # forwarded objects are *always* passed by pointers for consistency!
      result = true
    elif (optByRef in s.options) or (getSize(conf, pt) > conf.target.floatSize * 3):
      result = true           # requested anyway
    elif (tfFinal in pt.flags) and (pt[0] == nil):
      result = false          # no need, because no subtyping possible
    else:
      result = true           # ordinary objects are always passed by reference,
                              # otherwise casting doesn't work
  of tyTuple:
    result = (getSize(conf, pt) > conf.target.floatSize*3) or (optByRef in s.options)
  else:
    result = false
  # first parameter and return type is 'lent T'? --> use pass by pointer
  if s.position == 0 and retType != nil and retType.kind == tyLent:
    result = not (pt.kind in {tyVar, tyArray, tyOpenArray, tyVarargs, tyRef, tyPtr, tyPointer} or
      pt.kind == tySet and mapSetType(conf, pt) == ctArray)

