discard """
  targets: "c cpp js"
"""

# TODO: in future work move existing `system` tests here, where they belong

template main =
  block:
    proc outer() =
      var a = 0
      proc inner() = a.inc
      doAssert inner is "closure"
      let inner2 = inner
      doAssert inner2 is "closure"
      doAssert inner2 == inner
      doAssert rawProc(inner) == rawProc(inner2)

static: main()
main()
