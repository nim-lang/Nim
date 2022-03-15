discard """
  errormsg: "over- or underflow"
"""
import std/assertions
static:
  proc p =
    var
      x = int64.low
      y = 1
    discard x - y
    doAssert false
  p()
