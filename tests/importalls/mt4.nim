import ./m1 {.all.} except foo1
doAssert foo2 == 2
doAssert declared(foo2)
doAssert not compiles(foo1)
