{.push experimental: "allowPrivateImport".}
import ./m1 {.privateImport.} as m2
doAssert compiles(foo1)
doAssert compiles(m2.foo1)
doAssert declared(foo1)
doAssert declared(m2.foo0) # public: works fine

doAssert m2.foo1 == 2
doAssert declared(m2.foo1)
doAssert not declared(m2.nonexistant)
