discard """
  targets: "c cpp"
"""

type FooBase = ref object of RootObj
  dummy: int
type Foo = ref object of FooBase
  value : float32
type Foo2 = ref object of Foo
  change : float32
method bar(x: FooBase, a: float32) {.base.} =
  discard
method bar(x: Foo, a: float32)  =
  x.value += a
method bar(x: Foo2, a: float32)  =
  x.value += a


proc test() =
  var x = new Foo2
  x.bar(2.3)
  doAssert x.value <= 2.3

test()
# methods of a non-ref object; the dispatcher crashed the compiler for C++
type
  ValueBase = object of RootObj
  ValueDerived = object of ValueBase

method name(x: ValueBase): string {.base.} = "base"
method name(x: ValueDerived): string = "derived"

doAssert name(ValueBase()) == "base"
doAssert name(ValueDerived()) == "derived"
