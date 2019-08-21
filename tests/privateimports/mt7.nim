include ./m1
doAssert compiles(foo1)
doAssert compiles(mt7.foo1)
doAssert declared(foo1)
doAssert declared(mt7.foo1)
doAssert declared(mt7.foo0)

var f0: Foo5
f0.z3 = 3
doAssert f0.z3 == 3
var f = initFoo5(z3=3)
doAssert f.z3 == 3
doAssert mt7.z3(f) == 30
doAssert z3(f) == 30
