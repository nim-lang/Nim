discard """
  errormsg: "case statement cannot work on enums with holes for computed goto"
  line: 13
"""

type
  X = enum
    A = 0, B = 100

var z = A
while true:
  {.computedGoto.}
  case z
  of A: discard
  of B: discard
