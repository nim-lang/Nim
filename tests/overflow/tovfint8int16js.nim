discard """
  description: "Test overflow checks for int8 and int16 on JS backend"
  matrix: "--backend:js"
  outputsub: "Error: unhandled exception"
"""

# Test int8 overflow detection
{.push overflowChecks: on.}

block test_int8_add_overflow:
  let i8 = int8.high  # 127
  var caught = false
  try:
    discard i8 + 1
  except OverflowDefect:
    caught = true
  doAssert caught, "int8 addition overflow not caught"

block test_int8_sub_underflow:
  let i8 = int8.low  # -128
  var caught = false
  try:
    discard i8 - 1
  except OverflowDefect:
    caught = true
  doAssert caught, "int8 subtraction underflow not caught"

block test_int8_mul_overflow:
  let i8 = int8.high  # 127
  var caught = false
  try:
    discard i8 * 2
  except OverflowDefect:
    caught = true
  doAssert caught, "int8 multiplication overflow not caught"

block test_int16_add_overflow:
  let i16 = int16.high  # 32767
  var caught = false
  try:
    discard i16 + 1
  except OverflowDefect:
    caught = true
  doAssert caught, "int16 addition overflow not caught"

block test_int16_sub_underflow:
  let i16 = int16.low  # -32768
  var caught = false
  try:
    discard i16 - 1
  except OverflowDefect:
    caught = true
  doAssert caught, "int16 subtraction underflow not caught"

block test_int16_mul_overflow:
  let i16 = int16.high  # 32767
  var caught = false
  try:
    discard i16 * 2
  except OverflowDefect:
    caught = true
  doAssert caught, "int16 multiplication overflow not caught"

# Test that non-overflowing operations work correctly
block test_int8_normal:
  let a = int8(10)
  let b = int8(20)
  doAssert a + b == 30
  doAssert b - a == 10
  doAssert a * 2 == 20

block test_int16_normal:
  let a = int16(1000)
  let b = int16(2000)
  doAssert a + b == 3000
  doAssert b - a == 1000
  doAssert a * 2 == 2000

{.pop.}

echo "All overflow tests passed"
