{.push experimental: "allowPrivateImport".}
import ./m1 {.privateImport.} as m2 except foo1
doAssert foo2 == 2
doAssert not compiles(foo1)
doAssert m2.foo1 == 2
doAssert compiles(m2.foo1)

from system {.privateImport.} as s import ThisIsSystem
doAssert ThisIsSystem
doAssert s.ThisIsSystem
