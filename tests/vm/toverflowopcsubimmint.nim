discard """
  errormsg: "over- or underflow"
"""
import std/assertions
static:
  proc p =
    var x = int64.low
    discard x - 1
    doAssert false
  p()
