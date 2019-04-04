discard """
  nimout: "OK"
  output: "OK"
"""
import bitops

proc main() =
  const U8 = 0b0011_0010'u8
  const I8 = 0b0011_0010'i8
  const U16 = 0b00100111_00101000'u16
  const I16 = 0b00100111_00101000'i16
  const U32 = 0b11010101_10011100_11011010_01010000'u32
  const I32 = 0b11010101_10011100_11011010_01010000'i32
  const U64A = 0b01000100_00111111_01111100_10001010_10011001_01001000_01111010_00010001'u64
  const I64A = 0b01000100_00111111_01111100_10001010_10011001_01001000_01111010_00010001'i64
  const U64B = 0b00110010_11011101_10001111_00101000_00000000_00000000_00000000_00000000'u64
  const I64B = 0b00110010_11011101_10001111_00101000_00000000_00000000_00000000_00000000'i64

  doAssert( U64A.fastLog2 == 62)
  doAssert( I64A.fastLog2 == 62)
  doAssert( U64A.countLeadingZeroBits == 1)
  doAssert( I64A.countLeadingZeroBits == 1)
  doAssert( U64A.countTrailingZeroBits == 0)
  doAssert( I64A.countTrailingZeroBits == 0)
  doAssert( U64A.firstSetBit == 1)
  doAssert( I64A.firstSetBit == 1)
  doAssert( U64A.parityBits == 1)
  doAssert( I64A.parityBits == 1)
  doAssert( U64A.countSetBits == 29)
  doAssert( I64A.countSetBits == 29)
  doAssert( U64A.rotateLeftBits(37) == 0b00101001_00001111_01000010_00101000_10000111_11101111_10010001_01010011'u64)
  doAssert( U64A.rotateRightBits(37) == 0b01010100_11001010_01000011_11010000_10001010_00100001_11111011_11100100'u64)

  doAssert( U64B.firstSetBit == 36)
  doAssert( I64B.firstSetBit == 36)

  doAssert( U32.fastLog2 == 31)
  doAssert( I32.fastLog2 == 31)
  doAssert( U32.countLeadingZeroBits == 0)
  doAssert( I32.countLeadingZeroBits == 0)
  doAssert( U32.countTrailingZeroBits == 4)
  doAssert( I32.countTrailingZeroBits == 4)
  doAssert( U32.firstSetBit == 5)
  doAssert( I32.firstSetBit == 5)
  doAssert( U32.parityBits == 0)
  doAssert( I32.parityBits == 0)
  doAssert( U32.countSetBits == 16)
  doAssert( I32.countSetBits == 16)
  doAssert( U32.rotateLeftBits(21) == 0b01001010_00011010_10110011_10011011'u32)
  doAssert( U32.rotateRightBits(21) == 0b11100110_11010010_10000110_10101100'u32)

  doAssert( U16.fastLog2 == 13)
  doAssert( I16.fastLog2 == 13)
  doAssert( U16.countLeadingZeroBits == 2)
  doAssert( I16.countLeadingZeroBits == 2)
  doAssert( U16.countTrailingZeroBits == 3)
  doAssert( I16.countTrailingZeroBits == 3)
  doAssert( U16.firstSetBit == 4)
  doAssert( I16.firstSetBit == 4)
  doAssert( U16.parityBits == 0)
  doAssert( I16.parityBits == 0)
  doAssert( U16.countSetBits == 6)
  doAssert( I16.countSetBits == 6)
  doAssert( U16.rotateLeftBits(12) == 0b10000010_01110010'u16)
  doAssert( U16.rotateRightBits(12) == 0b01110010_10000010'u16)

  doAssert( U8.fastLog2 == 5)
  doAssert( I8.fastLog2 == 5)
  doAssert( U8.countLeadingZeroBits == 2)
  doAssert( I8.countLeadingZeroBits == 2)
  doAssert( U8.countTrailingZeroBits == 1)
  doAssert( I8.countTrailingZeroBits == 1)
  doAssert( U8.firstSetBit == 2)
  doAssert( I8.firstSetBit == 2)
  doAssert( U8.parityBits == 1)
  doAssert( I8.parityBits == 1)
  doAssert( U8.countSetBits == 3)
  doAssert( I8.countSetBits == 3)
  doAssert( U8.rotateLeftBits(3) == 0b10010001'u8)
  doAssert( U8.rotateRightBits(3) == 0b0100_0110'u8)

  template test_undefined_impl(ffunc: untyped; expected: int; is_static: bool) =
    doAssert( ffunc(0'u8) == expected)
    doAssert( ffunc(0'i8) == expected)
    doAssert( ffunc(0'u16) == expected)
    doAssert( ffunc(0'i16) == expected)
    doAssert( ffunc(0'u32) == expected)
    doAssert( ffunc(0'i32) == expected)
    doAssert( ffunc(0'u64) == expected)
    doAssert( ffunc(0'i64) == expected)

  template test_undefined(ffunc: untyped; expected: int) =
    test_undefined_impl(ffunc, expected, false)
    static:
      test_undefined_impl(ffunc, expected, true)

  when defined(noUndefinedBitOpts):
    # check for undefined behavior with zero.
    test_undefined(countSetBits, 0)
    test_undefined(parityBits, 0)
    test_undefined(firstSetBit, 0)
    test_undefined(countLeadingZeroBits, 0)
    test_undefined(countTrailingZeroBits, 0)
    test_undefined(fastLog2, -1)

    # check for undefined behavior with rotate by zero.
    doAssert( U8.rotateLeftBits(0) == U8)
    doAssert( U8.rotateRightBits(0) == U8)
    doAssert( U16.rotateLeftBits(0) == U16)
    doAssert( U16.rotateRightBits(0) == U16)
    doAssert( U32.rotateLeftBits(0) == U32)
    doAssert( U32.rotateRightBits(0) == U32)
    doAssert( U64A.rotateLeftBits(0) == U64A)
    doAssert( U64A.rotateRightBits(0) == U64A)

    # check for undefined behavior with rotate by integer width.
    doAssert( U8.rotateLeftBits(8) == U8)
    doAssert( U8.rotateRightBits(8) == U8)
    doAssert( U16.rotateLeftBits(16) == U16)
    doAssert( U16.rotateRightBits(16) == U16)
    doAssert( U32.rotateLeftBits(32) == U32)
    doAssert( U32.rotateRightBits(32) == U32)
    doAssert( U64A.rotateLeftBits(64) == U64A)
    doAssert( U64A.rotateRightBits(64) == U64A)

  block:
    # mask operations
    var v: uint8
    v.setMask(0b1100_0000)
    v.setMask(0b0000_1100)
    doAssert(v == 0b1100_1100)
    v.flipMask(0b0101_0101)
    doAssert(v == 0b1001_1001)
    v.clearMask(0b1000_1000)
    doAssert(v == 0b0001_0001)
    v.clearMask(0b0001_0001)
    doAssert(v == 0b0000_0000)
  block:
    # single bit operations
    var v: uint8
    v.setBit(0)
    doAssert v == 0x0000_0001
    v.setBit(1)
    doAssert v == 0b0000_0011
    v.flipBit(7)
    doAssert v == 0b1000_0011
    v.clearBit(0)
    doAssert v == 0b1000_0010
    v.flipBit(1)
    doAssert v == 0b1000_0000
    doAssert v.testbit(7)
    doAssert not v.testbit(6)
  block:
    # multi bit operations
    var v: uint8
    v.setBits(0, 1, 7)
    doAssert v == 0b1000_0011
    v.flipBits(2, 3)
    doAssert v == 0b1000_1111
    v.clearBits(7, 0, 1)
    doAssert v == 0b0000_1100
  block:
    # signed
    var v: int8
    v.setBit(7)
    doAssert v == -128
  block:
    var v: uint64
    v.setBit(63)
    doAssert v == 0b1000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000'u64

  block:
    proc testReverseBitsInvo(x: SomeUnsignedInt) =
      doAssert(reverseBits(reverseBits(x)) == x)
      
    proc testReverseBitsPerType(x, reversed: uint64) =
      doAssert reverseBits(x) == reversed
      doAssert reverseBits(uint32(x)) == uint32(reversed shr 32)
      doAssert reverseBits(uint32(x shr 16)) == uint32(reversed shr 16)
      doAssert reverseBits(uint16(x)) == uint16(reversed shr 48)
      doAssert reverseBits(uint8(x)) == uint8(reversed shr 56)

      testReverseBitsInvo(x)
      testReverseBitsInvo(uint32(x))
      testReverseBitsInvo(uint16(x))
      testReverseBitsInvo(uint8(x))

    proc testReverseBitsRefl(x, reversed: uint64) =
      testReverseBitsPerType(x, reversed)
      testReverseBitsPerType(reversed, x)

    proc testReverseBitsShift(d, b: uint64) =
      var
        x = d
        y = b

      for i in 1..64:
        testReverseBitsRefl(x, y)
        x = x shl 1
        y = y shr 1

    proc testReverseBits(d, b: uint64) =
      testReverseBitsShift(d, b)

    testReverseBits(0x0u64, 0x0u64)
    testReverseBits(0xffffffffffffffffu64, 0xffffffffffffffffu64)
    testReverseBits(0x0123456789abcdefu64, 0xf7b3d591e6a2c480u64)
    testReverseBits(0x5555555555555555u64, 0xaaaaaaaaaaaaaaaau64)
    testReverseBits(0x5555555500000001u64, 0x80000000aaaaaaaau64)
    testReverseBits(0x55555555aaaaaaaau64, 0x55555555aaaaaaaau64)
    testReverseBits(0xf0f0f0f00f0f0f0fu64, 0xf0f0f0f00f0f0f0fu64)
    testReverseBits(0x181881810ff00916u64, 0x68900ff081811818u64)

  echo "OK"

block: # not ready for vm because exception is compile error
  try:
    var v: uint32
    var i = 32
    v.setBit(i)
    doAssert false
  except RangeError:
    discard
  except:
    doAssert false


main()
static:
  # test everything on vm as well
  main()
