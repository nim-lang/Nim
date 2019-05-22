discard """
  errormsg: "branch initialization with a runtime discriminator only supports ordinal types."
  line: 14
"""
type
  Holed = enum A = 0, B = 2
  HoledObj = object
    case kind: Holed
    of A: a: int
    else: discard

let holed = B
case holed
of A: echo HoledObj(kind: holed, a: 1)
else: discard
