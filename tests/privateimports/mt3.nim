{.push experimental: "allowPrivateImport".}
import ./m1 {.privateImport.}
doAssert foo1 == 2

doAssert m1.foo1 == 2

doAssert not compiles(mt3.foo0) # foo0 is an imported symbol
doAssert not compiles(mt3.foo1) # ditto
