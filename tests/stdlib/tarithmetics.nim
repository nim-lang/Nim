discard """
  targets: "c cpp js"
"""

# TODO: in future work move existing arithmetic tests here, where they belong: Nim/tests/arithm
# FYI https://github.com/nim-lang/Nim/pull/17767

template main =
  # put all arithmetic tests

  block tshr:

    # Signed types
    block:
      let
        t0: int = -3 shr 2
        t1: int8 = -4'i8 shr 1'i8
        t2: int16 = -5'i16 shr 1'i16
        t3: int32 = -7'i32 shr 1'i32
        t4: int64 = -9'i64 shr 1'i64

      doAssert t0 == -1
      doAssert t1 == -2
      doAssert t2 == -3
      doAssert t3 == -4
      doAssert t4 == -5

    # Unsigned types
    block:
      let        
        t5: uint = 3'u shr 2'u
        t6: uint8 = 2'u8 shr 1'u8
        t7: uint16 = 5'u16 shr 1'u16
        t8: uint32 = 6'u32 shr 1'u32
        t9: uint64 = 8'u64 shr 1'u64
      
      doAssert t5 == 0
      doAssert t6 == 1
      doAssert t7 == 2
      doAssert t8 == 3
      doAssert t9 == 4

static: main()
main()
