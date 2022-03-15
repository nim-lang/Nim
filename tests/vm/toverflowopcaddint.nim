discard """
  errormsg: "over- or underflow"
"""
import std/assertions
static:
  proc p =
    var
      x = int64.high
      y = 1
    discard x + y
    doAssert false
  p()
