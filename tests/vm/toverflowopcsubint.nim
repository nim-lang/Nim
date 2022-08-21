discard """
  errormsg: "over- or underflow"
"""

static:
  proc p =
    var
      x = int64.low
      y = 1
    discard x - y
    doAssert false
  p()
