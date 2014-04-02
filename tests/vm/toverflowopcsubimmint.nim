discard """
  errormsg: "over- or underflow"
"""

static:
  proc p =
    var x = int64.low
    discard x - 1
    assert false
  p()
