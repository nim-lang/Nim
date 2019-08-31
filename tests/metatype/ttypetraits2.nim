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

proc typeToString*(t: typedesc, prefer = "preferTypeName"): string {.magic: "TypeTrait".}
  ## Returns the name of the given type, with more flexibility than `name`,
  ## and avoiding the potential clash with a variable named `name`.
  ## prefer = "preferResolved" will resolve type aliases recursively.
  # Move to typetraits.nim once api stabilized.

block: # typeToString
  type MyInt = int
  type
    C[T0, T1] = object
  type C2=C # alias => will resolve as C
  type C2b=C # alias => will resolve as C (recursively)
  type C3[U,V] = C[V,U]
  type C4[X] = C[X,X]
  template name2(T): string = typeToString(T, "preferResolved")
  doAssert MyInt.name2 == "int"
  doAssert C3[MyInt, C2b].name2 == "C3[int, C]"
    # C3 doesn't get resolved to C, not an alias (nor does C4)
  doAssert C2b[MyInt, C4[cstring]].name2 == "C[int, C4[cstring]]"
  doAssert C4[MyInt].name2 == "C4[int]"
  when BiggestFloat is float and cint is int:
    doAssert C2b[cint, BiggestFloat].name2 == "C3[int, C3[float, int32]]"

  template name3(T): string = typeToString(T, "preferMixed")
  doAssert MyInt.name3 == "MyInt{int}"
  doAssert (tuple[a: MyInt, b: float]).name3 == "tuple[a: MyInt{int}, b: float]"
  doAssert (tuple[a: C2b[MyInt, C4[cstring]], b: cint, c: float]).name3 ==
    "tuple[a: C2b{C}[MyInt{int}, C4[cstring]], b: cint{int32}, c: float]"
