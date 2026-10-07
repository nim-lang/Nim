discard """
  errormsg: "sum type case objects cannot have an else branch"
  line: 9
"""

type X = object
  case
  of A: discard
  else: x: int
