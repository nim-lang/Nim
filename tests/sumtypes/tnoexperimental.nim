discard """
  errormsg: "an object `case` without a discriminator requires '--experimental:sumTypes'"
  line: 7
"""

type X = object
  case
  of A: discard
  of B: x: int
