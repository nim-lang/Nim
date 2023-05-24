discard """
  targets: "cpp"
  matrix: "--gc:orc"
"""

import std/options

# bug #18410
type
  O = object of RootObj
   val: pointer

proc p(): Option[O] = none(O)

doAssert $p() == "none(O)"

# bug #17351
type
  Foo = object of RootObj
  Foo2 = object of Foo
  Bar = object
    x: Foo2

var b = Bar()
discard b

# bug #4678
{.emit: """/*TYPESECTION*/
enum class SomeEnum {A,B,C};
""".}
type
  EnumVector[T: enum] {.importcpp: "std::vector", header: "vector".} = object
  SomeEnum {.importcpp, nodecl.} = enum
    A,B,C

proc asVector*[T](t: T): EnumVector[T] =
  discard
# Nim generates this signature here:
# N_NIMCALL(std::vector<> , asvector_106028_3197418230)(SomeEnum t0)

discard asVector(SomeEnum.A)
