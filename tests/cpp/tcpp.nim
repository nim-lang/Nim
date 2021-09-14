discard """
  targets: "cpp"
"""


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

# bug #10219
type
    Vector*[T] {.importcpp: "std::vector", header: "vector".} = object

proc initVector*[T](n: csize_t): Vector[T] 
    {.importcpp: "std::vector<'*0>(@)", header: "vector".}

proc unsafeIndex[T](this: var Vector[T], i: csize_t): var T 
    {.importcpp: "#[#]", header: "vector".}

proc `[]`*[T](this: var Vector[T], i: Natural): var T {.inline, noinit.} =
    when compileOption("boundChecks"):
        # this.checkIndex i
        discard
    result = this.unsafeIndex(cast[csize_t](i))

var v1 = initVector[int](10)
doAssert v1[0] == 0