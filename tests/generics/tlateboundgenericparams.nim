discard """
  output: "1\n10\n1\n10"
  nimout: '''
bar instantiated with 1
bar instantiated with 10
'''
"""

import typetraits

type
  Foo = object

proc defaultFoo: Foo = discard
proc defaultInt: int = 1
proc defaultTInt(T: type): int = 2
proc defaultTFoo[T](x: typedesc[T]): Foo = discard
proc defaultTOldSchool[T](x: typedesc[T]): T = discard
proc defaultTModern(T: type): T = discard

proc specializedDefault(T: type int): int = 10
proc specializedDefault(T: type string): string = "default"

converter intFromFoo(x: Foo): int = 3

proc consumeInt(x: int) =
  discard

const activeTests = {1..100}

when true:
  template test(n, body) =
    when n in activeTests:
      block:
        body

  template reject(x) =
    static: assert(not compiles(x))

  test 1:
    proc t[T](val: T = defaultInt()) =
      consumeInt val

    t[int]()
    reject t[string]()

  test 2:
    proc t1[T](val: T = defaultFoo()) =
      static:
        assert type(val).name == "int"
        assert T.name == "int"

      consumeInt val

    # here, the converter should kick in, but notice
    # how `val` is still typed `int` inside the proc.
    t1[int]()

    proc t2[T](val: T = defaultFoo()) =
      discard

    reject t2[string]()

  test 3:
    proc tInt[T](val = defaultInt()): string =
      return type(val).name

    doAssert tInt[int]() == "int"
    doAssert tInt[string]() == "int"

    proc tInt2[T](val = defaultTInt(T)): string =
      return type(val).name

    doAssert tInt2[int]() == "int"
    doAssert tInt2[string]() == "int"

    proc tDefTModern[T](val = defaultTModern(T)): string =
      return type(val).name

    doAssert tDefTModern[int]() == "int"
    doAssert tDefTModern[string]() == "string"
    doAssert tDefTModern[Foo]() == "Foo"

    proc tDefTOld[T](val = defaultTOldSchool(T)): string =
      return type(val).name

    doAssert tDefTOld[int]() == "int"
    doAssert tDefTOld[string]() == "string"
    doAssert tDefTOld[Foo]() == "Foo"

  test 4:
    proc t[T](val: T = defaultTFoo(T)): string =
      return type(val).name

    doAssert t[int]() == "int"
    doAssert t[Foo]() == "Foo"
    reject t[string]()

  test 5:
    proc t1[T](a: T = specializedDefault(T)): T =
      return a

    doAssert t1[int]() == 10
    doAssert t1[string]() == "default"

    proc t2[T](a: T, b = specializedDefault(T)): auto =
      return $a & $b

    doAssert t2(5) == "510"
    doAssert t2("string ") == "string default"

    proc t3[T](a: T, b = specializedDefault(type(a))): auto =
      return $a & $b

    doAssert t3(100) == "10010"
    doAssert t3("another ") == "another default"

  test 6:
    # https://github.com/nim-lang/Nim/issues/5595
    type
      Point[T] = object
        x, y: T

    proc getOrigin[T](): Point[T] = Point[T](x: 0, y: 0)

    proc rotate[T](point: Point[T], radians: float,
                   origin = getOrigin[T]()): Point[T] =
      discard

    var p = getOrigin[float]()
    var rotated = p.rotate(2.1)

  test 7:
    proc bar(x: static[int]) =
      static: echo "bar instantiated with ", x
      echo x

    proc foo(x: static[int] = 1) =
      bar(x)

    foo()
    foo(10)
    foo(1)
    foo(10)

