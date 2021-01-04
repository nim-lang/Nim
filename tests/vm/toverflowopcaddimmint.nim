discard """
  errormsg: "over- or underflow"
"""

static:
  proc p =
    var
      x = int64.high
    discard x + 1
    doAssert false
  p()
