# disabled: "windows"

#[
xxx merge all or most float tests in just 1 file
]#

import std/[strutils]
block:
  proc test(a: string, b: float) =
    let a2 = a.parseFloat
    doAssert a2 == b, $(a, a2, b)
  test "0.00_0001", 1E-6
  test "0.00__00_01", 1E-6
  test "0.0_01", 0.001
  test "0.00_000_1", 1E-6
  test "0.00000_1", 1E-6
  test "1_0.00_0001", 10.000001
  test "1__00.00_0001", 1_00.000001

block: # bug #18148
  var a = 1.1'f32
  doAssert $a == "1.1", $a # was failing

import std/[fenv, math]

block: # bug #7717
  proc test(f: float) =
    let f2 = $f
    let f3 = parseFloat(f2)
    doAssert f == f3, $(f, f2, f3)

  test 1.0 + epsilon(float64)
  test 1000000.0000000123
  test log2(100000.0)
  test maximumPositiveValue(float32)
  test maximumPositiveValue(float64)
  test minimumPositiveValue(float32)
  test minimumPositiveValue(float64)
