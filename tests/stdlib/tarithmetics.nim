discard """
  targets: "c cpp js"
"""

# TODO: in future work move existing arithmetic tests (tests/arithm/*) into this file
# FYI https://github.com/nim-lang/Nim/pull/17767

template main =
  # put all arithmetic tests

  block tshr:
    block: # Signed types
      let
        a1 = -3
        a2 = -2
        b1 = -4'i8
        b2 = 1'i8
        c1 = -5'i16
        c2 = 1'i16
        d1 = -7i32
        d2 = 1'i32
        e1 = -9'i64
        e2 = 1'i64
      doAssert a1 shr a2 == -1
      doAssert b1 shr b2 == -2
      doAssert c1 shr c2 == -3
      doAssert d1 shr d2 == -4
      doAssert e1 shr e2 == -5

    block: # Unsigned types
      let
        a1 = 3'u
        a2 = 2'u
        b1 = 2'u8
        b2 = 1'u8
        c1 = 5'u16
        c2 = 1'u16
        d1 = 6'u32
        d2 = 1'u32
        e1 = 8'u64
        e2 = 1'u64
      doAssert a1 shr a2 == 0
      doAssert b1 shr b2 == 1
      doAssert c1 shr c2 == 2
      doAssert d1 shr d2 == 3
      doAssert e1 shr e2 == 4

static: main()
main()
