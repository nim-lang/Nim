discard """
  errormsg: "int64 underflow"
"""

static:
  proc p =
    var x = int64.low
    discard x - 1
    doAssert false
  p()
