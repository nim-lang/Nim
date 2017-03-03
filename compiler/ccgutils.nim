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
  platform, trees

proc getPragmaStmt*(n: PNode, w: TSpecialWord): PNode =
  case n.kind
  of nkStmtList:
    for i in 0 .. < n.len:
      result = getPragmaStmt(n[i], w)
      if result != nil: break
  of nkPragma:
    for i in 0 .. < n.len:
      if whichPragma(n[i]) == w: return n[i]
  else: discard

proc stmtsContainPragma*(n: PNode, w: TSpecialWord): bool =
  result = getPragmaStmt(n, w) != nil

proc hashString*(s: string): BiggestInt =
  # has to be the same algorithm as system.hashString!
  if CPU[targetCPU].bit == 64:
    # we have to use the same bitwidth
    # as the target CPU
    var b = 0'i64
    for i in countup(0, len(s) - 1):
      b = b +% ord(s[i])
      b = b +% `shl`(b, 10)
      b = b xor `shr`(b, 6)
    b = b +% `shl`(b, 3)
    b = b xor `shr`(b, 11)
    b = b +% `shl`(b, 15)
    result = b
  else:
    var a = 0'i32
    for i in countup(0, len(s) - 1):
      a = a +% ord(s[i]).int32
      a = a +% `shl`(a, 10'i32)
      a = a xor `shr`(a, 6'i32)
    a = a +% `shl`(a, 3'i32)
    a = a xor `shr`(a, 11'i32)
    a = a +% `shl`(a, 15'i32)
    result = a

var
  gTypeTable: array[TTypeKind, TIdTable]
  gCanonicalTypes: array[TTypeKind, PType]

proc initTypeTables() =
  for i in countup(low(TTypeKind), high(TTypeKind)): initIdTable(gTypeTable[i])

proc resetCaches* =
  ## XXX: fix that more properly
  initTypeTables()
  for i in low(gCanonicalTypes)..high(gCanonicalTypes):
    gCanonicalTypes[i] = nil

when false:
  proc echoStats*() =
    for i in countup(low(TTypeKind), high(TTypeKind)):
      echo i, " ", gTypeTable[i].counter

proc slowSearch(key: PType; k: TTypeKind): PType =
  # tuples are quite horrible as C does not support them directly and
  # tuple[string, string] is a (strange) subtype of
  # tuple[nameA, nameB: string]. This bites us here, so we
  # use 'sameBackendType' instead of 'sameType'.
  if idTableHasObjectAsKey(gTypeTable[k], key): return key
  for h in countup(0, high(gTypeTable[k].data)):
    var t = PType(gTypeTable[k].data[h].key)
    if t != nil and sameBackendType(t, key):
      return t
  idTablePut(gTypeTable[k], key, key)
  result = key

proc getUniqueType*(key: PType): PType =
  # this is a hotspot in the compiler!
  result = key
  when false:
    if key == nil: return
    var k = key.kind
    case k
    of tyBool, tyChar, tyInt..tyUInt64:
      # no canonicalization for integral types, so that e.g. ``pid_t`` is
      # produced instead of ``NI``.
      result = key
    of  tyEmpty, tyNil, tyExpr, tyStmt, tyPointer, tyString,
        tyCString, tyNone, tyVoid:
      result = gCanonicalTypes[k]
      if result == nil:
        gCanonicalTypes[k] = key
        result = key
    of tyTypeDesc, tyTypeClasses, tyGenericParam, tyFromExpr, tyFieldAccessor:
      if key.sym != nil:
        internalError(key.sym.info, "metatype not eliminated")
      else:
        internalError("metatype not eliminated")
    of tyDistinct:
      if key.deepCopy != nil: result = key
      else: result = getUniqueType(lastSon(key))
    of tyGenericInst, tyOrdinal, tyStatic, tyAlias:
      result = getUniqueType(lastSon(key))
      #let obj = lastSon(key)
      #if obj.sym != nil and obj.sym.name.s == "TOption":
      #  echo "for ", typeToString(key), " I returned "
      #  debug result
    of tyPtr, tyRef, tyVar:
      let elemType = lastSon(key)
      if elemType.kind in {tyBool, tyChar, tyInt..tyUInt64}:
        # no canonicalization for integral types, so that e.g. ``ptr pid_t`` is
        # produced instead of ``ptr NI``.
        result = key
      else:
        result = slowSearch(key, k)
    of tyGenericInvocation, tyGenericBody,
       tyOpenArray, tyArray, tySet, tyRange, tyTuple,
       tySequence, tyForward, tyVarargs, tyProxy:
      # we have to do a slow linear search because types may need
      # to be compared by their structure:
      result = slowSearch(key, k)
    of tyObject:
      if tfFromGeneric notin key.flags:
        # fast case; lookup per id suffices:
        result = PType(idTableGet(gTypeTable[k], key))
        if result == nil:
          idTablePut(gTypeTable[k], key, key)
          result = key
      else:
        # ugly slow case: need to compare by structure
        if idTableHasObjectAsKey(gTypeTable[k], key): return key
        for h in countup(0, high(gTypeTable[k].data)):
          var t = PType(gTypeTable[k].data[h].key)
          if t != nil and sameBackendType(t, key):
            return t
        idTablePut(gTypeTable[k], key, key)
        result = key
    of tyEnum:
      result = PType(idTableGet(gTypeTable[k], key))
      if result == nil:
        idTablePut(gTypeTable[k], key, key)
        result = key
    of tyProc:
      if key.callConv != ccClosure:
        result = key
      else:
        # ugh, we need the canon here:
        result = slowSearch(key, k)
    of tyUnused, tyUnused0, tyUnused1, tyUnused2: internalError("getUniqueType")

proc makeSingleLineCString*(s: string): string =
  result = "\""
  for c in items(s):
    result.add(c.toCChar)
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

proc makeLLVMString*(s: string): Rope =
  const MaxLineLength = 64
  result = nil
  var res = "c\""
  for i in countup(0, len(s) - 1):
    if (i + 1) mod MaxLineLength == 0:
      add(result, rope(res))
      setLen(res, 0)
    case s[i]
    of '\0'..'\x1F', '\x80'..'\xFF', '\"', '\\':
      add(res, '\\')
      add(res, toHex(ord(s[i]), 2))
    else: add(res, s[i])
  add(res, "\\00\"")
  add(result, rope(res))

initTypeTables()
