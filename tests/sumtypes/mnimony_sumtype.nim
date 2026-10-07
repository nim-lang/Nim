type
  Node* = ref object
    case
    of AddOpr, SubOpr:
      a*, b*: Node
    of Value:
      val*: int

proc eval*(n: Node): int =
  case n
  of Value(val):
    result = val
  of AddOpr(a, b):
    result = eval(a) + eval(b)
  of SubOpr(a, b):
    result = eval(a) - eval(b)
