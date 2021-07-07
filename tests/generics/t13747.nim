discard """
  joinable: false
  matrix: "-d:t13747_case1; -d:t13747_case2; -d:t13747_case3; -d:t13747_case4; -d:t13747_case5; -d:t13747_case6; -d:t13747_case7; -d:t13747_case8; -d:t13747_case9; -d:t13747_case10; -d:t13747_case11; -d:t13747_case12; -d:t13747_case13"
  # this allows testing each one individually; each of those (except t13747_case1, t13747_case7, t13747_case8) were failing
"""

# bug #13747 generic sandwich non-module scope symbols were ignored

# keep these at module scope
when defined(t13747_case1):
  # every symbol suffixed by V1, represents -d:case2a1 from https://github.com/nim-lang/Nim/issues/13747#issuecomment-615992993
  proc byValImpl1V1(T: typedesc, valV1: int): auto =
    T.valV1

  template byVal1V1(E: typedesc): untyped =
    byValImpl1V1(E, E.valV1)

  proc byVal2V1(T: typedesc): auto =
    mixin valV1
    T.valV1

  template funV1() =
    template valV1(t: type): untyped = 11
    doAssert int.byVal1V1() == 11
    doAssert int.byVal2V1() == 11

  funV1() # was ok

when defined(t13747_case2):
  # every symbol suffixed by V2, represents -d:case2a2 from https://github.com/nim-lang/Nim/issues/13747#issuecomment-615992993
  proc byValImpl1V2(T: typedesc, valV2: int): auto =
    T.valV2

  template byVal1V2(E: typedesc): untyped =
    byValImpl1V2(E, E.valV2)

  proc byVal2V2(T: typedesc): auto =
    mixin valV2
    T.valV2

  template funV2() =
    template valV2(t: type): untyped = 12
    doAssert int.byVal1V2() == 12 # ok(workaround)
    doAssert int.byVal2V2() == 12 # was giving CT error

  block: funV2() # was BUG

when defined(t13747_case3):
  # every symbol suffixed by V3, represents -d:case2a2 -d:case2a3 from https://github.com/nim-lang/Nim/issues/13747#issuecomment-615992993
  proc byValImpl1V3(T: typedesc, valV3: int): auto =
    T.valV3

  template byVal1V3(E: typedesc): untyped =
    byValImpl1V3(E, E.valV3)

  proc byVal2V3(T: typedesc): auto =
    mixin valV3
    T.valV3

  template valV3(a: int8) = discard
  proc byVal3V3(T: typedesc): auto =
    mixin valV3
    T.valV3

  template funV3() =
    template valV3(t: type): untyped = 13
    doAssert int.byVal1V3() == 13 # ok(workaround)
    doAssert int.byVal2V3() == 13 # was giving CT error

  block: funV3() # was BUG

when defined(t13747_case4):
  type
    Bar1 = distinct int
    Bar2 = distinct int
    Bar3 = distinct int
    Bar4 = distinct int
    Bar5 = distinct int

  proc fn[T](a: T): int =
    mixin bar
    bar(a)

  proc bar(a: Bar1): int = 11
  doAssert fn(1.Bar1) == 11

  block:
    proc bar(a: Bar2): int = 12
    doAssert fn(1.Bar2) == 12 # was failing because bar at block scope was not visible

  proc outer =
    proc bar(a: Bar3): int = 13
    doAssert fn(1.Bar3) == 13 # ditto
  outer()

  proc outer2[T](x: T) =
    proc bar(a: Bar4): int = 14
    doAssert fn(1.Bar4) == 14 # ditto
  outer2(1.0)
  outer2("u")

  template outer3 =
    proc bar(a: Bar5): int = 15
    doAssert fn(1.Bar5) == 15
  outer3()

when defined(t13747_case5):
  # examples from https://github.com/nim-lang/Nim/issues/13747#issue-587437527
  import m13747
  block:
    proc `$`(a: Foo): string = "custom1"
    doAssert $(Foo(), Foo()) == "(custom1, custom1)" # was: (default, default)
    doAssert $Foo() == "custom1"

  proc `$`(a: Foo): string = "custom2"
  # echo (Foo(), Foo()) # xxx prints (custom1, custom1) but should print (custom2, custom2), because of generic caching, this is a separate issue
  doAssert $Foo() == "custom2"

when defined(t13747_case6): # bug #17965
  block:
    type User = ref object
      id: int
    proc `==`(a, b: User): bool = a[] == b[]
    var a = User(id: 1)
    var b = User(id: 1)
    doAssert a == b # was ok
    doAssert @[a] == @[b] # was failing

when defined(t13747_case7):
  # D20210519T201000:here makes sure this keeps working
  proc cmp(a: string) = discard
  template genericTests() =
    let fn = cmp[int]
  genericTests()

when defined t13747_case8: # bug #2752
  # D20210519T200936:here makes sure this keeps working; this is a minimized version of bug #2752;
  # the non-minimized is in tests/generics/tgenerics_issues.nim (formerly tests/generics/tdont_use_inner_scope.nim)
  proc myFilter[T](a: T) =
    proc aNameWhichWillConflict(z: int) = discard
    let foo = aNameWhichWillConflict # semstmts.nim:500:12 in: semVarOrLet def.kind: nkClosedSymChoice;
  block:
    proc aNameWhichWillConflict(x: string) = discard
    myFilter(1)

# tests that need an stdlib import come after

when defined t13747_case9: # bug #13970
  # (also reported in https://github.com/nim-lang/Nim/issues/13747#issuecomment-612905795)
  import algorithm
  block:
    var a = @[(1, @['a']), (4, @['d']), (3, @['c']), (2, @['b'])]
    proc `<`(x, y: (int, seq[char])): bool = x[0] < y[0]
    sort(a) # was CT error

when defined t13747_case10:
  # example with a pragma: make sure `off` is resolved here
  proc fn1[T](a: T) =
    {.warning[resultshadowed]: off.}: discard
  fn1(1)

when defined t13747_case11:
  # BUG D20210621T173756:here: this test was failing with `Error: type mismatch`
  proc fn2[T](a: T) =
    {.warning[resultshadowed]: off.}:
      discard
  const off = "asdf"
  fn2(1)

when defined t13747_case12:
  # more pragmas
  proc fn3[T](a: T) =
    mixin off2
    mixin resultshadowed2
    {.define(t13747_case12_sub).}
    {.noSideEffect.}: discard
    {.noSideEffect2.}: discard
    {.warning[resultshadowed]: off2.}: discard
    {.push warning[resultshadowed]: off2.}
    {.push, warning[resultshadowed]: off.}
    {.pop.}
    {.push warnings: off.}
    {.push warning[GcMem]: off, warning[Uninit]: off.}
  block:
    doAssert not compiles(fn3(1))
    const off2 = off
    {.pragma: noSideEffect2, noSideEffect.}
    doAssert compiles(fn3(1))
    fn3(1)

when defined t13747_case13:
  proc foo[T](a: T = low(T)) = discard
  proc bar[A](a: A) =
    foo[A]()
  foo[int]()
  bar(1.0)

  proc foo2[T](a = low(T)) = discard
  proc bar2[A](a: A) =
    foo2[A]()
  bar2(2)
  foo2[int]()
