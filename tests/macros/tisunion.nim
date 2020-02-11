import macros

type
  MyType1 = object
    a,b: int

  MyType2 {.union.} = object
    a: int
    b: float

  Alias1 = MyType1
  Alias2 = MyType2

  GenericNonUnion[T] = object
    a: int
    b: T

  GenericUnion[T] {.union.} = object
    a: int
    b: T

  Alias3 = GenericNonUnion[float]
  Alias4 = GenericUnion[float]

doAssert isUnion(MyType1) == false
doAssert isUnion(MyType2) == true
doAssert isUnion(Alias1) == false
doAssert isUnion(Alias2) == true
doAssert isUnion(GenericNonUnion[float]) == false
doAssert isUnion(GenericUnion[float]) == true
doAssert isUnion(Alias3) == false
doAssert isUnion(Alias4) == true

macro foobar(arg: typed; expectation: static bool) =
  doAssert isUnion(arg) == expectation

proc main() =
  var
    tmp0: MyType1
    tmp1: MyType2
    tmp2: Alias1
    tmp3: Alias2
    tmp4: GenericNonUnion[float]
    tmp5: GenericUnion[float]
    tmp6: Alias3
    tmp7: Alias4

  foobar(tmp0, false)
  foobar(tmp1, true)
  foobar(tmp2, false)
  foobar(tmp3, true)
  foobar(tmp4, false)
  foobar(tmp5, true)
  foobar(tmp6, false)
  foobar(tmp7, true)

main()
