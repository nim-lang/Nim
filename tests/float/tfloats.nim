discard """
  targets: "c cpp js"
"""
# disabled: "windows"

#[
xxx merge all or most float tests into this file
]#

import std/[fenv, math, strutils]

proc equalsOrNaNs(a, b: float): bool =
  if isNaN(a): isNaN(b)
  elif a == 0:
    b == 0 and signbit(a) == signbit(b)
  else:
    a == b

template reject(a) =
  doAssertRaises(ValueError): discard parseFloat(a)

template main =
  block:
    proc test(a: string, b: float) =
      let a2 = a.parseFloat
      doAssert equalsOrNaNs(a2, b), $(a, a2, b)
    test "0.00_0001", 1E-6
    test "0.00__00_01", 1E-6
    test "0.0_01", 0.001
    test "0.00_000_1", 1E-6
    test "0.00000_1", 1E-6
    test "1_0.00_0001", 10.000001
    test "1__00.00_0001", 1_00.000001
    test "inf", Inf
    test "-inf", -Inf
    test "-Inf", -Inf
    test "-INF", -Inf
    test "NaN", NaN
    test "-nan", NaN
    test ".1", 0.1
    test "-.1", -0.1
    test "-0", -0.0
    when false: # pending bug #18246
      test "-0", -0.0
    test ".1e-1", 0.1e-1
    test "0_1_2_3.0_1_2_3E+0_1_2", 123.0123e12
    test "0_1_2.e-0", 12e0
    test "0_1_2e-0", 12e0
    test "-0e0", -0.0
    test "-0e-0", -0.0

  reject "a"
  reject ""
  reject "e1"
  reject "infa"
  reject "infe1"
  reject "_"
  reject "1e"

  when false: # gray area; these numbers should probably be invalid
    reject "1_"
    reject "1_.0"
    reject "1.0_"

  block: # bug #18148
    var a = 1.1'f32
    doAssert $a == "1.1", $a # was failing

proc runtimeOnlyTests =
  # enable for 'static' once -d:nimFpRoundtrips became the default
  block: # bug #7717
    proc test(f: float) =
      let f2 = $f
      let f3 = parseFloat(f2)
      doAssert equalsOrNaNs(f, f3), $(f, f2, f3)

    test 1.0 + epsilon(float64)
    test 1000000.0000000123
    test log2(100000.0)
    test maximumPositiveValue(float32)
    test maximumPositiveValue(float64)
    test minimumPositiveValue(float32)
    test minimumPositiveValue(float64)

static: main()
main()

runtimeOnlyTests()
