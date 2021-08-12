import std/private/since

proc fun1(): int {.since: (1, 3).} = 12
proc fun1Bad(): int {.since: (99, 3).} = 12
proc fun2(): int {.since: (1, 3, 1).} = 12
proc fun2Bad(): int {.since: (99, 3, 1).} = 12

doAssert fun1() == 12
doAssert declared(fun1)
doAssert not declared(fun1Bad)

doAssert fun2() == 12
doAssert declared(fun2)
doAssert not declared(fun2Bad)

var ok = false
since (1, 3):
  ok = true
doAssert ok

ok = false
since (1, 3, 1):
  ok = true
doAssert ok

since (99, 3):
  doAssert false

when false:
  # pending bug #15920
  # Error: cannot attach a custom pragma to 'fun3'
  template fun3(): int {.since: (1, 3).} = 12
