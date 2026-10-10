discard """
  errormsg: "undeclared sum type branch: Square"
  line: 19
"""

type
  Node = ref object
    case
    of AddOpr, SubOpr:
      a, b: Node
    of Value:
      val: int
  Shape = object
    case
    of Circle: radius: float
    of Rect: w, h: float
let s = Circle()
case s
of Square(a): discard
else: discard
