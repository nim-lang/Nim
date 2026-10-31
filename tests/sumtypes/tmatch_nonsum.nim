discard """
  errormsg: "a pattern requires a sum type, but the selector is of type 'int'"
  line: 13
"""

type
  Sh = object
    case
    of C: r: int
    of R: w: int
let i = 3
case i
of C(r): discard
else: discard
