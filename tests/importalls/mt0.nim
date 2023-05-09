import ./m1 as m
doAssert compiles(foo0)
doAssert not compiles(foo1)
doAssert foo6b() == 2
doAssert m3h2 == 2

var f = initFoo5(z3=3)
doAssert f.z3 == 30
doAssert z3(f) == 30
