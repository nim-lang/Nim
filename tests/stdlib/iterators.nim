template main() =
  template itetest(A, B) =
    block:
      var c = 0
      for i in A .. B:
        c.inc
      doAssert type(A)(c) == max(B - A + 1, 0)

  template typeitetest(T) =
    itetest(high(T) - 1, high(T))

   # bug #16353
  typeitetest(int8)
  typeitetest(int16)
  typeitetest(int32)
  typeitetest(int64)
  typeitetest(uint8)
  typeitetest(uint16)
  typeitetest(uint32)
  typeitetest(uint64)

  itetest(50, 40)
  itetest(high(int64), 40)
  itetest(0, 20)
  itetest(0.uint8, 20.uint8)
  itetest(high(int16), high(int16).int32)
  itetest(high(int16).int32, high(int16))

static: main()
main()
