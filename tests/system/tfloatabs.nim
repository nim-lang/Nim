discard """
  targets: "c cpp js"
"""

proc magnitude(value: float64): float64 {.noinline.} = abs(value)
proc magnitude(value: float32): float32 {.noinline.} = abs(value)

doAssert magnitude(-3.5) == 3.5
doAssert magnitude(-3.5'f32) == 3.5'f32
doAssert magnitude(-Inf) == Inf
doAssert magnitude(float32(-Inf)) == float32(Inf)
doAssert magnitude(0.0) == 0.0
doAssert magnitude(-0.0) == 0.0
let nan = magnitude(NaN)
doAssert nan != nan
when not defined(js):
  doAssert cast[uint64](magnitude(-0.0)) == 0'u64
  doAssert cast[uint32](magnitude(-0.0'f32)) == 0'u32
