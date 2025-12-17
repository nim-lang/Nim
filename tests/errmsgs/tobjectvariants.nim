discard """
  errormsg: "selector must be of an ordinal type"
"""

type
  Case = object
    case x: float
    of 1.0:
      id: int
    else:
      ta: float

var s = Case(x: 4.0, id: 1)