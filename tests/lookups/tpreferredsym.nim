import mpreferredsym

block: # issue #11184
  type MyType = object

  proc foo0(arg: MyType): string = "foo0"
  proc foo1(arg: MyType): string = "foo1"
  proc foo2(arg: MyType): string = "foo2"

  proc test() =
    var bar: MyType

    doAssert myTemplate0() == "foo0"
    doAssert myTemplate1() == "foo1"
    doAssert myTemplate2() == "foo2"

  test()

block: 
  proc overloadToPrefer(x: string): string = x & "def"
  doAssert singleOverload() == (124, "abcdef")
