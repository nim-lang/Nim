import std/importutils

type Foo* = object
  a*: int

proc mimportutils_cyclic2_lib(): Foo {.importc.}

proc mimportutils_cyclic1_main*() =
  deferImport "mimportutils_cyclic2"
  let foo = mimportutils_cyclic2_lib()
  doAssert foo.a == 1
