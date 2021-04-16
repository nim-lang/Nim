import ./m1 {.all.}
  # D20201209T194412:here keep this as is, without `as`, so that mt8.nim test keeps
  # checking that the original module symbol for `m1` isn't modified and that
  # only the alias in `createModuleAlias` is affected.
doAssert declared(m1.foo1)
doAssert foo1 == 2


doAssert m1.foo1 == 2

doAssert not compiles(mt3.foo0) # foo0 is an imported symbol
doAssert not compiles(mt3.foo1) # ditto
