#
#
#           The Nimrod Compiler
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module declares some helpers for the C code generator.

import 
  ast, astalgo, ropes, lists, hashes, strutils, types, msgs, wordrecg, 
  platform

proc whichPragma*(n: PNode): TSpecialWord = 
  var key = if n.kind == nkExprColonExpr: n.sons[0] else: n
  if key.kind == nkIdent: result = whichKeyword(key.ident)

proc getPragmaStmt*(n: PNode, w: TSpecialWord): PNode =
  case n.kind
  of nkStmtList: 
    for i in 0 .. < n.len: 
      result = getPragmaStmt(n[i], w)
      if result != nil: break
  of nkPragma:
    for i in 0 .. < n.len: 
      if whichPragma(n[i]) == w: return n[i]
  else: nil

proc stmtsContainPragma*(n: PNode, w: TSpecialWord): bool =
  result = getPragmaStmt(n, w) != nil

proc hashString*(s: string): biggestInt = 
  # has to be the same algorithm as system.hashString!
  if CPU[targetCPU].bit == 64: 
    # we have to use the same bitwidth
    # as the target CPU
    var b = 0'i64
    for i in countup(0, len(s) - 1): 
      b = b +% Ord(s[i])
      b = b +% `shl`(b, 10)
      b = b xor `shr`(b, 6)
    b = b +% `shl`(b, 3)
    b = b xor `shr`(b, 11)
    b = b +% `shl`(b, 15)
    result = b
  else: 
    var a = 0'i32
    for i in countup(0, len(s) - 1): 
      a = a +% Ord(s[i]).int32
      a = a +% `shl`(a, 10'i32)
      a = a xor `shr`(a, 6'i32)
    a = a +% `shl`(a, 3'i32)
    a = a xor `shr`(a, 11'i32)
    a = a +% `shl`(a, 15'i32)
    result = a

var gTypeTable: array[TTypeKind, TIdTable]

proc initTypeTables() = 
  for i in countup(low(TTypeKind), high(TTypeKind)): InitIdTable(gTypeTable[i])
  
proc GetUniqueType*(key: PType): PType = 
  # this is a hotspot in the compiler!
  result = key
  if key == nil: return 
  var k = key.kind
  case k 
  of tyObject, tyEnum: 
    result = PType(IdTableGet(gTypeTable[k], key))
    if result == nil: 
      IdTablePut(gTypeTable[k], key, key)
      result = key
  of tyGenericInst, tyDistinct, tyOrdinal: 
    result = GetUniqueType(lastSon(key))
  of tyProc: 
    nil
  else: 
    # we have to do a slow linear search because types may need
    # to be compared by their structure:
    if IdTableHasObjectAsKey(gTypeTable[k], key): return 
    for h in countup(0, high(gTypeTable[k].data)): 
      var t = PType(gTypeTable[k].data[h].key)
      if (t != nil) and sameType(t, key): 
        return t
    IdTablePut(gTypeTable[k], key, key)

proc TableGetType*(tab: TIdTable, key: PType): PObject = 
  # returns nil if we need to declare this type
  result = IdTableGet(tab, key)
  if (result == nil) and (tab.counter > 0): 
    # we have to do a slow linear search because types may need
    # to be compared by their structure:
    for h in countup(0, high(tab.data)): 
      var t = PType(tab.data[h].key)
      if t != nil: 
        if sameType(t, key): 
          return tab.data[h].val

proc toCChar*(c: Char): string = 
  case c
  of '\0'..'\x1F', '\x80'..'\xFF': result = '\\' & toOctal(c)
  of '\'', '\"', '\\': result = '\\' & c
  else: result = $(c)

proc makeSingleLineCString*(s: string): string =
  result = "\""
  for c in items(s):
    result.add(c.toCChar)
  result.add('\"')
  
proc makeCString*(s: string): PRope = 
  # BUGFIX: We have to split long strings into many ropes. Otherwise
  # this could trigger an InternalError(). See the ropes module for
  # further information.
  const 
    MaxLineLength = 64
  var res: string
  result = nil
  res = "\""
  for i in countup(0, len(s) - 1):
    if (i + 1) mod MaxLineLength == 0:
      add(res, '\"')
      add(res, tnl)
      app(result, toRope(res)) # reset:
      setlen(res, 1)
      res[0] = '\"'
    add(res, toCChar(s[i]))
  add(res, '\"')
  app(result, toRope(res))

proc makeLLVMString*(s: string): PRope = 
  const MaxLineLength = 64
  var res: string
  result = nil
  res = "c\""
  for i in countup(0, len(s) - 1): 
    if (i + 1) mod MaxLineLength == 0: 
      app(result, toRope(res))
      setlen(res, 0)
    case s[i]
    of '\0'..'\x1F', '\x80'..'\xFF', '\"', '\\': 
      add(res, '\\')
      add(res, toHex(ord(s[i]), 2))
    else: add(res, s[i])
  add(res, "\\00\"")
  app(result, toRope(res))

InitTypeTables()
