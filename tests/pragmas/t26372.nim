discard """
  action: run
"""

# bug #26372: `hasCustomPragma` fails on field inherited from generic object

import std/macros

template marker() {.pragma.}
template val(x: int) {.pragma.}

type
  Base[T] = object of RootObj
    field {.marker.}: T
    v {.val(3).}: int
    plain: int

  Derived = object of Base[int]
  RDerived = ref object of Base[string]
  GDerived[T] = object of Base[T]
    other {.marker.}: int
  BaseInt = Base[int]
  AliasDerived = object of BaseInt
  Deep = object of GDerived[float]

doAssert Derived().field.hasCustomPragma(marker)
doAssert not Derived().plain.hasCustomPragma(marker)
doAssert Derived().v.getCustomPragmaVal(val) == 3
doAssert RDerived().field.hasCustomPragma(marker)
doAssert GDerived[int]().field.hasCustomPragma(marker)
doAssert GDerived[int]().other.hasCustomPragma(marker)
doAssert AliasDerived().field.hasCustomPragma(marker)
doAssert BaseInt().field.hasCustomPragma(marker)
doAssert Deep().field.hasCustomPragma(marker)
doAssert Deep().other.hasCustomPragma(marker)
doAssert Deep().v.getCustomPragmaVal(val) == 3
