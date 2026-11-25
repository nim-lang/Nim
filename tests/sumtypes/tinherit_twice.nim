discard """
  errormsg: "only one empty `case` section is allowed in an object type"
  line: 12
"""

type
  X = object of RootObj
    case
    of A: a: string
    of A2: a2: int
  Y = object of X
    case
    of B: b: int
    of B2: b2: int
