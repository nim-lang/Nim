#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Serialization utilities for the compiler.
import

  ".."/[ lineinfos, rodutils ]

import

  strutils, math


type
  EncodingString* = distinct string
  EncodingKind* = enum
    FileNum = "unused?"
    OpenType
    CloseType
    OpenLoc
    CloseLoc
    OpenNode
    CloseNode
    OpenSym
    CloseSym
    Comma
    CallConv
    JustCol
    LineAndCol
    LineColFile
    SomeFlags = "flags in an int32"
    UniqueId = "a type's uniqueId"
    SymbolId = "a symbol's id"
    OwnerId = "a symbol's id"
    SizeValue = "type's size"
    TypeAlignment = "type's alignment"
    AnLiteral
    AnType
    AnNode
    AnIdent
    LocStorage
    LockLevel
    PaddingAtEnd
    AttachedOps
    MethodIndex
    MethodId
    TypeInst
    TypeId
    TypeCompiles
    SymbolFlags
    SymbolMagic
    SymbolPos
    SymbolOffset
    SymbolConstraint
    Unsafety
    Transformed
    Guard
    BitSize

converter toEncodingString*(s: var string): var EncodingString = s.EncodingString
converter toEncodingString*(s: string): EncodingString = s.EncodingString
converter toChar*(k: EncodingKind): char = k.char
converter toEncodingKind*(c: char): EncodingKind = ord(c).EncodingKind

proc `$`*(e: EncodingString): string {.borrow.}
proc len*(e: EncodingString): int {.borrow.}
proc setLen*(e: var EncodingString; newlen: Natural) {.borrow.}
proc add*(e: var EncodingString; s: string) {.borrow.}
proc add*(e: var EncodingString; c: char) {.borrow.}
proc add*(e: var EncodingString; kinds: varargs[EncodingKind]) =
  for v in kinds.items:
    e.add v.char

proc encodeStr*(s: string, result: var EncodingString) =
  for i in 0..<s.len:
    case s[i]
    of 'a'..'z', 'A'..'Z', '0'..'9', '_': result.add(s[i])
    else: result.add('\\' & toHex(ord(s[i]), 2))

proc hexChar(c: char, xi: var int) =
  case c
  of '0'..'9': xi = (xi shl 4) or (ord(c) - ord('0'))
  of 'a'..'f': xi = (xi shl 4) or (ord(c) - ord('a') + 10)
  of 'A'..'F': xi = (xi shl 4) or (ord(c) - ord('A') + 10)
  else: discard

proc decodeStr*(s: cstring, pos: var int): string =
  var i = pos
  result = ""
  while true:
    case s[i]
    of '\\':
      inc(i, 3)
      var xi = 0
      hexChar(s[i-2], xi)
      hexChar(s[i-1], xi)
      result.add(chr(xi))
    of 'a'..'z', 'A'..'Z', '0'..'9', '_':
      result.add(s[i])
      inc(i)
    else: break
  pos = i

const
  chars = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

{.push overflowChecks: off.}

# since negative numbers require a leading '-' they use up 1 byte. Thus we
# subtract/add `vintDelta` here to save space for small negative numbers
# which are common in ROD files:
const
  vintDelta = 5

template encodeIntImpl(self) =
  var d: char
  var v = x
  var rem = v mod 190
  if rem < 0:
    result.add('-')
    v = - (v div 190)
    rem = - rem
  else:
    v = v div 190
  var idx = int(rem)
  if idx < 62: d = chars[idx]
  else: d = chr(idx - 62 + 128)
  if v != 0: self(v, result)
  result.add(d)

proc encodeVBiggestIntAux(x: BiggestInt, result: var EncodingString) =
  ## encode a biggest int as a variable length base 190 int.
  encodeIntImpl(encodeVBiggestIntAux)

proc encodeVIntAux(x: int, result: var EncodingString) =
  ## encode an int as a variable length base 190 int.
  encodeIntImpl(encodeVIntAux)

proc add*(e: var EncodingString; i: BiggestInt) =
  ## encode a biggest int as a variable length base 190 int.
  encodeVBiggestIntAux(i +% vintDelta, e)

proc add*(e: var EncodingString; i: int | uint16 | int16 | int32) =
  ## encode an int as a variable length base 190 int.
  encodeVIntAux(i.int +% vintDelta, e)

template add*(e: var EncodingString; i: FileIndex) =
  ## a file index is simply encoded as an integer, of course
  e.add i.int32

proc add*(e: var EncodingString; k: EncodingKind) =
  e.add k.char

proc encodeVBiggestInt*(x: BiggestInt, result: var EncodingString)
  {.deprecated: "use add()".} =
  result.add x

proc encodeVInt*(x: int, result: var EncodingString)
  {.deprecated: "use add()".} =
  result.add x

template decodeIntImpl() =
  var i = pos
  var sign = - 1
  assert(s[i] in {'a'..'z', 'A'..'Z', '0'..'9', '-', '\x80'..'\xFF'})
  if s[i] == '-':
    inc(i)
    sign = 1
  result = 0
  while true:
    case s[i]
    #of '0'..'9': result = result * 190 - (ord(s[i]) - ord('0'))
    #of 'a'..'z': result = result * 190 - (ord(s[i]) - ord('a') + 10)
    #of 'A'..'Z': result = result * 190 - (ord(s[i]) - ord('A') + 36)
    #of '\x80'..'\xFF': result = result * 190 - (ord(s[i]) - 128 + 62)
    of '\x80'..'\xFF': result = result * 128 - (ord(s[i]) - 128)
    else: break
    inc(i)
  result = result * sign -% vintDelta
  pos = i

proc decodeVInt*(s: cstring, pos: var int): int =
  decodeIntImpl()

proc decodeVBiggestInt*(s: cstring, pos: var int): BiggestInt =
  decodeIntImpl()

{.pop.}

iterator decodeVIntArray*(s: cstring): int =
  var i = 0
  while s[i] != '\0':
    yield decodeVInt(s, i)
    if s[i] == ' ': inc i

iterator decodeStrArray*(s: cstring): string =
  var i = 0
  while s[i] != '\0':
    yield decodeStr(s, i)
    if s[i] == ' ': inc i

proc addLineInfo*(e: var EncodingString; kind: EncodingKind;
                  line = uint16(0); column = int16(-1); file = FileIndex(-1)) =
  e.add kind
  case kind
  of JustCol:
    e.add column
  of LineAndCol:
    e.add column
    e.add Comma
    e.add line
  of LineColFile:
    e.add column
    e.add Comma
    e.add line
    e.add Comma
    e.add file
  else:
    raise newException(Defect, "use JustCol, LineAndCol, or LineColFile")

proc addLineInfo*(e: var EncodingString; kind: EncodingKind; info: TLineInfo) =
  e.addLineInfo(kind, line = info.line,
                      column = info.col,
                      file = info.fileIndex)

proc addLineInfoDelta*(e: var EncodingString; info: TLineInfo; old: TLineInfo) =
  if old.fileIndex != info.fileIndex:
    e.addLineInfo(LineColFile, info)
  elif old.line == info.line:
    e.addLineInfo(JustCol, info)
  else:
    e.addLineInfo(LineAndCol, info)
