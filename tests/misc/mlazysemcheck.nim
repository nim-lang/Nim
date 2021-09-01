discard """
  matrix: "-d:case_noimports; -d:case4; -d:case_stdlib ; -d:case_import1; -d:case_cyclic"
"""
#[
PRTEMP: move to tlazysemcheck otherwise tests won't run?
]#

{.define(nimLazySemcheck).}

# first, define convenience procs for testing
var witness: string

template echo2(a: auto) =
  witness.add $a
  witness.add "\n"

template chk(a: auto) =
  if witness != a:
    echo "witness mismatch:"
    echo "expected: \n" & a
    echo "actual  : \n" & witness
    doAssert false

# next, define each test case:

when defined case_noimports:
  # fwd proc + impl proc without `*` in impl
  proc fn1*(): int
  proc fn1: int = 2
  static: doAssert fn1() == 2
  doAssert fn1() == 2

  block: # out of order
    proc fn1 =
      fn2()
    proc fn2 =
      if false:
        fn1()
      echo2 "fn2"
    when 1+1 == 2:
      proc fn3() = fn1()
    when 1+1 == 3:
      proc fn4_nonexistent()
    fn3()

  block: # callback
    proc fn() = discard
    proc bar(a: proc()): int = discard
    proc bar2()=
      let b = bar(fn)
    bar2()

  block: # anon
    proc fn(a: int, b: proc()) = discard
    fn(1, proc() = discard)

  block: # overload
    proc fn(a: int): int = 1
    proc fn(a: int64): int = 2
    doAssert fn(1) == 1
    doAssert fn(1'i64) == 2

  block:
    proc fn1(): int
    proc fn1(): int = 1
    doAssert fn1() == 1

  block:
    proc fn1(): int
    proc fn1(): int = 1
    let z1 = fn1()
    doAssert z1 == 1

  block:
    proc fn1(): int
    proc fn1(): int = 1
    const z1 = fn1()
    doAssert z1 == 1

  block:
    proc fn1(): int
    proc fn1(): int = 1
    const z1 = fn1()
    type A = proc(): int
    # type T = type(fn1)
    # echo T # BUG: PRTEMP None
    # doAssert type(fn1) is A # BUG: Error: internal error: genMagicExpr: mIs
    doAssert type(fn1()) is int

  chk "fn2\n"

when defined case4:
  import mlazysemcheck_c
  from mlazysemcheck_b import b1

  proc baz3(a: int) = echo2 "in baz3"
  proc baz2(a: float) =
    static: echo " ct baz2 float"
  proc baz2(a: int) =
    static: echo " ct baz2"
    baz3(a)
  proc baz1(a: int) = baz2(a)
  proc baz(a: int) = baz1(a)
  block:
    proc fn1(a: int) =
      echo2 ("fn1", a)
      if a>0:
        fn2(a-1)
    proc fn2(a: int) =
      echo2 ("fn2", a)
      if a>0:
        fn1(a-1)
    when 1+1 == 2:
      proc fn3()
    when 1+1 == 3:
      proc fn4()
    fn1(10)
    when true:
      baz(3)
      b1()
  block: # iterator
    proc bar =
      for ai in fn(3):
        echo2 ai
    iterator fn(n: int): int =
      for i in 0..<n:
        yield i*10
    echo2 "iterator"
    bar()

  chk """
("fn1", 10)
("fn2", 9)
("fn1", 8)
("fn2", 7)
("fn1", 6)
("fn2", 5)
("fn1", 4)
("fn2", 3)
("fn1", 2)
("fn2", 1)
("fn1", 0)
in baz3
iterator
0
10
20
"""

when defined case_stdlib:
  #[
  WAS: case7
  ]#
  import strutils
  doAssert repeat("ab", 3) == "ababab"
  import algorithm
  doAssert isSorted([10,11,12])
  doAssert not isSorted([10,11,12, 5])
  doAssert @[1,4,2].sorted == @[1,2,4]

  import algorithm, math, strutils
  doAssert "abCd".toUpper == "ABCD"
  import strutils
  doAssert "abCd".toLower == "abcd"
  doAssert "abCd".repeat(3) == "abCdabCdabCd"
  doAssert not isNaN(3.4)
  doAssert floorDiv(17,4) == 4

  import os
  doAssert ("ab" / "cd" / "ef").endsWith("ef")

  doAssert 1.5 mod 1.6 == 1.5

  import options, times
  # BUG xxx PRTEMP
  # Error: internal error: getTypeDescAux(tyFromExpr)
  when false:
    let t = now()
    let t2 = now()
    doAssert t2 > t

