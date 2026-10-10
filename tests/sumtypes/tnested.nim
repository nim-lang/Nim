discard """
  errormsg: "a sum type `case` cannot be nested in another `case`"
  line: 9
"""

type X = object
  case k: bool
  of true:
    case
    of C: discard
  of false: discard
