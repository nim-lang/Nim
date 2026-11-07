import ropes, int128

type
  Snippet* = string
  Builder* = object
    buf*: string
    indents*: int

template newBuilder*(s: string): Builder =
  Builder(buf: s)

proc extract*(builder: Builder): Snippet =
  builder.buf

# Indentation is relative: `indents` only applies to the lines of `buf`, and
# a multi-line snippet that is added to a builder (typically the extracted
# contents of another builder, like a nested block's statements) has its lines
# shifted by the indentation of the builder it is added to. Indentation is
# written lazily when the first character of a line is added, so that empty
# lines carry no trailing whitespace and `indents` can still change after a
# newline has been added. Preprocessor lines always start in column 0.

proc addIndentation(builder: var Builder) {.inline.} =
  var i = builder.buf.len
  let newLen = i + builder.indents
  builder.buf.setLen(newLen)
  while i < newLen:
    builder.buf[i] = '\t'
    inc i

template atLineStart*(builder: Builder): bool =
  builder.buf.len == 0 or builder.buf[^1] == '\n'

proc add*(builder: var Builder, s: string) =
  if builder.indents <= 0:
    builder.buf.add(s)
  else:
    var i = 0
    while i < s.len:
      if s[i] notin {'\n', '#'} and builder.atLineStart:
        builder.addIndentation()
      var e = i
      while e < s.len and s[e] != '\n': inc e
      if e < s.len: inc e # include the newline
      let oldLen = builder.buf.len
      builder.buf.setLen(oldLen + e - i)
      copyMem(addr builder.buf[oldLen], unsafeAddr s[i], e - i)
      i = e

proc add*(builder: var Builder, s: char) =
  if builder.indents > 0 and s notin {'\n', '#'} and builder.atLineStart:
    builder.addIndentation()
  builder.buf.add(s)

proc addNewline*(builder: var Builder) =
  builder.buf.add('\n')

proc addLineEnd*(builder: var Builder, s: string) =
  builder.add(s)
  builder.addNewline()

proc addLineEndIndent*(builder: var Builder, s: string) =
  builder.add(s)
  builder.addNewline()
  inc builder.indents

proc addDedent*(builder: var Builder, s: string) =
  dec builder.indents
  builder.add(s)

proc addLineEndDedent*(builder: var Builder, s: string) =
  builder.addDedent(s)
  builder.addNewline()

proc addLineComment*(builder: var Builder, comment: string) =
  # probably no-op on nifc
  builder.add("// ")
  builder.add(comment)
  builder.addNewline()

proc addIntValue*(builder: var Builder, val: int) =
  builder.buf.addInt(val)

proc addIntValue*(builder: var Builder, val: int64) =
  builder.buf.addInt(val)

proc addIntValue*(builder: var Builder, val: uint64) =
  builder.buf.addInt(val)

proc addIntValue*(builder: var Builder, val: Int128) =
  builder.buf.addInt128(val)

template cIntValue*(val: int): Snippet = $val
template cIntValue*(val: int64): Snippet = $val
template cIntValue*(val: uint64): Snippet = $val
template cIntValue*(val: Int128): Snippet = $val

template cUintValue*(val: uint): Snippet = $val & "U"

import std/formatfloat

proc addFloatValue*(builder: var Builder, val: float) =
  builder.buf.addFloat(val)

template cFloatValue*(val: float): Snippet = $val

proc addInt64Literal*(result: var Builder; i: BiggestInt) =
  if i > low(int64):
    result.add "IL64($1)" % [rope(i)]
  else:
    result.add "(IL64(-9223372036854775807) - IL64(1))"

proc addUint64Literal*(result: var Builder; i: uint64) =
  result.add rope($i & "ULL")

proc addIntLiteral*(result: var Builder; i: BiggestInt) =
  if i > low(int32) and i <= high(int32):
    result.addIntValue(i)
  elif i == low(int32):
    # Nim has the same bug for the same reasons :-)
    result.add "(-2147483647 -1)"
  elif i > low(int64):
    result.add "IL64($1)" % [rope(i)]
  else:
    result.add "(IL64(-9223372036854775807) - IL64(1))"

proc addIntLiteral*(result: var Builder; i: Int128) =
  addIntLiteral(result, toInt64(i))

proc cInt64Literal*(i: BiggestInt): Snippet =
  if i > low(int64):
    result = "IL64($1)" % [rope(i)]
  else:
    result = "(IL64(-9223372036854775807) - IL64(1))"

proc cUint64Literal*(i: uint64): Snippet =
  result = $i & "ULL"

proc cIntLiteral*(i: BiggestInt): Snippet =
  if i > low(int32) and i <= high(int32):
    result = rope(i)
  elif i == low(int32):
    # Nim has the same bug for the same reasons :-)
    result = "(-2147483647 -1)"
  elif i > low(int64):
    result = "IL64($1)" % [rope(i)]
  else:
    result = "(IL64(-9223372036854775807) - IL64(1))"

proc cIntLiteral*(i: Int128): Snippet =
  result = cIntLiteral(toInt64(i))

const
  NimInt* = "NI"
  NimInt8* = "NI8"
  NimInt16* = "NI16"
  NimInt32* = "NI32"
  NimInt64* = "NI64"
  CInt* = "int"
  NimUint* = "NU"
  NimUint8* = "NU8"
  NimUint16* = "NU16"
  NimUint32* = "NU32"
  NimUint64* = "NU64"
  NimFloat* = "NF"
  NimFloat32* = "NF32"
  NimFloat64* = "NF64"
  NimFloat128* = "NF128" # not actually defined
  NimNan* = "NAN"
  NimInf* = "INF"
  NimBool* = "NIM_BOOL"
  NimTrue* = "NIM_TRUE"
  NimFalse* = "NIM_FALSE"
  NimChar* = "NIM_CHAR"
  CChar* = "char"
  NimCstring* = "NCSTRING"
  NimNil* = "NIM_NIL"
  CNil* = "NULL"
  NimStrlitFlag* = "NIM_STRLIT_FLAG"
  CVoid* = "void"
  CPointer* = "void*"
  CConstPointer* = "NIM_CONST void*"

proc cIntType*(bits: BiggestInt): Snippet =
  "NI" & $bits

proc cUintType*(bits: BiggestInt): Snippet =
  "NU" & $bits

type
  IfBuilderState* = enum
    WaitingIf, WaitingElseIf, InBlock
  IfBuilder* = object
    state*: IfBuilderState
