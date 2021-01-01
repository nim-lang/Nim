discard """
  targets: "c js"
"""

# TODO merge this to tmath.nim once tmath.nim supports js target

import math

proc main() =
  block:
    doAssert 1.0 / abs(-0.0) == Inf
    doAssert 1.0 / abs(0.0) == Inf
    doAssert -1.0 / abs(-0.0) == -Inf
    doAssert -1.0 / abs(0.0) == -Inf
    doAssert abs(0.0) == 0.0
    doAssert abs(0.0'f32) == 0.0'f32

    doAssert abs(Inf) == Inf
    doAssert abs(-Inf) == Inf
    doAssert abs(NaN).isNaN
    doAssert abs(-NaN).isNaN

static: main()
main()
