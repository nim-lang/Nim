discard """
  errormsg: "branches in set pattern must come from the same `of` declaration"
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
of {Circle, Rect}(r): discard
