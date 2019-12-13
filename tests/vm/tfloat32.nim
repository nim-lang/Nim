proc main(): string =
  let x0 = float32(1.32)
  let x1: float32 = 1.32
  let x3 = 1.32'f32
  let x4 = 1.32
  let x2 = x1
  let x5 = x3*x3 # will differ here
  let x6 = 1.32'f64
  let x7: float = 1.32
  $(x0, x1, x2, x3, x4, x5, x6, x7, x3*x3,
    x3 * 2.0,  # will differ here
     $type(x4), $type(x5))

const a1 = main()
let a2 = main()

#[
CT (a1) and RT (a2) values differ when float operations are involved (eg x3*x3),
but otherwise are the same
]#
doAssert a1 == """
(1.320000052452087, 1.320000052452087, 1.320000052452087, 1.320000052452087, 1.32, 1.742400138473513, 1.32, 1.32, 1.742400138473513, 2.640000104904175, "float64", "float32")"""

doAssert a2 == """
(1.320000052452087, 1.320000052452087, 1.320000052452087, 1.320000052452087, 1.32, 1.742400169372559, 1.32, 1.32, 1.742400169372559, 2.640000104904175, "float64", "float32")"""
