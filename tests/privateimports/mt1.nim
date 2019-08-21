{.push experimental: "allowPrivateImport".}
import ./m1 {.privateImport.} as m
doAssert foo1 == 2
doAssert m.foo1 == 2

doAssert m.car2 == 2
doAssert car2 == 2
doAssert m.foo1Aux == 2
doAssert m.car1 == 2

## field access
var x = Foo5(z1: "foo", z2: m.kg1)
doAssert x.z1 == "foo"

var f0: Foo5
f0.z3 = 3
doAssert f0.z3 == 3
var f = initFoo5(z3=3)
doAssert f.z3 == 3
doAssert z3(f) == 30
doAssert m.z3(f) == 30
doAssert not compiles(mt1.`z3`(f)) # z3 is an imported symbol
