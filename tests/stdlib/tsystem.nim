discard """
  targets: "c cpp js"
"""

# TODO: in future work move existing `system` tests here, where they belong

import stdtest/testutils

template main =
  block: # closure
    proc outer() =
      var a = 0
      proc inner1 = a.inc
      proc inner2 = discard
      doAssert inner1 is "closure"
      doAssert inner2 isnot "closure"
      doAssert inner1 is (proc)
      doAssert inner2 is (proc)
      let inner1b = inner1
      doAssert inner1b is "closure"
      doAssert inner1b == inner1
    outer()

  block: # rawProc, rawProc, bug #17911
    proc outer() =
      var a = 0
      var b = 0
      proc inner1() = a.inc
      proc inner2() = a += 2
      proc inner3() = b.inc
      let inner1b = inner1
      doAssert inner2 != inner1
      doAssert inner3 != inner1
      whenVMorJs: discard
      do:
        doAssert rawProc(inner1b) == rawProc(inner1)
        doAssert rawProc(inner2) != rawProc(inner1)
        doAssert rawProc(inner3) != rawProc(inner1)

        doAssert rawEnv(inner1b) == rawEnv(inner1)
        doAssert rawEnv(inner2) == rawEnv(inner1) # because both use `a`
        # doAssert rawEnv(inner3) != rawEnv(inner1) # because `a` vs `b` # this doesn't hold
    outer()

static: main()
main()
