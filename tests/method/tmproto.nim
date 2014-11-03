type
  Obj1 = ref object {.inheritable.}
  Obj2 = ref object of Obj1

method beta(x: Obj1): int

proc delta(x: Obj2): int =
  beta(x)

method beta(x: Obj2): int

proc alpha(x: Obj1): int =
  beta(x)

method beta(x: Obj1): int = 1
method beta(x: Obj2): int = 2

proc gamma(x: Obj1): int =
  beta(x)

doAssert alpha(Obj1()) == 1
doAssert gamma(Obj1()) == 1
doAssert alpha(Obj2()) == 2
doAssert gamma(Obj2()) == 2
doAssert delta(Obj2()) == 2
