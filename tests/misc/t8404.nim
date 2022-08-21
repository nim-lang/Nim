discard """
  targets: "c cpp js"
"""
template main() =
  block: # bug #8404
    # can conv
    template float2int(T) =
      var a = -1.0
      let b = T(a)
      doAssert b < 0
      let c = b + 1
      doAssert c is T
      doAssert c == 0

    float2int(int8)
    float2int(int16)
    float2int(int32)
    float2int(int64)

  block:
    # can handle middle conv
    # `/` can trigger int to float
    template float2int(T) =
      let n = T(1 / 256)
      doAssert n == 0

    float2int(int8)
    float2int(int16)
    float2int(int32)
    # float2int(int64)
main()
static:
  main()
