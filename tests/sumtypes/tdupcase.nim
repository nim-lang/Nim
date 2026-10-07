discard """
  errormsg: "only one empty `case` section is allowed in an object type"
  line: 11
"""

{.experimental: "sumTypes".}
type X = object
  case
  of A: discard
  of B: x: int
  case
  of C: discard
