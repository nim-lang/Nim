type Box* = ref object
  n*: int

var box*: Box

proc setBox*(n: int) =
  box = Box(n: n)
