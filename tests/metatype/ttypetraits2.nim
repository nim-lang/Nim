# todo: merge with $nimc_D/tests/metatype/ttypetraits.nim (currently disabled)

import typetraits

block: # isNamedTuple
  type Foo1 = (a:1,).type
  type Foo2 = (Field0:1,).type
  type Foo3 = ().type
  type Foo4 = object

  doAssert (a:1,).type.isNamedTuple
  doAssert Foo1.isNamedTuple
  doAssert Foo2.isNamedTuple
  doAssert not Foo3.isNamedTuple
  doAssert not Foo4.isNamedTuple
  doAssert not (1,).type.isNamedTuple
