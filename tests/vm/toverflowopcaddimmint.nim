discard """
  errormsg: "int64 overflow"
"""

static:
  proc p =
    var
      x = int64.high
    discard x + 1
    doAssert false
  p()
