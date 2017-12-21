type
  Comparable = concept a
    (a < a) is bool

proc myMax(a, b: Comparable): Comparable =
  if a < b:
    return b
  else:
    return a

doAssert myMax(5, 10) == 10
doAssert myMax(31.3, 1.23124) == 31.3

# issue 6464
type T = concept x
  x.q

proc p(x, y: T): T = x
proc q(x: int) = discard
let x = p(5, 7)

