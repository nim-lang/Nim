discard """
  output: '''
int32
int32
1280
1280
3
1
2
2
3
4294967295
2
0
tUnsignedOps OK
'''
nimout: "tUnsignedOps OK"
"""

import typetraits


block tand:
  # bug #5216
  echo(name typeof((0x0A'i8 and 0x7F'i32) shl 7'i32))

  let i8 = 0x0A'i8
  echo(name typeof((i8 and 0x7F'i32) shl 7'i32))

  echo((0x0A'i8 and 0x7F'i32) shl 7'i32)

  let ii8 = 0x0A'i8
  echo((ii8 and 0x7F'i32) shl 7'i32)



block tcast:
  template crossCheck(ty: untyped, exp: untyped) =
    let rt = ty(exp)
    const ct = ty(exp)
    if $rt != $ct:
      echo astToStr(exp)
      echo "Got ", ct
      echo "Expected ", rt

  template add1(x: uint8): untyped = x + 1
  template add1(x: uint16): untyped = x + 1
  template add1(x: uint32): untyped = x + 1

  template sub1(x: uint8): untyped = x - 1
  template sub1(x: uint16): untyped = x - 1
  template sub1(x: uint32): untyped = x - 1

  crossCheck(int8, 0'i16 - 5'i16)
  crossCheck(int16, 0'i32 - 5'i32)
  crossCheck(int32, 0'i64 - 5'i64)

  crossCheck(uint8, 0'u8 - 5'u8)
  crossCheck(uint16, 0'u16 - 5'u16)
  crossCheck(uint32, 0'u32 - 5'u32)
  crossCheck(uint64, 0'u64 - 5'u64)

  crossCheck(uint8, uint8.high + 5'u8)
  crossCheck(uint16, uint16.high + 5'u16)
  crossCheck(uint32, uint32.high + 5'u32)
  crossCheck(uint64, 0xFFFFFFFFFFFFFFFF'u64 + 5'u64)
  crossCheck(uint64, uint64.high + 5'u64)

  doAssert $sub1(0'u8) == "255"
  doAssert $sub1(0'u16) == "65535"
  doAssert $sub1(0'u32) == "4294967295"

  doAssert $add1(255'u8) == "0"
  doAssert $add1(65535'u16) == "0"
  doAssert $add1(4294967295'u32) == "0"

  crossCheck(int32, high(int32))
  crossCheck(int32, high(int32).int32)
  crossCheck(int32, low(int32))
  crossCheck(int32, low(int32).int32)
  crossCheck(int64, high(int8).int16.int32.int64)
  crossCheck(int64, low(int8).int16.int32.int64)

  doAssert not compiles(echo int64(0xFFFFFFFFFFFFFFFF'u64))
  doAssert not compiles(echo int32(0xFFFFFFFFFFFFFFFF'u64))
  doAssert not compiles(echo int16(0xFFFFFFFFFFFFFFFF'u64))
  doAssert not compiles(echo  int8(0xFFFFFFFFFFFFFFFF'u64))

block tnot:
  # Signed types
  block:
    const t0: int8  = not 4
    const t1: int16 = not 4
    const t2: int32 = not 4
    const t3: int64 = not 4
    const t4: int8  = not -5
    const t5: int16 = not -5
    const t6: int32 = not -5
    const t7: int64 = not -5
    doAssert t0 == -5
    doAssert t1 == -5
    doAssert t2 == -5
    doAssert t3 == -5
    doAssert t4 == 4
    doAssert t5 == 4
    doAssert t6 == 4
    doAssert t7 == 4

  # Unsigned types
  block:
    const t0: uint8  = not 4'u8
    const t1: uint16 = not 4'u16
    const t2: uint32 = not 4'u32
    const t3: uint64 = not 4'u64
    const t4: uint8  = not 251'u8
    const t5: uint16 = not 65531'u16
    const t6: uint32 = not 4294967291'u32
    const t7: uint64 = not 18446744073709551611'u64
    doAssert t0 == 251
    doAssert t1 == 65531
    doAssert t2 == 4294967291'u32
    doAssert t3 == 18446744073709551611'u64
    doAssert t4 == 4
    doAssert t5 == 4
    doAssert t6 == 4
    doAssert t7 == 4


block tshr:
  proc T() =
    # let VI = -8
    let VI64 = -8'i64
    let VI32 = -8'i32
    let VI16 = -8'i16
    let VI8 = -8'i8
    # doAssert( (VI shr 1) == 9_223_372_036_854_775_804, "Actual: " & $(VI shr 1))
    doAssert( (VI64 shr 1) == -4, "Actual: " & $(VI64 shr 1))
    doAssert( (VI32 shr 1) == -4, "Actual: " & $(VI32 shr 1))
    doAssert( (VI16 shr 1) == -4, "Actual: " & $(VI16 shr 1))
    doAssert( (VI8 shr 1) == -4, "Actual: " & $(VI8 shr 1))

  T()
  static:
    T()



block tsubrange:
  # bug #5854
  type
    n16 = range[0'i16..high(int16)]

  var level: n16 = 1
  let maxLevel: n16 = 1

  level = min(level + 2, maxLevel).n16
  doAssert level == 1

block tissue12177:
  var a: uint16 = 1
  var b: uint32 = 2

  echo(b + a)
  echo(b - a)
  echo(b * a)
  echo(b div a)

  echo(a + b)
  echo(a - b)
  echo(a * b)
  echo(a div b)

block tUnsignedOps:
  proc testUnsignedOps() =
    let a: int8 = -128
    let b: int8 = 127

    doAssert b +% 1 == -128
    doAssert b -% -1 == -128
    doAssert b *% 2 == -2
    doAssert a /% 4 == 32
    doAssert a %% 7 == 2
    echo "tUnsignedOps OK"

  testUnsignedOps()
  static:
    testUnsignedOps()
