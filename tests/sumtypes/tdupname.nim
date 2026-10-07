discard """
  errormsg: "duplicate sum type branch name: A"
  line: 10
"""

{.experimental: "sumTypes".}
type X = object
  case
  of A: discard
  of A: x: int
