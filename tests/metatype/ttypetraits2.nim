discard """
"""

# NOTE: ttypetraits.nim is disabled, so using typetraits2.nim
import typetraits

block sameType:
  doAssert int == int

  type Foo = int | float
  doAssert Foo == Foo
  doAssert: Foo != int
  doAssert: int != Foo

  type myInt = distinct int
  doAssert myInt == myInt
  doAssert: int != myInt

  type Foo2 = float | int
  when false:
    # TODO: this fails
    doAssert Foo2 == Foo

  type A=object of RootObj
    b1:int

  type B=object of A
    b2:int
  doAssert: A != B
  doAssert: B != A
  doAssert B == B
