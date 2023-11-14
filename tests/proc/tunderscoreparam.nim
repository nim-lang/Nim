discard """
  targets: "c cpp js"
"""

import std/[assertions, sequtils]

proc test() =
  block:
    proc ok(_, _, a: int): int =
      doAssert not compiles(_)
      a
    doassert ok(4, 2, 5) == 5

  block:
    proc ok(_: int, _: int, a: int): int = a
    doAssert ok(4, 2, 5) == 5

  block:
    proc ok(_: int, _: float, a: int): int = a
    doAssert ok(1, 2.0, 5) == 5

  block:
    proc ok(_: int, _: float, _: string, a: int): int = a
    doAssert ok(1, 2.6, "5", 5) == 5
    
  block:
    proc ok[T](_, _, a: T): T =
      doAssert not compiles(_)
      a
    doAssert ok(4, 2, 5) == 5
    doAssert ok("a", "b", "c") == "c"
    doAssert not compiles(ok(1, 2, "a"))
  
  block:
    let ok = proc (_, _, a: int): int =
      doAssert not compiles(_)
      a
    doAssert ok(4, 2, 5) == 5
  
  block:
    proc foo(lam: proc (_, _, a: int): int): int =
      lam(4, 2, 5)
    doAssert foo(proc (_, _, a: auto): auto =
      doAssert not compiles(_)
      a) == 5
    
  block:
    iterator fn(_, _: int, c: int): int = yield c
    doAssert toSeq(fn(1,2,3)) == @[3]

  block:
    template ok(_, _, a: int): int = a
    doAssert ok(4, 2, 5) == 5

  block:
    doAssert not (compiles do:
      template bad(_: int): int = _
      discard bad(3))

  block:
    template ok(_: int, _: int, a: int): int = a
    doAssert ok(4, 2, 5) == 5

  block:
    template ok(_: int, _: float, a: int): int = a
    doAssert ok(1, 2.0, 5) == 5

  block:
    template ok(_: int, _: float, _: string, a: int): int = a
    doAssert ok(1, 2.6, "5", 5) == 5
  
  block:
    template main2() =
      iterator fn(_, _: int, c: int): int = yield c
    main2()

  block:
    template main =
      proc foo(_: int) =
        let a = _
    doAssert not compiles(main())
  
  block: # generic params
    doAssert not (compiles do:
      proc foo[_](t: typedesc[_]): seq[_] = @[default(_)]
      doAssert foo[int]() == 0)
  
  block:
    proc foo[_, _](): int = 123
    doAssert foo[int, bool]() == 123
  
  block:
    proc foo[T; U](_: typedesc[T]; _: typedesc[U]): (T, U) = (default(T), default(U))
    doAssert foo(int, bool) == (0, false)

proc closureTest() =
  var x = 0

  block:
    proc foo(_, _: int) = x += 5

    foo(1, 2)
    doAssert x == 5

  block:
    proc foo(_: int, _: float) = x += 5

    foo(1, 2)
    doAssert x == 10

  block:
    proc foo(_: int, _: float, _: string) = x += 5

    foo(1, 2, "5")
    doAssert x == 15

static: test()
test()

when not defined(js):
  static: closureTest()
closureTest()
