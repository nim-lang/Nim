discard """
  errormsg: "cannot bind the fields of a nested `case` or the fields after it"
  line: 21
"""

type
  V = object
    case
    of A:
      a: int
      case k: bool
      of true: t: string
      of false: f: float
      after: int
    of B: discard
let x = A(a: 1, k: true, t: "yes", after: 9)
case x
of A(a, k): echo a, " ", k
of B: discard
case x
of A(a, k, t): echo a, " ", k
of B: discard
