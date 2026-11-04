discard """
  targets: "c cpp"
  matrix: "; -d:danger"
"""

# The compile time range check must not depend on the host's float to integer
# conversion: `1e100.int64` is undefined behaviour, x86 produces `low(int64)`
# whereas arm64 saturates to `high(int64)`, so the compiler used to accept or
# reject these conversions depending on the machine it ran on.

import std/[assertions, math]

static:
  doAssert not compiles(int64(1e100))
  doAssert not compiles(uint64(1e100))
  doAssert not compiles(int64(9223372036854775808.0)) # 2^63, one past high(int64)
  doAssert not compiles(uint64(18446744073709551616.0)) # 2^64

# fits `uint64` but not `int64`:
doAssert uint64(1e19) == 10000000000000000000'u64
doAssert int64(-9223372036854775808.0) == low(int64)
doAssert int8(-128.9) == -128'i8

block: # bug #20102
  # a float to signed integer conversion is range checked, also for values
  # that do not fit an int64, NaN and infinities: converting those is
  # undefined behaviour in C
  proc opaque[T](x: T): T {.noinline.} = x

  template raises(body: untyped): bool =
    var r = false
    try:
      discard body
    except RangeDefect:
      r = true
    r

  const checked = compileOption("rangeChecks")

  # in range, truncated towards zero:
  doAssert int8(opaque(127.9)) == 127
  doAssert int8(opaque(-128.9)) == -128
  doAssert int8(opaque(-0.5)) == 0
  doAssert int16(opaque(-32768.0)) == -32768
  doAssert int32(opaque(2147483647.5)) == 2147483647
  doAssert int32(opaque(-2147483648.75)) == -2147483648'i32
  doAssert int(opaque(1e18)) == 1_000_000_000_000_000_000
  doAssert int64(opaque(-9223372036854775808.0)) == low(int64)
  doAssert int64(opaque(9223372036854774784.0)) == 9223372036854774784 # largest float below 2^63
  doAssert int8(opaque(100'f32)) == 100
  doAssert int64(opaque(-1e18'f32)) == -999999984306749440

  type A = range[0..10]
  doAssert A(opaque(10.5)) == 10

  # out of range:
  let values = [300.0, -129.0, 128.0, 1e19, -1e19, 9223372036854775808.0,
                -9223372036854777856.0, NaN, Inf, -Inf]
  for x in values:
    doAssert raises(int8(opaque(x))) == checked, $x
  for x in values[3..^1]:
    doAssert raises(int(opaque(x))) == checked, $x
    doAssert raises(int64(opaque(x))) == checked, $x
    doAssert raises(int32(opaque(float32(x)))) == checked, $x
  doAssert raises(int32(opaque(2147483648.0))) == checked
  doAssert raises(int32(opaque(-2147483649.0))) == checked
  doAssert raises(A(opaque(11.0))) == checked
  doAssert raises(A(opaque(-1.0))) == checked

  when checked:
    try:
      discard int8(opaque(300.0))
      doAssert false
    except RangeDefect as e:
      doAssert e.msg == "value out of range: 300.0 notin -128.0 .. 127.0", e.msg
