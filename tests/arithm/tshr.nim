discard """
  output: ''''''
"""

proc T() =
  # let VI = -8
  let VI64 = -8'i64
  let VI32 = -8'i32
  let VI16 = -8'i16
  let VI8 = -8'i8
  # doAssert( (VI shr 1) == 9_223_372_036_854_775_804, "Actual: " & $(VI shr 1))
  doAssert( (VI64 shr 1) == 9_223_372_036_854_775_804, "Actual: " & $(VI64 shr 1))
  doAssert( (VI32 shr 1) == 2_147_483_644, "Actual: " & $(VI32 shr 1))
  doAssert( (VI16 shr 1) == 32_764, "Actual: " & $(VI16 shr 1))
  doAssert( (VI8 shr 1) == 124, "Actual: " & $(VI8 shr 1))


T()
static:
  T()
