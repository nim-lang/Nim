discard """
  errormsg: "branch initialization with a runtime discriminator only supports ordinal types with 2^16 elements or less."
  line: 13
"""
type
  HoledObj = object
    case kind: int
    of 0: a: int
    else: discard

let someInt = low(int)
case someInt
of 938: echo HoledObj(kind: someInt, a: 1)
else: discard
