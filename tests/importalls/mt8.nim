#[
test multiple imports
]#

{.warning[UnusedImport]: off.}
import ./m1, m2 {.all.}, ./m3 {.all.}
  # make sure this keeps using `import ./m1` without as.

# m1 is regularly imported
doAssert declared(m1.foo0)
doAssert declared(foo0)

doAssert not declared(m1.foo1)
  # if we didn't call `createModuleAlias` even for `import f1 {.all.}`,
  # this would fail, see D20201209T194412.

# m2
doAssert declared(m2.bar2)
doAssert declared(bar2)

# m3
doAssert declared(m3.m3h2)
doAssert declared(m3h2)
