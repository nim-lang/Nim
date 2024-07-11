discard """
  matrix: "--mm:arc"
"""

type
  E = enum
    a, b, c, d
  X = object
    v: int
  O = object
    case kind: E
    of a:
      a: int
    of {b, c}:
      b: float
    else:
      d: X

proc `=destroy`(x: var X) =
  echo "x destroyed"

var o = O(kind: d, d: X(v: 12345))
doAssert o.d.v == 12345

doAssertRaises(FieldDefect):
  o.kind = a
