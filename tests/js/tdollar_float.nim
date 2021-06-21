#[
merge into tests/system/tdollars.nim once https://github.com/nim-lang/Nim/pull/14122
is merged
]#

import unittest

block: # https://github.com/timotheecour/Nim/issues/133
  # simple test
  var a: float = 2
  check $a == "2.0"

  # systematic tests
  template fun(a2: static float) =
    const a: float = a2 # needed pending https://github.com/timotheecour/Nim/issues/132
    var b = a
    check $b == $a

  fun 2
  fun 2.0
  fun 2.1
  fun 1_000
  fun 1_000.1
  fun 1_000_000_000.1
  fun 1_000_000_000_000.1

  # negatives
  fun -2.0
  fun -2.1

  # 0
  fun 0
  fun -0
  fun 0.0

  block:
    var a = -0.0
    check $a in ["-0.0", "0.0"]

  # exponents
  block:
    var a = 5e20
    check $a in ["5e20", "500000000000000000000.0"]

  fun 3.4e1'f32
  fun 3.4e-1'f32
  fun -3.4e-1'f32
  fun 3.4e-1'f32
  fun 3e-1'f32

  block:
    var a = 3.4e38'f32
    check $a in ["3.4e+38", "3.4e+038"]
      # on windows, printf (used in VM) prints as 3.4e+038
      # but js prints as 3.4e+38
      # on osx, both print as 3.4e+38
      # see https://github.com/timotheecour/Nim/issues/138

  when false: # edge cases
    fun -0.0 # see https://github.com/timotheecour/Nim/issues/136
    fun 5e20
    fun 3.4e38'f32
