discard """
  errormsg: "too many bindings for sum type branch"
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
of Circle(a, b): discard
else: discard