when defined case_import1:
  import mlazysemcheck_b
  doAssert 3.sorted2 == 6
  doAssert not c_isnan2(1.5)
  doAssert not c_isnan3(1.5)
  doAssert hash(@[1,2]) == 123
  doAssert testCallback() == 123

when defined case_cyclic:
  #[
  example showing cyclic deps work
  ]#
  import mlazysemcheck_b
  proc fn1*(s: var string, a: int) =
    s.add $("fn1", a)
    if a>0:
      fn2(s, a-1)
  var s = ""
  fn1(s, 3)
  doAssert s == """("fn1", 3)("fn2", 2)("fn1", 1)("fn2", 0)"""

  #[
  example showing cyclic deps work, with auto
  ]#
  proc fn3*(s: var string, a: int): auto =
    result = newSeq[int]()
    s.add $("fn1", a)
    for i in 0..<a:
      result.add fn4(s, i)
  var s2 = ""
  let ret = fn3(s2, 4)
  doAssert ret == @[0, 1, 2, 3]
  doAssert s2 == """("fn1", 4)("fn2", 0, "seq[int]")("fn2", 1, "seq[int]")("fn2", 2, "seq[int]")("fn2", 3, "seq[int]")"""

when defined case_perf:
  #[
  TODO:
  example showing perf for lots of imports
  ]#
  import std/[strutils, os, times, enumutils, browsers]
  echo 1

## scratch below

when defined case10c:
  proc aux0()=discard
  static: echo "ok0"
  import mlazysemcheck_b
  import mlazysemcheck_c
  static: echo "ok1"
  discard sorted2(1)
  static: echo "ok2"

when defined case10d:
  # works
  proc aux0()=discard
  static: echo "ok0"
  import mlazysemcheck_b
  import mlazysemcheck_c
  static: echo "ok1"
  discard sorted2(1)
  static: echo "ok2"

when defined case10e:
  # works
  proc aux0()=discard
  static: echo "ok0"
  import mlazysemcheck_b
  static: echo "ok1"
  discard sorted2(1)
  static: echo "ok2"

when defined case21:
  #[
  BUG D20210831T002126:here
  ]#
  import mlazysemcheck_b
  fn(1)

when defined case21b:
  import mlazysemcheck_b
  fn(1)

when defined case21c:
  import mlazysemcheck_b
  fn(1)

when defined case25:
  #[
  D20210831T132959 not accessible field
  ]#
  type A = object
    a0: float
  import mlazysemcheck_b
  fn()
  fn2(3)

when defined case25b:
  #[
  ]#
  import mlazysemcheck_b
  # proc bam() = echo "in bam"
  fn2(3)

when defined case26:
  #[
  D20210831T151342
  -d:nimLazySemcheck
  broken bc of compiles:
  prints:
  2
  (...,)

  would be fixed if not using compiles
  ]#
  import mlazysemcheck_b
  fn(2)
  # EDIT: how com works now?

when defined case27:
  # ok
  # proc llReadFromStdin(s: PLLStream, buf: pointer, bufLen: int): int
  type Foo = proc(): int
  proc foo(): int = 2
  # proc llStreamOpenStdIn*(r: TLLRepl = llReadFromStdin, onPrompt: OnPrompt = nil): PLLStream =
  # proc llStreamOpenStdIn*(r: Foo = foo) =
  proc llStreamOpenStdIn*(r = foo) =
  # proc llStreamOpenStdIn*(r = @[foo]) =
    discard
  llStreamOpenStdIn()


when defined case27a:
  # ok
  type Foo = proc(): int
  proc foo(): int = 2
  # discard foo()
  proc llStreamOpenStdIn*(r = foo) =
    discard
  llStreamOpenStdIn()

when defined case27b:
  # template stackTrace(c: PCtx, tos: PStackFrame, pc: int,
  #                     msg: string, lineInfo: TLineInfo = TLineInfo.default) =
  type A = object
    x: int
  template foo(lineInfo: A = A.default) =
  # template foo(lineInfo: A = default(A)) =
    discard
  foo()

when defined case27c:
  type A = object
    x: int
  proc foo(lineInfo: A = A.default) =
  # proc foo(lineInfo: A = default(A)) =
    discard
  foo()

when defined case27d:
  #[
  BUG D20210831T182524:here SIGSEGV
  ]#
  import mlazysemcheck_b
  llStreamOpenStdIn()

when defined case28:
  #[
  BUG D20210831T175533:here
  /t12748.nim(494, 8) Error: internal error: still forwarded: fn
  not really a bug but should report a proper error
  ]#
  proc fn()
  fn()

when defined case30:
  import mlazysemcheck_b
  fn()
