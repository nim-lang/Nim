discard """
output: "ok"
"""

proc main(): void =
  let a: float32 = 47.11'f32
  doAssert a == 47.11'f32

  let b: float64 = 10.234402823e+38'f64
  doAssert b != 10.123402823e+38'f64
  doAssert b == 10.234402823e+38'f64

  echo "ok"

main()
