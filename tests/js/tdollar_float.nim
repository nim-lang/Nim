#[
merge into tests/system/tdollars.nim once https://github.com/nim-lang/Nim/pull/14122
is merged
]#

import unittest

block: # https://github.com/timotheecour/Nim/issues/133
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

  var a: float = 2
  doAssert $a == "2.0"
