from ./m1 {.all.} as m2 import nil
doAssert not compiles(foo1)
doAssert m2.foo1 == 2
