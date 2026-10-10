import m26405a

type A* = object
proc `=destroy`(x: A) = echo "destroy A"

proc a*() =
  verifyObj[int]()
  verifyDistinct(A)
  verifyStatic[1]()
