discard """
  output: '''
foo1
foo2
'''
"""

block:
  type
    FooObj[T] = object
      v: T
    Foo1[T] = FooObj[T]
    Foo2 = FooObj

  proc foo1(x: Foo1) = echo "foo1"
  proc foo2(x: Foo2) = echo "foo2"

  var x: FooObj[float]
  foo1(x)  # works
  foo2(x)  # works

block:
  type
    FooObj[T] = T
    Foo1[T] = FooObj[T]
    Foo2 = FooObj
    Foo3 = Foo1
    Foo4x = FooObj[SomeInteger]
    Foo4 = FooObj[SomeFloat]
    Foo5x = Foo1[SomeInteger]
    Foo5 = Foo1[SomeFloat]

  proc foo0(x: FooObj): int = 0
  proc foo1(x: Foo1): int = 1
  proc foo2(x: Foo2): int = 2
  proc foo3(x: Foo3): int = 3
  proc foo4(x: Foo4x): int = 40
  proc foo4(x: Foo4): int = 4
  proc foo5(x: Foo5x): int = 50
  proc foo5(x: Foo5): int = 5

  block:
    var x: FooObj[float]
    doAssert(foo0(x) == 0)
    doAssert(foo1(x) == 1)
    doAssert(foo2(x) == 2)
    doAssert(foo3(x) == 3)
    doAssert(foo4(x) == 4)
    doAssert(foo5(x) == 5)

  block:
    var x: Foo1[float]
    doAssert(foo0(x) == 0)
    doAssert(foo1(x) == 1)
    doAssert(foo2(x) == 2)
    doAssert(foo3(x) == 3)
    doAssert(foo4(x) == 4)
    doAssert(foo5(x) == 5)

  block:
    var x: Foo2[float]
    doAssert(foo0(x) == 0)
    doAssert(foo1(x) == 1)
    doAssert(foo2(x) == 2)
    doAssert(foo3(x) == 3)
    doAssert(foo4(x) == 4)
    doAssert(foo5(x) == 5)

block:
  type
    FooObj[T,U] = object
      x: T
      y: U
    Foo1[U,T] = FooObj[T,U]
    Foo2 = FooObj
    Foo3 = Foo1
    Foo4x = FooObj[SomeInteger,SomeInteger]
    Foo4y = FooObj[SomeInteger,SomeFloat]
    Foo4z = FooObj[SomeFloat,SomeFloat]
    Foo4 = FooObj[SomeFloat,SomeInteger]
    Foo5x = Foo1[SomeInteger,SomeInteger]
    Foo5y = Foo1[SomeFloat,SomeInteger]
    Foo5z = Foo1[SomeFloat,SomeFloat]
    Foo5 = Foo1[SomeInteger,SomeFloat]

  proc foo0(x: FooObj): int = 0
  proc foo1(x: Foo1): int = 1
  proc foo2(x: Foo2): int = 2
  proc foo3(x: Foo3): int = 3
  proc foo4(x: Foo4x): int = 40
  proc foo4(x: Foo4y): int = 41
  proc foo4(x: Foo4z): int = 42
  proc foo4(x: Foo4): int = 4
  proc foo5(x: Foo5x): int = 50
  proc foo5(x: Foo5y): int = 51
  proc foo5(x: Foo5z): int = 52
  proc foo5(x: Foo5): int = 5

  block:
    var x: FooObj[float,int]
    doAssert(foo0(x) == 0)
    doAssert(foo1(x) == 1)
    doAssert(foo2(x) == 2)
    doAssert(foo3(x) == 3)
    doAssert(foo4(x) == 4)
    doAssert(foo5(x) == 5)

  block:
    var x: Foo1[int,float]
    doAssert(foo0(x) == 0)
    doAssert(foo1(x) == 1)
    doAssert(foo2(x) == 2)
    doAssert(foo3(x) == 3)
    doAssert(foo4(x) == 4)
    doAssert(foo5(x) == 5)

block:
  type
    FooObj[T] = object of RootObj
      v: T
    FooObj2[T] = object of FooObj[T]
    Foo1[T] = FooObj[T]
    Foo2 = FooObj
    Foo3 = Foo1
    Foo4x = FooObj[SomeInteger]
    Foo4 = FooObj[SomeFloat]
    Foo5x = Foo1[SomeInteger]
    Foo5 = Foo1[SomeFloat]

  proc foo0(x: FooObj): int = 0
  proc foo1(x: Foo1): int = 1
  proc foo2(x: Foo2): int = 2
  proc foo3(x: Foo3): int = 3
  proc foo4(x: Foo4x): int = 40
  proc foo4(x: Foo4): int = 4
  proc foo5(x: Foo5x): int = 50
  proc foo5(x: Foo5): int = 5

  block:
    var x: FooObj[float]
    doAssert(foo0(x) == 0)
    doAssert(foo1(x) == 1)
    doAssert(foo2(x) == 2)
    doAssert(foo3(x) == 3)
    doAssert(foo4(x) == 4)
    doAssert(foo5(x) == 5)

  block:
    var x: Foo1[float]
    doAssert(foo0(x) == 0)
    doAssert(foo1(x) == 1)
    doAssert(foo2(x) == 2)
    doAssert(foo3(x) == 3)
    doAssert(foo4(x) == 4)
    doAssert(foo5(x) == 5)

  #[ XXX These still fail
  block:
    var x: FooObj2[float]
    doAssert(foo0(x) == 0)
    doAssert(foo1(x) == 1)
    doAssert(foo2(x) == 2)
    doAssert(foo3(x) == 3)
    doAssert(foo4(x) == 4)
    doAssert(foo5(x) == 5)
  ]#
