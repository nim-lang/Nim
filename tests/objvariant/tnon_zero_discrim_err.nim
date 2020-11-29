discard """
  errormsg: "low(kind) must be 0 for discriminant"
  line: 7
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
