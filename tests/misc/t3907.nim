discard """
  disabled: "32bit"
"""

import std/assertions

let a = 0'i64
let b = if false: -1 else: a
doAssert b == 0

let c: range[0'i64..high(int64)] = 0'i64
let d = if false: -1 else: c

doAssert d == 0
