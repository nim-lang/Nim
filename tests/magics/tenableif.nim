proc test1() =
  # test with constraints on static value, and multi argument constraint
  proc baz(Ta, Tb, Tc: typedesc, d: static string): bool =
    if d[0] == 'f': false
    else:
      Ta is Tb and Tc is float

  proc fun[T1, T2, T3](a: T1, b: T2, c: T3, d: static string): auto
    {.enableif: baz(T1, T2, type(a), d) and T3 is string and type(a) is float.} =
    let ret = (a,b)
    # echo ret
    ret

  template baz2(a: untyped): bool =
    type(a) is string

  proc fun2(a: auto): auto {.enableif: baz2(a).} = (a,)
  proc fun3(a: string): auto {.enableif: false.} = discard
  proc fun3[T](a: ptr T): auto {.enableif: false.} = discard
  proc fun3(a: auto): auto {.enableif: false.} = discard
  proc fun3[T](a: T): auto {.enableif: 3 == 5.} = discard
  proc fun3[T](b: T): auto {.enableif: false.} = discard
  proc fun3(a: char|float|int): auto {.enableif: type(a).sizeof == 3.} = discard
  proc fun3(a: int): auto {.enableif: type(a) is float.} = (a,)
  proc fun3(a: ptr int16): auto {.enableif: false.} = discard
  proc fun3[T](c: T): auto {.enableif: false.} = "asdf"
  proc fun3(a: ptr int8): auto {.enableif: false.} = discard

  proc main()=
    doAssert not compiles(fun2(12.3))
    doAssert fun(1.1, 3.4, "asdf", "goobar") == (1.1, 3.4)
    doAssert fun2("foobar") == ("foobar",)
  main()

proc test2() =
  proc fun3[T](a: T): auto {.enableif: false.} = discard
  proc fun3[T](b: T): auto {.enableif: false.} = discard
  proc fun3(a: auto): auto {.enableif: typeof(a) is string .} = discard
  proc fun3(a: int): auto {.enableif: false.} = discard
  fun3("asdf")

proc test3() =
  proc fun() =
    template gooz(a): untyped =
      type(a) is int
    proc fun3[T](a: T): auto {.enableif: gooz(a).} = a
    doAssert fun3(1) == 1
    doAssert not compiles(fun3("asdf"))
  fun()

proc test4() =
  proc fun3[T](a: T): auto {.enableif: 3 == 3.} = (a,"ok1")
  proc fun() =
    proc fun3[T](a: T): auto {.enableif: false.} = (a,"ok1b")
    proc fun3[T](a: T): auto {.enableif: 1 == 2.} = (a,"ok1b")
    doAssert fun3("asdf") == ("asdf", "ok1")
  fun()

proc test5() =
  proc fun3[T](a: T): string {.enableif: false.}
  proc fun3[T](a: T): string {.enableif: true.}
  proc bar(): auto =
    fun3(12)
  proc fun3[T](a: T): string {.enableif: false.} = $(a,)
  proc fun3[T](a: T): string {.enableif: true.} = $(a,)
  doAssert bar() == "(12,)"

proc test6() =
  # templates are allowed to redefine with the same enableif constraint
  template fun3[T](a: T): int {.enableif: true.} = 41
  template fun3[T](a: T): int {.enableif: true.} = 42
  doAssert fun3("asdf") == 42

proc test7() =
  # different ways to specify `enableif`: from `a`, `T`, via an auxiliary template
  template fun3(a: auto): auto {.enableif: type(a) is int.} = (a,"ok1")
  template fun3[T](a: T): auto {.enableif: T is string.} = (a,"ok2")
  template baz(T): untyped = T is int8
  proc fun3[T](a: T): auto {.enableif: baz(T).} = (a, "ok3")
  doAssert fun3(13) == (13, "ok1")
  doAssert fun3("asdf") == ("asdf", "ok2")
  doAssert fun3(1'i8) == (1'i8, "ok3")
  doAssert not compiles fun3(1'u8)

import std/sugar

proc test8() =
  # test with `compiles`
  proc fun[T](a: T): auto {.enableif: compiles(a(1)).} = a(8)
  proc fun[T](a: T): auto {.enableif: compiles(a("b")).} = a("b")
  doAssert fun((x:int)=>x*2) == 8*2
  doAssert fun((x:string)=>x & "ba") == "bba"


template isEmpty*[T: object|seq|string|set](a: T): bool {.enableif: a.len is int .} =
  ## see https://github.com/nim-lang/Nim/pull/13526#issuecomment-596857722
  a.len == 0

proc testIsEmpty() =
  type Foo = object
    x: int
  type Foo2 = object
    x: int
  proc len(a: Foo2): int = a.x
  doAssert isEmpty(Foo2())
  doAssert not isEmpty(Foo2(x: 1))
  doAssert not compiles(isEmpty(Foo()))

proc testAll()=
  test1()
  test2()
  test3()
  test4()
  test5()
  test6()
  test7()
  test8()

testAll()
