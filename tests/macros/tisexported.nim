import macros

proc t1* = discard
proc t2 = discard

macro check(p1: typed, p2: typed) =
  doAssert isExported(p1) == true
  doAssert isExported(p2) == false

check t1, t2
