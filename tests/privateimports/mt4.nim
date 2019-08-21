{.push experimental: "allowPrivateImport".}
import ./m1 {.privateImport.} except foo1
doAssert foo2 == 2
doAssert declared(foo2)
doAssert not compiles(foo1)
