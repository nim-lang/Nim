
# rename as titerators_1?

template main() =
  block: # bug #16353
    var c = 0
    for i in high(int32) .. high(int32):
      c.inc
      doAssert c<=1
    doAssert c == 1

static: main()
main()
