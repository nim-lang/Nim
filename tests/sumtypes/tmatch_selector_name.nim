discard """
  errormsg: "expression 'Sh(`kind: C, r: zeroDefault([type node])).r' is of type 'int' and has to be used (or discarded)"
  line: 15
"""

# the selector of a pattern match renders as itself, not as a temporary
type
  Sh = object
    x: int
    case
    of C: r: int
    of R: w, h: int

case C()
of C(r): r
of R(w): w
