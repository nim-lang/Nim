import ./m1 {.all.} as m2 except foo1
doAssert foo2 == 2
doAssert not compiles(foo1)
doAssert m2.foo1 == 2
doAssert compiles(m2.foo1)

from system {.all.} as s import ThisIsSystem
doAssert ThisIsSystem
doAssert s.ThisIsSystem
