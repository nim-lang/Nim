discard """
  output: "Success!"
"""
# Test variable length binary integers

import
  strutils

type
  TBuffer = array[0..10, int8]

proc toVarNum(x: int32, b: var TBuffer) =
  # encoding: first bit indicates end of number (0 if at end)
  # second bit of the first byte denotes the sign (1 --> negative)
  var a = x
  if x != low(x):
    # low(int) is a special case,
    # because abs() does not work here!
    # we leave x as it is and use the check >% instead of >
    # for low(int) this is needed and positive numbers are not affected
    # anyway
    a = abs(x)
  # first 6 bits:
  b[0] = toU8(ord(a >% 63'i32) shl 7 or (ord(x < 0'i32) shl 6) or (int(a) and 63))
  a = (a shr 6'i32) and 0x03ffffff # skip first 6 bits
  var i = 1
  while a != 0'i32:
    b[i] = toU8(ord(a >% 127'i32) shl 7 or (int(a) and 127))
    inc(i)
    a = a shr 7'i32

proc toVarNum64(x: int64, b: var TBuffer) =
  # encoding: first bit indicates end of number (0 if at end)
  # second bit of the first byte denotes the sign (1 --> negative)
  var a = x
  if x != low(x):
    # low(int) is a special case,
    # because abs() does not work here!
    # we leave x as it is and use the check >% instead of >
    # for low(int) this is needed and positive numbers are not affected
    # anyway
    a = abs(x)
  # first 6 bits:
  b[0] = toU8(ord(a >% 63'i64) shl 7 or (ord(x < 0'i64) shl 6) or int(a and 63))
  a = (a shr 6) and 0x03ffffffffffffff # skip first 6 bits
  var i = 1
  while a != 0'i64:
    b[i] = toU8(ord(a >% 127'i64) shl 7 or int(a and 127))
    inc(i)
    a = a shr 7

proc toNum64(b: TBuffer): int64 =
  # treat first byte different:
  result = ze64(b[0]) and 63
  var
    i = 0
    Shift = 6'i64
  while (ze(b[i]) and 128) != 0:
    inc(i)
    result = result or ((ze64(b[i]) and 127) shl Shift)
    inc(Shift, 7)
  if (ze(b[0]) and 64) != 0: # sign bit set?
    result = not result +% 1
    # this is the same as ``- result``
    # but gives no overflow error for low(int)

proc toNum(b: TBuffer): int32 =
  # treat first byte different:
  result = int32 ze(b[0]) and 63
  var
    i = 0
    Shift = 6'i32
  while (ze(b[i]) and 128) != 0:
    inc(i)
    result = result or ((int32(ze(b[i])) and 127'i32) shl Shift)
    Shift = Shift + 7'i32
  if (ze(b[0]) and (1 shl 6)) != 0: # sign bit set?
    result = (not result) +% 1'i32
    # this is the same as ``- result``
    # but gives no overflow error for low(int)

proc toBinary(x: int64): string =
  result = newString(64)
  for i in 0..63:
    result[63-i] = chr((int(x shr i) and 1) + ord('0'))

proc t64(i: int64) =
  var
    b: TBuffer
  toVarNum64(i, b)
  var x = toNum64(b)
  if x != i:
    writeLine(stdout, $i)
    writeLine(stdout, toBinary(i))
    writeLine(stdout, toBinary(x))

proc t32(i: int32) =
  var
    b: TBuffer
  toVarNum(i, b)
  var x = toNum(b)
  if x != i:
    writeLine(stdout, toBinary(i))
    writeLine(stdout, toBinary(x))

proc tm(i: int32) =
  var
    b: TBuffer
  toVarNum64(i, b)
  var x = toNum(b)
  if x != i:
    writeLine(stdout, toBinary(i))
    writeLine(stdout, toBinary(x))

t32(0)
t32(1)
t32(-1)
t32(-100_000)
t32(100_000)
t32(low(int32))
t32(high(int32))

t64(low(int64))
t64(high(int64))
t64(0)
t64(-1)
t64(1)
t64(1000_000)
t64(-1000_000)

tm(0)
tm(1)
tm(-1)
tm(-100_000)
tm(100_000)
tm(low(int32))
tm(high(int32))

writeLine(stdout, "Success!") #OUT Success!
