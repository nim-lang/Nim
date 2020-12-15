
# rename as titerators_1?

template main() =
  template fn(T) = 
    block: # bug #16353
      var c = 0
      for i in high(T) .. high(T):
        c.inc
        doAssert c<=1
      doAssert c == 1

  fn(int8)
  fn(int16)
  fn(int32)
  fn(int64)
  fn(uint8)
  fn(uint16)
  fn(uint32)
  fn(uint64)

static: main()
main()
