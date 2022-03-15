discard """
  errormsg: "over- or underflow"
"""
import std/assertions
static:
  proc p =
    var
      x = 1'i64 shl 62
    discard x * 2
    doAssert false
  p()
