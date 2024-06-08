discard """
  targets: "c cpp js"
"""

proc main() =
  block: # bug #16806
    let
      a = 42u16
      b = cast[int16](a)
    doAssert a.int16 == 42
    doAssert b in int16.low..int16.high

  block: # bug #16808
    doAssert cast[int8](cast[uint8](int8(-12))) == int8(-12)
    doAssert cast[int16](cast[uint16](int16(-12))) == int16(-12)
    doAssert cast[int32](cast[uint32](int32(-12))) == int32(-12)

  doAssert cast[int8](int16.high) == -1

static: main()
main()
