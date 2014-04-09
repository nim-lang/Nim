discard """
  errormsg: "over- or underflow"
"""

static:
  proc p =
    var
      x = 1 shl 62
    discard x * 2
    assert false
  p()
