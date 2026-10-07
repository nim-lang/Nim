discard """
  errormsg: "bindings require a single pattern in an `of` branch"
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
let n = Value(val: 1)
case n
of AddOpr(a), SubOpr(b): discard
else: discard
