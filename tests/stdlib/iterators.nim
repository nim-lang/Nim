template main() =
  template iterTest(A, B) =
    block:
      var c = 0
      for i in A .. B:
        c.inc
      doAssert type(A)(c) == max(B - A + 1, 0)

  template typeIterTest(T) =
    iterTest(high(T) - 1, high(T))

   # bug #16353
  typeIterTest(int8)
  typeIterTest(int16)
  typeIterTest(int32)
  typeIterTest(int64)
  typeIterTest(uint8)
  typeIterTest(uint16)
  typeIterTest(uint32)
  typeIterTest(uint64)

  iterTest(50, 40)
  iterTest(high(int64), 40)
  iterTest(0, 20)
  iterTest(0.uint8, 20.uint8)
  iterTest(high(int16), high(int16).int32)
  iterTest(high(int16).int32, high(int16))

static: main()
main()
