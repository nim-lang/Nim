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

