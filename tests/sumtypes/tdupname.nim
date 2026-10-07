discard """
  errormsg: "duplicate sum type branch name: A"
  line: 9
"""

type X = object
  case
  of A: discard
  of A: x: int
