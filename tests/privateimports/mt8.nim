#[
test multiple imports
]#

{.push experimental: "allowPrivateImport".}
import ./m1, m2 {.privateImport.}, ./m3 {.privateImport.}

# m1 is regularly imported
doAssert declared(m1.foo0)
doAssert declared(foo0)
doAssert not declared(m1.foo1)

# m2
doAssert declared(m2.bar2)
doAssert declared(bar2)

# m3
doAssert declared(m3.car2)
doAssert declared(car2)
