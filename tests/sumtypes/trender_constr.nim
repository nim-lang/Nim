discard """
  errormsg: "expression 'C().r' is of type 'int' and has to be used (or discarded)"
  line: 15
"""

# a sum type constructor renders like the source, without the hidden discriminator
type
  Sh = object
    x: int
    case
    of C: r: int
    of R: w, h: int

case C()
of C(r): r
of R(w): w
