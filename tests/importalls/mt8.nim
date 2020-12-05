#[
test multiple imports
]#

{.warning[UnusedImport]: off.}
{.push experimental: "enableImportAll".}
import ./m1, m2 {.all.}, ./m3 {.all.}

# m1 is regularly imported
doAssert declared(m1.foo0)
doAssert declared(foo0)
doAssert not declared(m1.foo1)

# m2
doAssert declared(m2.bar2)
doAssert declared(bar2)

# m3
doAssert declared(m3.m3h2)
doAssert declared(m3h2)
