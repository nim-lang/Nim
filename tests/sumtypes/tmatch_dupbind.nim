discard """
  errormsg: "duplicate binding: w"
  line: 13
"""

type
  Sh = object
    case
    of C: r: int
    of R: w, h: int
case R(w: 1, h: 2)
of C(r): discard
of R(w, w): echo w
