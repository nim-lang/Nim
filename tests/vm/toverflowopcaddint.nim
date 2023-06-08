discard """
  errormsg: "int64 overflow"
"""

static:
  proc p =
    var
      x = int64.high
      y = 1
    discard x + y
    doAssert false
  p()
