discard """
  errormsg: "not all cases are covered; missing: {AddOpr, SubOpr}"
  line: 18
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
let n = Value(val: 1)
case n
of Value(v): echo v
