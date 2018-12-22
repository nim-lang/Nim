discard """
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

  static :
    # test bitopts at compile time with vm
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

    static:    # check for undefined behavior with rotate by zero.
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

  echo "OK"

main()
