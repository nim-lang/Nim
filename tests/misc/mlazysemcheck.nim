#[
## notes
see main test: `tlazysemcheck`

## TODO
* support `from a import b` (`import a` already works) in presence of cyclic deps
  which would mean importing a lazy symbol.
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
  when true: # top-level tests
    # export with fwd proc + impl proc without `*` in impl
    proc gfn1*(): int
    proc gfn1: int = 2
    static: doAssert gfn1() == 2
    doAssert gfn1() == 2

    # method
    type Ga = ref object of RootObj
    method gfn2*(a: Ga, b: string) {.base, gcsafe.} = discard
    block:
      var a = Ga()
      a.gfn2("")

    # converter
    type Ga3 = object
      a0: int
    type Gb3 = object
      b0: int
    converter toGb3(a: Ga3): Gb3 =
      Gb3(b0: a.a0)
    block:
      var a = Ga3(a0: 3)
      var b: Gb3 = a
      doAssert b == Gb3(b0: 3)

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
    type Foo = proc(): int
    proc foo1(): int = 2
    proc foo2(): int = 2
    proc bar1(r = foo1) = discard
    proc bar2(r = @[foo2]) = discard
    bar1()
    bar2()

  block:
    type A = object
      x: int
    template foo1(lineInfo: A = A.default) = discard
    template foo2(lineInfo: A = default(A)) = discard
    proc foo3(lineInfo: A = A.default) = discard
    proc foo4(lineInfo: A = default(A)) = discard
    foo1()
    foo2()
    foo3()
    foo4()

  block:
    proc fn1(): int
    proc fn1(): int = 1
    const z1 = fn1()
    doAssert type(fn1()) is int

  block:
    proc fn1(): int
    proc fn1(): int = 1
    type T = type(fn1)
    var a: T
    doAssert type(fn1) is proc

  block:
    # test a case where a generic `foo` semcheck triggers another semcheck that in turns
    # calls `foo`
    proc foo[T](a: T) =
      var b: T
      type T2 = typeof(bar())
    proc bar() =
      foo(1)
    foo(1)

  block:
    # variation on this
    proc foo[T](a: T) =
      var b: T
      when T is string:
        static:
          bar()
    proc bar() =
      foo(1.5)
    foo(1)

  block: # compiles
    block:
      proc foo[T](a: T) =
        var b: T
        const z1 = compiles(bar(""))
        const z2 = compiles(bar(1.0))
        doAssert not z1
        doAssert z2
      proc bar(a: float) =
        foo(1)
      foo(1)
    block:
      proc fn(a: int) = discard
      proc fn2(a: int) = discard
      block:
        doAssert compiles(fn(1))
        doAssert not compiles(fn(""))
        doAssert not compiles(fn_nonexistent(1))
        block:
          proc fn3(a: int) = discard
          doAssert compiles(fn3(1))
        doAssert not compiles(fn3(1))

  block: # a regression test involving fwd declared procs
    block:
      proc fn1(): int
      proc fn1(): int = discard
      let z1 = fn1()
    block:
      proc fn1(): int
      let z1 = fn1()
      proc fn1(): int = discard
    block:
      proc fn1(): int
      proc fn1(): int = discard
      discard fn1()
    block:
      proc fn1(): int
      discard fn1()
      proc fn1(): int = discard
    block:
      proc fn1(): int = discard
      let z1 = fn1
    block:
      proc fn1(): int
      proc fn1(): int = discard
      let z1 = fn1
    block:
      proc fn1(): int
      proc fn1(): int = discard
      const z1 = fn1
    block:
      proc fn1(): int
      proc fn1(): int = discard
      var z1: type(fn1)

  block: # semchecking `fun1(fun2(arg))` inside a generic
    proc fun[T](a: T): auto =
      result = bar1(bar2(a))
    proc bar2(a: int): int =
      a*3
    proc bar1(a: int):int =
      a*2
    doAssert fun(4) == 4 * 3 * 2

  block: # a regression test
    proc fun2[T](a: T): auto =
      const b = bar1(bar2(T.sizeof))
      result = b
    proc bar2(a: int): int =
      a*3
    proc bar1(a: int):int =
      a*2
    doAssert fun2(1'i16) == (int16.sizeof) * 3 * 2

  block: # a regression test
    proc fun3[T](a: T): auto =
      const b = bar1(bar2(T.sizeof))
      result = b
    proc bar2(a: auto): auto =
      a*3
    proc bar1(a: auto): auto =
      a*2
    doAssert fun3(1'i16) == (int16.sizeof) * 3 * 2

  block: # regression tests
    # D20210902T184355
    block:
      proc fnAux(): int
      type FnAux = proc(): int
      proc fn7(r: FnAux = fnAux) = discard
      proc fnAux(): int = discard
      fn7()

    block:
      proc fnAux(): int
      proc fn8(r = fnAux) = discard
      proc fnAux(): int = discard
      fn8()

    block:
      proc fnAux(): int
      proc fnAux(b: float): int
      type FnAux = proc(): int
      proc fn9(r: FnAux = fnAux) = discard
      proc fnAux(): int = discard
      proc fnAux(b: float): int = discard
      fn9()

    block:
      proc fnAux(): int
      proc fnAux(b: float): int = discard
      proc fnAux(b: float32): int = discard
      type FnAux = proc(): int
      proc fn10(r: FnAux = fnAux) = discard
      proc fnAux(): int = discard
      fn10()

    block:
      proc fnAux(b: float): int
      proc fnAux(): int = discard
      proc fn11(r = fnAux) = discard
      doAssert not compiles(fn11()) # ambiguous

  block:
    proc fn12() =
      when not defined(nimLazySemcheckComplete):
        static: doAssert false # shouldn't fail because semcheck should be lazy
    template bar() =
      static: fn12() # semchecking bar shouldn't trigger calling fn12
      fn12() # ditto

  block:
    proc fn12() =
      when not defined(nimLazySemcheckComplete):
        static: doAssert false # shouldn't fail because semcheck should be lazy
    proc fn2() =
      when not defined(nimLazySemcheckComplete):
        static: doAssert false # shouldn't fail because semcheck should be lazy
    template bar1() =
      static: fn12() # semchecking bar shouldn't trigger calling fn12
      fn12() # ditto
    proc bar2() =
      static: fn12()
      fn12() # ditto
    macro bar3() =
      static: fn12()
      fn12()
    iterator bar4(): int =
      static: fn12()
      fn12()

  block: # typed params in macros
    # D20210907T225444
    macro barUntyped1(fns: untyped): untyped =
      result = fns
    macro barUntyped2(fns: untyped): untyped =
      discard
    macro barTyped1(fns: typed): untyped =
      result = fns
    macro barTyped2(fns: typed): untyped =
      discard

    proc fn13(): int
    barTyped1: # works with fwd procs
      proc fn13(): int = 1
    doAssert fn13() == 1

    barUntyped2:
      proc fn14(): int =
        static: doAssert false

    template bad1 =
      barTyped2:
        proc fn15(): int =
          static: doAssert false

    template bad2 =
      barUntyped1:
        proc fn16(): int =
          static: doAssert false
        fn16()
    doAssert not compiles(bad1()) # typed params must be fully semcheck-able (epilogue happens during typed param evaluation)
    doAssert not compiles(bad2())

    barTyped1: # cycles work inside typed params
      proc fn17x1 = fn17x2()
      proc fn17x2 = fn17x3()
      proc fn17x3 = fn17x1()

    barTyped2: # ditto
      proc fn18x1 = fn18x2()
      proc fn18x2 = fn18x3()
      proc fn18x3 = fn18x1()

    template bad3 =
      barTyped2: # ditto
        proc fn18x1 = fn18x2()
        proc fn18x2 = fn18x3()
        proc fn18x3 = fn18x4()
    doAssert not compiles(bad3())
      # because `fn18x4` not declared; even if `barTyped2` then later ignores its input,
      # epilogue for typed param should prevent this from compiling

  chk "fn2\n"

elif defined case_reordering:
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

elif defined case_import1:
  import mlazysemcheck_b
  doAssert 3.sorted2 == 6
  doAssert not c_isnan2(1.5)
  doAssert not c_isnan3(1.5)
  doAssert hash(@[1,2]) == 123
  doAssert testCallback() == 123
  testFieldAccessible[int]()

  fn4(1)
  fn5(1)
  fn6(1)
  fn7(1)
  fn8(1)
  fn9(1)

  block: # a regression test
    type Foo = int
    proc bar(a: Foo)
    proc fun[T](a: T)
    proc fun[T](a: T) =
      const b = compiles(bar(1))
    proc gun[T](b: T) =
      var a: Foo
      fun(a)
    proc bar(a: Foo) =
      gun(1)
    fun("")

  block:
    fnProcParamDefault1a()
    fnProcParamDefault1b()
    when false: # xxx bug D20210831T182524
      fnProcParamDefault1c()
      fnProcParamDefault1()
      fnProcParamDefault2()

elif defined case_cyclic:
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

  #[
  3-way cycle, where each module imports the other 2
  ]#
  import mlazysemcheck_b
  import mlazysemcheck_c
  proc ha*(a: int): int =
    if a>0:
      hb(a-1) + hc(a-1)
    else:
      10
  doAssert ha(0) == 10
  doAssert ha(1) == 10
  doAssert ha(2) == 134
  doAssert ha(3) == 700

  #[
  3-way cycle with generics
  ]#
  import mlazysemcheck_b
  import mlazysemcheck_c

  proc someOverload*(a: int8): string = "int8"

  proc ga*[T](a: T): T =
    # checks that it finds the right overload among imports
    doAssert someOverload(1'i8) == "int8"
    doAssert someOverload(1'i16) == "int16"
    doAssert someOverload(1'i32) == "int32"
    if a>0:
      gb(a-1) + gc(a-1)
    else:
      10

  doAssert ga(0) == 10
  doAssert ga(1) == 10
  doAssert ga(2) == 134
  doAssert ga(3) == 700

elif defined case_many_fake_symbols:
  # a regression test
  proc semTypeNodeFake()
  proc semTypeNodeFake() = discard
  import macros
  macro genfns(n: static int): untyped =
    result = newStmtList()
    for i in 0..<n:
      let name2 = ident("fnz_" & $i)
      result.add quote do:
        proc `name2`(): int = discard
  genfns(1000)
  semTypeNodeFake()
  proc foo() =
    template bar() =
      semTypeNodeFake()
    bar()
  foo()

elif defined case_stdlib:
  import strutils, algorithm
  block:
    doAssert repeat("ab", 3) == "ababab"
    doAssert isSorted([10,11,12])
    doAssert not isSorted([10,11,12, 5])
    doAssert @[1,4,2].sorted == @[1,2,4]

  import algorithm, math, strutils

  block:
    doAssert "abCd".toUpper == "ABCD"
    doAssert "abCd".toLower == "abcd"
    doAssert "abCd".repeat(3) == "abCdabCdabCd"
    doAssert not isNaN(3.4)
    doAssert floorDiv(17,4) == 4

  import os

  block:
    doAssert ("ab" / "cd" / "ef").endsWith("ef")
    doAssert 1.5 mod 1.6 == 1.5

  import std/jsonutils
  import std/json
  block:
    let a = "abc"
    var a2: type(a)
    fromJson(a2, a.toJson)
    doAssert a2 == a

  import options, times

  block:
    let t = now()
    let t2 = now()
    doAssert t2 > t

elif defined case_test2:
  import std/macros
  block: # regression test D20210902T181022:here
    macro foo(normalizer: static[proc(s :string): string]): untyped =
      let ret = quote: `normalizer`
    proc baz(s: string): string = discard
    foo(baz)

elif defined case_stdlib_imports:
  {.define(nimCompilerDebug).}
  #[
  from tests/test_nimscript.nims, minus 1 module, see below
  ]#
  import std/[
  # Core:
  bitops, typetraits, lenientops, macros, volatile,
  typeinfo, endians,
  cpuinfo, rlocks, locks,

  # Algorithms:
  algorithm, sequtils,

  # Collections:
  critbits, deques, heapqueue, intsets, lists, options, sets,
  sharedlist, tables,
  sharedtables,

  # Strings:
  editdistance, wordwrap, parseutils, ropes,
  pegs, punycode, strformat, strmisc, strscans, strtabs,
  strutils, unicode, unidecode,
  cstrutils, encodings,

  # Time handling:
  monotimes, times,

  # Generic operator system services:
  os, streams,
  distros, dynlib, marshal, memfiles, osproc, terminal,

  # Math libraries:
  complex, math, mersenne, random, rationals, stats, sums, fenv,

  # Internet protocols:
  httpcore, mimetypes, uri,
  asyncdispatch, asyncfile, asyncftpclient, asynchttpserver,
  asyncnet, cgi, cookies, httpclient, nativesockets, net, selectors,
  # smtp, # require -d:ssl
  asyncstreams, asyncfutures,

  # Threading:
  # threadpool, # requires --threads

  # Parsers:
  htmlparser, json, lexbase, parsecfg, parsecsv, parsesql, parsexml,
  parseopt,

  # XML processing:
  xmltree, xmlparser,

  # Generators:
  htmlgen,

  # Hashing:
  base64, hashes,
  md5, oids, sha1,

  # Miscellaneous:
  colors, sugar, varints,
  browsers, logging, segfaults, unittest,
  # coro, # require -d:nimCoroutines

  # Modules for JS backend:
  # fails: asyncjs, dom, jsconsole, jscore, jsffi,

  # Unlisted in lib.html:
  decls, compilesettings, with, wrapnils
  ]

elif defined case_perf:
  #[
  PRTEMP TODO:
  example showing perf for lots of imports
  ]#
  import std/[strutils, os, times, enumutils, browsers]

elif defined case_bug1:
  #[
  D20210831T175533
  minor bug: this gives: `Error: internal error: still forwarded: fn`
  but instead should report a proper compiler error
  ]#
  proc fn()
  fn()

# scratch below

elif defined case_bug2:
  #[
  D20210831T151342
  -d:nimLazySemcheck (works if nimLazySemcheck passed after system is processed)
  broken bc of compiles ?
  prints:
  2
  (...,)
  would be fixed if not using compiles
  ]#
  import mlazysemcheck_b
  fn(2)

else:
  static: doAssert false
