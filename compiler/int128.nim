## This module is for compiler internal use only. For reliable error
## messages and range checks, the compiler needs a data type that can
## hold all from ``low(BiggestInt)`` to ``high(BiggestUInt)``, This
## type is for that purpose.

from math import trunc

type
  Int128* = object
    udata: array[4,uint32]

template sdata(arg: Int128, idx: int): int32 =
  # udata and sdata was supposed to be in a union, but unions are
  # handled incorrectly in the VM.
  cast[ptr int32](arg.udata[idx].unsafeAddr)[]

# encoding least significant int first (like LittleEndian)

const
  Zero* = Int128(udata: [0'u32,0,0,0])
  One* = Int128(udata: [1'u32,0,0,0])
  Ten* = Int128(udata: [10'u32,0,0,0])
  Min = Int128(udata: [0'u32,0,0,0x80000000'u32])
  Max = Int128(udata: [high(uint32),high(uint32),high(uint32),uint32(high(int32))])
  NegOne* = Int128(udata: [0xffffffff'u32,0xffffffff'u32,0xffffffff'u32,0xffffffff'u32])

template low*(t: typedesc[Int128]): Int128 = Min
template high*(t: typedesc[Int128]): Int128 = Max

proc `$`*(a: Int128): string

proc toInt128*[T: SomeInteger | bool](arg: T): Int128 =
  when T is bool: result.sdata(0) = int32(arg)
  elif T is SomeUnsignedInt:
    when sizeof(arg) <= 4:
      result.udata[0] = uint32(arg)
    else:
      result.udata[0] = uint32(arg and T(0xffffffff))
      result.udata[1] = uint32(arg shr 32)
  elif sizeof(arg) <= 4:
    result.sdata(0) = int32(arg)
    if arg < 0: # sign extend
      result.sdata(1) = -1
      result.sdata(2) = -1
      result.sdata(3) = -1
  else:
    let tmp = int64(arg)
    result.udata[0] = uint32(tmp and 0xffffffff)
    result.sdata(1) = int32(tmp shr 32)
    if arg < 0: # sign extend
      result.sdata(2) = -1
      result.sdata(3) = -1

template isNegative(arg: Int128): bool =
  arg.sdata(3) < 0

template isNegative(arg: int32): bool =
  arg < 0

proc bitconcat(a,b: uint32): uint64 =
  (uint64(a) shl 32) or uint64(b)

proc bitsplit(a: uint64): (uint32,uint32) =
  (cast[uint32](a shr 32), cast[uint32](a))

proc toInt64*(arg: Int128): int64 =
  if isNegative(arg):
    assert(arg.sdata(3) == -1, "out of range")
    assert(arg.sdata(2) == -1, "out of range")
  else:
    assert(arg.sdata(3) == 0, "out of range")
    assert(arg.sdata(2) == 0, "out of range")

  cast[int64](bitconcat(arg.udata[1], arg.udata[0]))

proc toInt64Checked*(arg: Int128; onError: int64): int64 =
  if isNegative(arg):
    if arg.sdata(3) != -1 or arg.sdata(2) != -1:
      return onError
  else:
    if arg.sdata(3) != 0 or arg.sdata(2) != 0:
      return onError
  return cast[int64](bitconcat(arg.udata[1], arg.udata[0]))

proc toInt32*(arg: Int128): int32 =
  if isNegative(arg):
    assert(arg.sdata(3) == -1, "out of range")
    assert(arg.sdata(2) == -1, "out of range")
    assert(arg.sdata(1) == -1, "out of range")
  else:
    assert(arg.sdata(3) == 0, "out of range")
    assert(arg.sdata(2) == 0, "out of range")
    assert(arg.sdata(1) == 0, "out of range")

  arg.sdata(0)

proc toInt16*(arg: Int128): int16 =
  if isNegative(arg):
    assert(arg.sdata(3) == -1, "out of range")
    assert(arg.sdata(2) == -1, "out of range")
    assert(arg.sdata(1) == -1, "out of range")
  else:
    assert(arg.sdata(3) == 0, "out of range")
    assert(arg.sdata(2) == 0, "out of range")
    assert(arg.sdata(1) == 0, "out of range")

  int16(arg.sdata(0))

proc toInt8*(arg: Int128): int8 =
  if isNegative(arg):
    assert(arg.sdata(3) == -1, "out of range")
    assert(arg.sdata(2) == -1, "out of range")
    assert(arg.sdata(1) == -1, "out of range")
  else:
    assert(arg.sdata(3) == 0, "out of range")
    assert(arg.sdata(2) == 0, "out of range")
    assert(arg.sdata(1) == 0, "out of range")

  int8(arg.sdata(0))

proc toInt*(arg: Int128): int =
  when sizeof(int) == 4:
    cast[int](toInt32(arg))
  else:
    cast[int](toInt64(arg))

proc toUInt64*(arg: Int128): uint64 =
  assert(arg.udata[3] == 0)
  assert(arg.udata[2] == 0)
  bitconcat(arg.udata[1], arg.udata[0])

proc toUInt32*(arg: Int128): uint32 =
  assert(arg.udata[3] == 0)
  assert(arg.udata[2] == 0)
  assert(arg.udata[1] == 0)
  arg.udata[0]

proc toUInt16*(arg: Int128): uint16 =
  assert(arg.udata[3] == 0)
  assert(arg.udata[2] == 0)
  assert(arg.udata[1] == 0)
  uint16(arg.udata[0])

proc toUInt8*(arg: Int128): uint8 =
  assert(arg.udata[3] == 0)
  assert(arg.udata[2] == 0)
  assert(arg.udata[1] == 0)
  uint8(arg.udata[0])

proc toUInt*(arg: Int128): uint =
  when sizeof(int) == 4:
    cast[uint](toInt32(arg))
  else:
    cast[uint](toInt64(arg))

proc castToInt64*(arg: Int128): int64 =
  ## Conversion to int64 without range check.
  cast[int64](bitconcat(arg.udata[1], arg.udata[0]))

proc castToUInt64*(arg: Int128): uint64 =
  ## Conversion to uint64 without range check.
  cast[uint64](bitconcat(arg.udata[1], arg.udata[0]))

proc addToHex(result: var string; arg: uint32) =
  for i in 0..<8:
    let idx = (arg shr ((7-i) * 4)) and 0xf
    result.add "0123456789abcdef"[idx]

proc addToHex*(result: var string; arg: Int128) =
  var i = 3
  while i >= 0:
    result.addToHex(arg.udata[i])
    i -= 1

proc toHex*(arg: Int128): string =
  result.addToHex(arg)

proc inc*(a: var Int128, y: uint32 = 1) =
  let input = a
  a.udata[0] += y
  if unlikely(a.udata[0] < y):
    a.udata[1].inc
    if unlikely(a.udata[1] == 0):
      a.udata[2].inc
      if unlikely(a.udata[2] == 0):
        a.udata[3].inc
        doAssert(a.sdata(3) != low(int32), "overflow")

proc cmp*(a,b: Int128): int =
  let tmp1 = cmp(a.sdata(3), b.sdata(3))
  if tmp1 != 0: return tmp1
  let tmp2 = cmp(a.udata[2], b.udata[2])
  if tmp2 != 0: return tmp2
  let tmp3 = cmp(a.udata[1], b.udata[1])
  if tmp3 != 0: return tmp3
  let tmp4 = cmp(a.udata[0], b.udata[0])
  return tmp4

proc `<`*(a,b: Int128): bool =
  cmp(a,b) < 0

proc `<=`*(a,b: Int128): bool =
  cmp(a,b) <= 0

proc `==`*(a,b: Int128): bool =
  if a.udata[0] != b.udata[0]: return false
  if a.udata[1] != b.udata[1]: return false
  if a.udata[2] != b.udata[2]: return false
  if a.udata[3] != b.udata[3]: return false
  return true

proc inplaceBitnot(a: var Int128) =
  a.udata[0] = not a.udata[0]
  a.udata[1] = not a.udata[1]
  a.udata[2] = not a.udata[2]
  a.udata[3] = not a.udata[3]

proc bitnot*(a: Int128): Int128 =
  result.udata[0] = not a.udata[0]
  result.udata[1] = not a.udata[1]
  result.udata[2] = not a.udata[2]
  result.udata[3] = not a.udata[3]

proc bitand*(a,b: Int128): Int128 =
  result.udata[0] = a.udata[0] and b.udata[0]
  result.udata[1] = a.udata[1] and b.udata[1]
  result.udata[2] = a.udata[2] and b.udata[2]
  result.udata[3] = a.udata[3] and b.udata[3]

proc bitor*(a,b: Int128): Int128 =
  result.udata[0] = a.udata[0] or b.udata[0]
  result.udata[1] = a.udata[1] or b.udata[1]
  result.udata[2] = a.udata[2] or b.udata[2]
  result.udata[3] = a.udata[3] or b.udata[3]

proc bitxor*(a,b: Int128): Int128 =
  result.udata[0] = a.udata[0] xor b.udata[0]
  result.udata[1] = a.udata[1] xor b.udata[1]
  result.udata[2] = a.udata[2] xor b.udata[2]
  result.udata[3] = a.udata[3] xor b.udata[3]

proc `shr`*(a: Int128, b: int): Int128 =
  let b = b and 127
  if b < 32:
    result.sdata(3) = a.sdata(3) shr b
    result.udata[2] = cast[uint32](bitconcat(a.udata[3], a.udata[2]) shr b)
    result.udata[1] = cast[uint32](bitconcat(a.udata[2], a.udata[1]) shr b)
    result.udata[0] = cast[uint32](bitconcat(a.udata[1], a.udata[0]) shr b)
  elif b < 64:
    if isNegative(a):
      result.sdata(3) = -1
    result.sdata(2) = a.sdata(3) shr (b and 31)
    result.udata[1] = cast[uint32](bitconcat(a.udata[3], a.udata[2]) shr (b and 31))
    result.udata[0] = cast[uint32](bitconcat(a.udata[2], a.udata[1]) shr (b and 31))
  elif b < 96:
    if isNegative(a):
      result.sdata(3) = -1
      result.sdata(2) = -1
    result.sdata(1) = a.sdata(3) shr (b and 31)
    result.udata[0] = cast[uint32](bitconcat(a.udata[3], a.udata[2]) shr (b and 31))
  else: # b < 128
    if isNegative(a):
      result.sdata(3) = -1
      result.sdata(2) = -1
      result.sdata(1) = -1
    result.sdata(0) = a.sdata(3) shr (b and 31)

proc `shl`*(a: Int128, b: int): Int128 =
  let b = b and 127
  if b < 32:
    result.udata[0] = a.udata[0] shl b
    result.udata[1] = cast[uint32]((bitconcat(a.udata[1], a.udata[0]) shl b) shr 32)
    result.udata[2] = cast[uint32]((bitconcat(a.udata[2], a.udata[1]) shl b) shr 32)
    result.udata[3] = cast[uint32]((bitconcat(a.udata[3], a.udata[2]) shl b) shr 32)
  elif b < 64:
    result.udata[0] = 0
    result.udata[1] = a.udata[0] shl (b and 31)
    result.udata[2] = cast[uint32]((bitconcat(a.udata[1], a.udata[0]) shl (b and 31)) shr 32)
    result.udata[3] = cast[uint32]((bitconcat(a.udata[2], a.udata[1]) shl (b and 31)) shr 32)
  elif b < 96:
    result.udata[0] = 0
    result.udata[1] = 0
    result.udata[2] = a.udata[0] shl (b and 31)
    result.udata[3] = cast[uint32]((bitconcat(a.udata[1], a.udata[0]) shl (b and 31)) shr 32)
  else:
    result.udata[0] = 0
    result.udata[1] = 0
    result.udata[2] = 0
    result.udata[3] = a.udata[0] shl (b and 31)

proc `+`*(a,b: Int128): Int128 =
  let tmp0 = uint64(a.udata[0]) + uint64(b.udata[0])
  result.udata[0] = cast[uint32](tmp0)
  let tmp1 = uint64(a.udata[1]) + uint64(b.udata[1]) + (tmp0 shr 32)
  result.udata[1] = cast[uint32](tmp1)
  let tmp2 = uint64(a.udata[2]) + uint64(b.udata[2]) + (tmp1 shr 32)
  result.udata[2] = cast[uint32](tmp2)
  let tmp3 = uint64(a.udata[3]) + uint64(b.udata[3]) + (tmp2 shr 32)
  result.udata[3] = cast[uint32](tmp3)

proc `+=`*(a: var Int128, b: Int128) =
  a = a + b

proc `-`*(a: Int128): Int128 =
  result = bitnot(a)
  result.inc

proc `-`*(a,b: Int128): Int128 =
  a + (-b)

proc `-=`*(a: var Int128, b: Int128) =
  a = a - b

proc abs*(a: Int128): Int128 =
  if isNegative(a):
    -a
  else:
    a

proc abs(a: int32): int =
  if a < 0: -a else: a

proc `*`(a: Int128, b: uint32): Int128 =
  let tmp0 = uint64(a.udata[0]) * uint64(b)
  let tmp1 = uint64(a.udata[1]) * uint64(b)
  let tmp2 = uint64(a.udata[2]) * uint64(b)
  let tmp3 = uint64(a.udata[3]) * uint64(b)

  if unlikely(tmp3 > uint64(high(int32))):
    assert(false, "overflow")

  result.udata[0] = cast[uint32](tmp0)
  result.udata[1] = cast[uint32](tmp1) + cast[uint32](tmp0 shr 32)
  result.udata[2] = cast[uint32](tmp2) + cast[uint32](tmp1 shr 32)
  result.udata[3] = cast[uint32](tmp3) + cast[uint32](tmp2 shr 32)

proc `*`*(a: Int128, b: int32): Int128 =
  result = a * cast[uint32](abs(b))
  if b < 0:
    result = -result

proc `*=`*(a: var Int128, b: int32): Int128 =
  result = result * b

proc makeInt128(high,low: uint64): Int128 =
  result.udata[0] = cast[uint32](low)
  result.udata[1] = cast[uint32](low shr 32)
  result.udata[2] = cast[uint32](high)
  result.udata[3] = cast[uint32](high shr 32)

proc high64(a: Int128): uint64 =
  bitconcat(a.udata[3], a.udata[2])

proc low64(a: Int128): uint64 =
  bitconcat(a.udata[1], a.udata[0])

proc `*`*(lhs,rhs: Int128): Int128 =
  let
    a = cast[uint64](lhs.udata[0])
    b = cast[uint64](lhs.udata[1])
    c = cast[uint64](lhs.udata[2])
    d = cast[uint64](lhs.udata[3])

    e = cast[uint64](rhs.udata[0])
    f = cast[uint64](rhs.udata[1])
    g = cast[uint64](rhs.udata[2])
    h = cast[uint64](rhs.udata[3])


  let a32 = cast[uint64](lhs.udata[1])
  let a00 = cast[uint64](lhs.udata[0])
  let b32 = cast[uint64](rhs.udata[1])
  let b00 = cast[uint64](rhs.udata[0])

  result = makeInt128(high64(lhs) * low64(rhs) + low64(lhs) * high64(rhs) + a32 * b32, a00 * b00)
  result += toInt128(a32 * b00) shl 32
  result += toInt128(a00 * b32) shl 32

proc `*=`*(a: var Int128, b: Int128) =
  a = a * b

import bitops

proc fastLog2*(a: Int128): int =
  if a.udata[3] != 0:
    return 96 + fastLog2(a.udata[3])
  if a.udata[2] != 0:
    return 64 + fastLog2(a.udata[2])
  if a.udata[1] != 0:
    return 32 + fastLog2(a.udata[1])
  if a.udata[0] != 0:
    return      fastLog2(a.udata[0])

proc divMod*(dividend, divisor: Int128): tuple[quotient, remainder: Int128] =
  assert(divisor != Zero)
  let isNegativeA = isNegative(dividend)
  let isNegativeB = isNegative(divisor)

  var dividend = abs(dividend)
  let divisor = abs(divisor)

  if divisor > dividend:
    result.quotient = Zero
    if isNegativeA:
      result.remainder = -dividend
    else:
      result.remainder = dividend
    return

  if divisor == dividend:
    if isNegativeA xor isNegativeB:
      result.quotient = NegOne
    else:
      result.quotient = One
    result.remainder = Zero
    return

  var denominator = divisor
  var quotient = Zero

  # Left aligns the MSB of the denominator and the dividend.
  let shift = fastLog2(dividend) - fastLog2(denominator)
  denominator = denominator shl shift

  # Uses shift-subtract algorithm to divide dividend by denominator. The
  # remainder will be left in dividend.
  for i in 0..shift:
    quotient = quotient shl 1
    if dividend >= denominator:
      dividend -= denominator
      quotient = bitor(quotient, One)

    denominator = denominator shr 1

  if isNegativeA xor isNegativeB:
    result.quotient = -quotient
  else:
    result.quotient = quotient
  if isNegativeA:
    result.remainder = -dividend
  else:
    result.remainder = dividend

proc `div`*(a,b: Int128): Int128 =
  let (a,b) = divMod(a,b)
  return a

proc `mod`*(a,b: Int128): Int128 =
  let (a,b) = divMod(a,b)
  return b

proc addInt128*(result: var string; value: Int128) =
  let initialSize = result.len
  if value == Zero:
    result.add "0"
  elif value == low(Int128):
    result.add "-170141183460469231731687303715884105728"
  else:
    let isNegative = isNegative(value)
    var value = abs(value)
    while value > Zero:
      let (quot, rem) = divMod(value, Ten)
      result.add "0123456789"[rem.toInt64]
      value = quot
    if isNegative:
      result.add '-'

    var i = initialSize
    var j = high(result)
    while i < j:
      swap(result[i], result[j])
      i += 1
      j -= 1

proc `$`*(a: Int128): string =
  result.addInt128(a)

proc parseDecimalInt128*(arg: string, pos: int = 0): Int128 =
  assert(pos < arg.len)
  assert(arg[pos] in {'-','0'..'9'})

  var isNegative = false
  var pos = pos
  if arg[pos] == '-':
    isNegative = true
    pos += 1

  result = Zero
  while pos < arg.len and arg[pos] in '0'..'9':
    result = result * Ten
    result.inc(uint32(arg[pos]) - uint32('0'))
    pos += 1

  if isNegative:
    result = -result

# fluff

proc `<`*(a: Int128, b: BiggestInt): bool =
  cmp(a,toInt128(b)) < 0

proc `<`*(a: BiggestInt, b: Int128): bool =
  cmp(toInt128(a), b) < 0

proc `<=`*(a: Int128, b: BiggestInt): bool =
  cmp(a,toInt128(b)) <= 0

proc `<=`*(a: BiggestInt, b: Int128): bool =
  cmp(toInt128(a), b) <= 0

proc `==`*(a: Int128, b: BiggestInt): bool =
  a == toInt128(b)

proc `==`*(a: BiggestInt, b: Int128): bool =
  toInt128(a) == b

proc `-`*(a: BiggestInt, b: Int128): Int128 =
  toInt128(a) - b

proc `-`*(a: Int128, b: BiggestInt): Int128 =
  a - toInt128(b)

proc `+`*(a: BiggestInt, b: Int128): Int128 =
  toInt128(a) + b

proc `+`*(a: Int128, b: BiggestInt): Int128 =
  a + toInt128(b)

proc toFloat64*(arg: Int128): float64 =
  let isNegative = isNegative(arg)
  let arg = abs(arg)

  let a = float64(bitconcat(arg.udata[1], arg.udata[0]))
  let b = float64(bitconcat(arg.udata[3], arg.udata[2]))

  result = a + 18446744073709551616'f64 * b # a + 2^64 * b
  if isNegative:
    result = -result

proc ldexp(x: float64, exp: cint): float64 {.importc: "ldexp", header: "<math.h>".}

template bitor(a,b,c: Int128): Int128 = bitor(bitor(a,b), c)

proc toInt128*(arg: float64): Int128 =
  let isNegative = arg < 0
  let v0 = ldexp(abs(arg), -100)
  let w0 = uint64(trunc(v0))
  let v1 = ldexp(v0 - float64(w0), 50)
  let w1 = uint64(trunc(v1))
  let v2 = ldexp(v1 - float64(w1), 50)
  let w2 = uint64(trunc(v2))

  let res = bitor(toInt128(w0) shl 100, toInt128(w1) shl 50, toInt128(w2))
  if isNegative:
    return -res
  else:
    return res

proc maskUInt64*(arg: Int128): Int128 {.noinit, inline.} =
  result.udata[0] = arg.udata[0]
  result.udata[1] = arg.udata[1]
  result.udata[2] = 0
  result.udata[3] = 0

proc maskUInt32*(arg: Int128): Int128 {.noinit, inline.} =
  result.udata[0] = arg.udata[0]
  result.udata[1] = 0
  result.udata[2] = 0
  result.udata[3] = 0

proc maskUInt16*(arg: Int128): Int128 {.noinit, inline.} =
  result.udata[0] = arg.udata[0] and 0xffff
  result.udata[1] = 0
  result.udata[2] = 0
  result.udata[3] = 0

proc maskUInt8*(arg: Int128): Int128 {.noinit, inline.} =
  result.udata[0] = arg.udata[0] and 0xff
  result.udata[1] = 0
  result.udata[2] = 0
  result.udata[3] = 0

proc maskBytes*(arg: Int128, numbytes: int): Int128 {.noinit.} =
  case numbytes
  of 1:
    return maskUInt8(arg)
  of 2:
    return maskUInt16(arg)
  of 4:
    return maskUInt32(arg)
  of 8:
    return maskUInt64(arg)
  else:
    assert(false, "masking only implemented for 1, 2, 4 and 8 bytes")




when isMainModule:
  let (a,b) = divMod(Ten,Ten)

  doAssert $One == "1"
  doAssert $Ten == "10"
  doAssert $Zero == "0"
  let c = parseDecimalInt128("12345678989876543210123456789")
  doAssert $c == "12345678989876543210123456789"

  var d : array[39, Int128]
  d[0] =  parseDecimalInt128("1")
  d[1] =  parseDecimalInt128("10")
  d[2] =  parseDecimalInt128("100")
  d[3] =  parseDecimalInt128("1000")
  d[4] =  parseDecimalInt128("10000")
  d[5] =  parseDecimalInt128("100000")
  d[6] =  parseDecimalInt128("1000000")
  d[7] =  parseDecimalInt128("10000000")
  d[8] =  parseDecimalInt128("100000000")
  d[9] =  parseDecimalInt128("1000000000")
  d[10] = parseDecimalInt128("10000000000")
  d[11] = parseDecimalInt128("100000000000")
  d[12] = parseDecimalInt128("1000000000000")
  d[13] = parseDecimalInt128("10000000000000")
  d[14] = parseDecimalInt128("100000000000000")
  d[15] = parseDecimalInt128("1000000000000000")
  d[16] = parseDecimalInt128("10000000000000000")
  d[17] = parseDecimalInt128("100000000000000000")
  d[18] = parseDecimalInt128("1000000000000000000")
  d[19] = parseDecimalInt128("10000000000000000000")
  d[20] = parseDecimalInt128("100000000000000000000")
  d[21] = parseDecimalInt128("1000000000000000000000")
  d[22] = parseDecimalInt128("10000000000000000000000")
  d[23] = parseDecimalInt128("100000000000000000000000")
  d[24] = parseDecimalInt128("1000000000000000000000000")
  d[25] = parseDecimalInt128("10000000000000000000000000")
  d[26] = parseDecimalInt128("100000000000000000000000000")
  d[27] = parseDecimalInt128("1000000000000000000000000000")
  d[28] = parseDecimalInt128("10000000000000000000000000000")
  d[29] = parseDecimalInt128("100000000000000000000000000000")
  d[30] = parseDecimalInt128("1000000000000000000000000000000")
  d[31] = parseDecimalInt128("10000000000000000000000000000000")
  d[32] = parseDecimalInt128("100000000000000000000000000000000")
  d[33] = parseDecimalInt128("1000000000000000000000000000000000")
  d[34] = parseDecimalInt128("10000000000000000000000000000000000")
  d[35] = parseDecimalInt128("100000000000000000000000000000000000")
  d[36] = parseDecimalInt128("1000000000000000000000000000000000000")
  d[37] = parseDecimalInt128("10000000000000000000000000000000000000")
  d[38] = parseDecimalInt128("100000000000000000000000000000000000000")

  for i in 0..<d.len:
    for j in 0..<d.len:
      doAssert(cmp(d[i], d[j]) == cmp(i,j))
      if i + j < d.len:
        doAssert d[i] * d[j] == d[i+j]
      if i - j >= 0:
        doAssert d[i] div d[j] == d[i-j]

  var sum: Int128

  for it in d:
    sum += it

  doAssert $sum == "111111111111111111111111111111111111111"

  for it in d.mitems:
    it = -it

  for i in 0..<d.len:
    for j in 0..<d.len:
      doAssert(cmp(d[i], d[j]) == -cmp(i,j))
      if i + j < d.len:
        doAssert d[i] * d[j] == -d[i+j]
      if i - j >= 0:
        doAssert d[i] div d[j] == -d[i-j]

  doAssert $high(Int128) == "170141183460469231731687303715884105727"
  doAssert $low(Int128) == "-170141183460469231731687303715884105728"

  var ma = 100'i64
  var mb = 13

  doAssert toInt128(ma) * toInt128(0) == toInt128(0)
  doAssert toInt128(-ma) * toInt128(0) == toInt128(0)

  # sign correctness
  doAssert divMod(toInt128( ma),toInt128( mb)) == (toInt128( ma div  mb), toInt128( ma mod  mb))
  doAssert divMod(toInt128(-ma),toInt128( mb)) == (toInt128(-ma div  mb), toInt128(-ma mod  mb))
  doAssert divMod(toInt128( ma),toInt128(-mb)) == (toInt128( ma div -mb), toInt128( ma mod -mb))
  doAssert divMod(toInt128(-ma),toInt128(-mb)) == (toInt128(-ma div -mb), toInt128(-ma mod -mb))

  doAssert divMod(toInt128( mb),toInt128( mb)) == (toInt128( mb div  mb), toInt128( mb mod  mb))
  doAssert divMod(toInt128(-mb),toInt128( mb)) == (toInt128(-mb div  mb), toInt128(-mb mod  mb))
  doAssert divMod(toInt128( mb),toInt128(-mb)) == (toInt128( mb div -mb), toInt128( mb mod -mb))
  doAssert divMod(toInt128(-mb),toInt128(-mb)) == (toInt128(-mb div -mb), toInt128(-mb mod -mb))

  doAssert divMod(toInt128( mb),toInt128( ma)) == (toInt128( mb div  ma), toInt128( mb mod  ma))
  doAssert divMod(toInt128(-mb),toInt128( ma)) == (toInt128(-mb div  ma), toInt128(-mb mod  ma))
  doAssert divMod(toInt128( mb),toInt128(-ma)) == (toInt128( mb div -ma), toInt128( mb mod -ma))
  doAssert divMod(toInt128(-mb),toInt128(-ma)) == (toInt128(-mb div -ma), toInt128(-mb mod -ma))

  let e = parseDecimalInt128("70997106675279150998592376708984375")

  let strArray = [
    # toHex(e shr 0), toHex(e shr 1), toHex(e shr 2), toHex(e shr 3)
    "000dac6d782d266a37300c32591eee37", "0006d636bc1693351b9806192c8f771b", "00036b1b5e0b499a8dcc030c9647bb8d", "0001b58daf05a4cd46e601864b23ddc6",
    "0000dac6d782d266a37300c32591eee3", "00006d636bc1693351b9806192c8f771", "000036b1b5e0b499a8dcc030c9647bb8", "00001b58daf05a4cd46e601864b23ddc",
    "00000dac6d782d266a37300c32591eee", "000006d636bc1693351b9806192c8f77", "0000036b1b5e0b499a8dcc030c9647bb", "000001b58daf05a4cd46e601864b23dd",
    "000000dac6d782d266a37300c32591ee", "0000006d636bc1693351b9806192c8f7", "00000036b1b5e0b499a8dcc030c9647b", "0000001b58daf05a4cd46e601864b23d",
    "0000000dac6d782d266a37300c32591e", "00000006d636bc1693351b9806192c8f", "000000036b1b5e0b499a8dcc030c9647", "00000001b58daf05a4cd46e601864b23",
    "00000000dac6d782d266a37300c32591", "000000006d636bc1693351b9806192c8", "0000000036b1b5e0b499a8dcc030c964", "000000001b58daf05a4cd46e601864b2",
    "000000000dac6d782d266a37300c3259", "0000000006d636bc1693351b9806192c", "00000000036b1b5e0b499a8dcc030c96", "0000000001b58daf05a4cd46e601864b",
    "0000000000dac6d782d266a37300c325", "00000000006d636bc1693351b9806192", "000000000036b1b5e0b499a8dcc030c9", "00000000001b58daf05a4cd46e601864",
    "00000000000dac6d782d266a37300c32", "000000000006d636bc1693351b980619", "0000000000036b1b5e0b499a8dcc030c", "000000000001b58daf05a4cd46e60186",
    "000000000000dac6d782d266a37300c3", "0000000000006d636bc1693351b98061", "00000000000036b1b5e0b499a8dcc030", "0000000000001b58daf05a4cd46e6018",
    "0000000000000dac6d782d266a37300c", "00000000000006d636bc1693351b9806", "000000000000036b1b5e0b499a8dcc03", "00000000000001b58daf05a4cd46e601",
    "00000000000000dac6d782d266a37300", "000000000000006d636bc1693351b980", "0000000000000036b1b5e0b499a8dcc0", "000000000000001b58daf05a4cd46e60",
    "000000000000000dac6d782d266a3730", "0000000000000006d636bc1693351b98", "00000000000000036b1b5e0b499a8dcc", "0000000000000001b58daf05a4cd46e6",
    "0000000000000000dac6d782d266a373", "00000000000000006d636bc1693351b9", "000000000000000036b1b5e0b499a8dc", "00000000000000001b58daf05a4cd46e",
    "00000000000000000dac6d782d266a37", "000000000000000006d636bc1693351b", "0000000000000000036b1b5e0b499a8d", "000000000000000001b58daf05a4cd46",
    "000000000000000000dac6d782d266a3", "0000000000000000006d636bc1693351", "00000000000000000036b1b5e0b499a8", "0000000000000000001b58daf05a4cd4",
    "0000000000000000000dac6d782d266a", "00000000000000000006d636bc169335", "000000000000000000036b1b5e0b499a", "00000000000000000001b58daf05a4cd",
    "00000000000000000000dac6d782d266", "000000000000000000006d636bc16933", "0000000000000000000036b1b5e0b499", "000000000000000000001b58daf05a4c",
    "000000000000000000000dac6d782d26", "0000000000000000000006d636bc1693", "00000000000000000000036b1b5e0b49", "0000000000000000000001b58daf05a4",
    "0000000000000000000000dac6d782d2", "00000000000000000000006d636bc169", "000000000000000000000036b1b5e0b4", "00000000000000000000001b58daf05a",
    "00000000000000000000000dac6d782d", "000000000000000000000006d636bc16", "0000000000000000000000036b1b5e0b", "000000000000000000000001b58daf05",
    "000000000000000000000000dac6d782", "0000000000000000000000006d636bc1", "00000000000000000000000036b1b5e0", "0000000000000000000000001b58daf0",
    "0000000000000000000000000dac6d78", "00000000000000000000000006d636bc", "000000000000000000000000036b1b5e", "00000000000000000000000001b58daf",
    "00000000000000000000000000dac6d7", "000000000000000000000000006d636b", "0000000000000000000000000036b1b5", "000000000000000000000000001b58da",
    "000000000000000000000000000dac6d", "0000000000000000000000000006d636", "00000000000000000000000000036b1b", "0000000000000000000000000001b58d",
    "0000000000000000000000000000dac6", "00000000000000000000000000006d63", "000000000000000000000000000036b1", "00000000000000000000000000001b58",
    "00000000000000000000000000000dac", "000000000000000000000000000006d6", "0000000000000000000000000000036b", "000000000000000000000000000001b5",
    "000000000000000000000000000000da", "0000000000000000000000000000006d", "00000000000000000000000000000036", "0000000000000000000000000000001b",
    "0000000000000000000000000000000d", "00000000000000000000000000000006", "00000000000000000000000000000003", "00000000000000000000000000000001",
    "00000000000000000000000000000000", "00000000000000000000000000000000", "00000000000000000000000000000000", "00000000000000000000000000000000",
    "00000000000000000000000000000000", "00000000000000000000000000000000", "00000000000000000000000000000000", "00000000000000000000000000000000",
    "00000000000000000000000000000000", "00000000000000000000000000000000", "00000000000000000000000000000000", "00000000000000000000000000000000",
  ]

  for i in 0 ..< 128:
    let str1 = toHex(e shr i)
    let str2 = strArray[i]
    doAssert str1 == str2

  let strArray2 = [
    "000dac6d782d266a37300c32591eee37", "001b58daf05a4cd46e601864b23ddc6e", "0036b1b5e0b499a8dcc030c9647bb8dc", "006d636bc1693351b9806192c8f771b8",
    "00dac6d782d266a37300c32591eee370", "01b58daf05a4cd46e601864b23ddc6e0", "036b1b5e0b499a8dcc030c9647bb8dc0", "06d636bc1693351b9806192c8f771b80",
    "0dac6d782d266a37300c32591eee3700", "1b58daf05a4cd46e601864b23ddc6e00", "36b1b5e0b499a8dcc030c9647bb8dc00", "6d636bc1693351b9806192c8f771b800",
    "dac6d782d266a37300c32591eee37000", "b58daf05a4cd46e601864b23ddc6e000", "6b1b5e0b499a8dcc030c9647bb8dc000", "d636bc1693351b9806192c8f771b8000",
    "ac6d782d266a37300c32591eee370000", "58daf05a4cd46e601864b23ddc6e0000", "b1b5e0b499a8dcc030c9647bb8dc0000", "636bc1693351b9806192c8f771b80000",
    "c6d782d266a37300c32591eee3700000", "8daf05a4cd46e601864b23ddc6e00000", "1b5e0b499a8dcc030c9647bb8dc00000", "36bc1693351b9806192c8f771b800000",
    "6d782d266a37300c32591eee37000000", "daf05a4cd46e601864b23ddc6e000000", "b5e0b499a8dcc030c9647bb8dc000000", "6bc1693351b9806192c8f771b8000000",
    "d782d266a37300c32591eee370000000", "af05a4cd46e601864b23ddc6e0000000", "5e0b499a8dcc030c9647bb8dc0000000", "bc1693351b9806192c8f771b80000000",
    "782d266a37300c32591eee3700000000", "f05a4cd46e601864b23ddc6e00000000", "e0b499a8dcc030c9647bb8dc00000000", "c1693351b9806192c8f771b800000000",
    "82d266a37300c32591eee37000000000", "05a4cd46e601864b23ddc6e000000000", "0b499a8dcc030c9647bb8dc000000000", "1693351b9806192c8f771b8000000000",
    "2d266a37300c32591eee370000000000", "5a4cd46e601864b23ddc6e0000000000", "b499a8dcc030c9647bb8dc0000000000", "693351b9806192c8f771b80000000000",
    "d266a37300c32591eee3700000000000", "a4cd46e601864b23ddc6e00000000000", "499a8dcc030c9647bb8dc00000000000", "93351b9806192c8f771b800000000000",
    "266a37300c32591eee37000000000000", "4cd46e601864b23ddc6e000000000000", "99a8dcc030c9647bb8dc000000000000", "3351b9806192c8f771b8000000000000",
    "66a37300c32591eee370000000000000", "cd46e601864b23ddc6e0000000000000", "9a8dcc030c9647bb8dc0000000000000", "351b9806192c8f771b80000000000000",
    "6a37300c32591eee3700000000000000", "d46e601864b23ddc6e00000000000000", "a8dcc030c9647bb8dc00000000000000", "51b9806192c8f771b800000000000000",
    "a37300c32591eee37000000000000000", "46e601864b23ddc6e000000000000000", "8dcc030c9647bb8dc000000000000000", "1b9806192c8f771b8000000000000000",
    "37300c32591eee370000000000000000", "6e601864b23ddc6e0000000000000000", "dcc030c9647bb8dc0000000000000000", "b9806192c8f771b80000000000000000",
    "7300c32591eee3700000000000000000", "e601864b23ddc6e00000000000000000", "cc030c9647bb8dc00000000000000000", "9806192c8f771b800000000000000000",
    "300c32591eee37000000000000000000", "601864b23ddc6e000000000000000000", "c030c9647bb8dc000000000000000000", "806192c8f771b8000000000000000000",
    "00c32591eee370000000000000000000", "01864b23ddc6e0000000000000000000", "030c9647bb8dc0000000000000000000", "06192c8f771b80000000000000000000",
    "0c32591eee3700000000000000000000", "1864b23ddc6e00000000000000000000", "30c9647bb8dc00000000000000000000", "6192c8f771b800000000000000000000",
    "c32591eee37000000000000000000000", "864b23ddc6e000000000000000000000", "0c9647bb8dc000000000000000000000", "192c8f771b8000000000000000000000",
    "32591eee370000000000000000000000", "64b23ddc6e0000000000000000000000", "c9647bb8dc0000000000000000000000", "92c8f771b80000000000000000000000",
    "2591eee3700000000000000000000000", "4b23ddc6e00000000000000000000000", "9647bb8dc00000000000000000000000", "2c8f771b800000000000000000000000",
    "591eee37000000000000000000000000", "b23ddc6e000000000000000000000000", "647bb8dc000000000000000000000000", "c8f771b8000000000000000000000000",
    "91eee370000000000000000000000000", "23ddc6e0000000000000000000000000", "47bb8dc0000000000000000000000000", "8f771b80000000000000000000000000",
    "1eee3700000000000000000000000000", "3ddc6e00000000000000000000000000", "7bb8dc00000000000000000000000000", "f771b800000000000000000000000000",
    "eee37000000000000000000000000000", "ddc6e000000000000000000000000000", "bb8dc000000000000000000000000000", "771b8000000000000000000000000000",
    "ee370000000000000000000000000000", "dc6e0000000000000000000000000000", "b8dc0000000000000000000000000000", "71b80000000000000000000000000000",
    "e3700000000000000000000000000000", "c6e00000000000000000000000000000", "8dc00000000000000000000000000000", "1b800000000000000000000000000000",
    "37000000000000000000000000000000", "6e000000000000000000000000000000", "dc000000000000000000000000000000", "b8000000000000000000000000000000",
    "70000000000000000000000000000000", "e0000000000000000000000000000000", "c0000000000000000000000000000000", "80000000000000000000000000000000",
  ]

  for i in 0 ..< 128:
    let str1 = toHex(e shl i)
    let str2 = strArray2[i]
    doAssert str1 == str2
