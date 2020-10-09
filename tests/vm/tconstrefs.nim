discard """
  targets:  "c cpp js"
"""

import std/json

block: # ref objects
  type Foo = ref object
    x1: int
    x2: string
    x3: seq[string]
  const j1 = Foo(x1: 12, x2: "asdf", x3: @["foo", "bar"])
  doAssert j1[] == Foo(x1: 12, x2: "asdf", x3: @["foo", "bar"])[]
  doAssert $j1[] == """(x1: 12, x2: "asdf", x3: @["foo", "bar"])"""
  doAssert j1.x2 == "asdf"

block: # nested ref objects
  type Bar = ref object
    b0: int
  type Foo2 = ref object
    f0: Bar
  const f = Foo2(f0: Bar(b0: 1))
  doAssert f.f0.b0 == 1

block: # ref object of
  type Foo = ref object of RootObj
    f0: int
  const f = @[Foo(f0: 1), Foo(f0: 2)]
  doAssert f[1].f0 == 2
  let f2 = f
  doAssert f2[1].f0 == 2

  type Goo = ref object of Foo
    g0: int
  const g = @[Goo(g0: 3), Goo(g0: 4, f0: 5)]
  doAssert g[0].g0 == 3
  doAssert g[0].f0 == 0
  doAssert g[1].g0 == 4
  doAssert g[1].f0 == 5

block: # complex example
  type Bar = ref object
    b0: int
  type Foo3 = ref object
    f0: Bar
    f1: array[2, Bar]
    f2: seq[Bar]
    f3: seq[Foo3]
    f4: string

  proc initFoo3(s: string): Foo3 =
    result = Foo3(f0: Bar(b0: 2))
    result.f1 = [nil, Bar(b0: 3)]
    result.f2 = @[Bar(b0: 4)]
    result.f3 = @[Foo3(f4: s)]
    result.f4 = s

  const f = initFoo3("abc")
  let f2 = f
  var f3 = f
  var f4 = f.unsafeAddr[]
  var f5 = [f,f]

  proc fn(a: Foo3) =
    # shows we can pass a const ref to a proc
    doAssert a.f4 == "abc"

  fn(f)

  template check(x: Foo3) =
    fn(x)
    doAssert x.f0.b0 == 2
    doAssert x.f1[0] == nil
    doAssert x.f1[1].b0 == 3
    doAssert x.f2[0].b0 == 4
    doAssert x.f3[0].f4 == "abc"
    doAssert x.f4 == "abc"

  check(f)
  check(f2)
  check(f3)
  check(f4)
  check(f5[0])

  const f6 = f.f3
  doAssert f6[0].f4 == "abc"
  let f7 = f6
  doAssert f7[0].f4 == "abc"
  var f8: array[2,Bar]
  f8 = f.f1
  doAssert f8[1].b0 == 3
  var f9: (Foo3,)
  f9[0] = f
  doAssert f9[0].f0.b0 == 2

block: # case ref objects
  const j = parseJson(""" {"x1":12,"x2":"asdf","x3":[1,2]} """)
  const x1 = j["x1"].getInt
  const x2 = j["x3"].to(seq[int])
  when false:
    # pending https://github.com/nim-lang/Nim/issues/13081
    echo j["x1"].getInt
  doAssert j["x1"].getInt.static == 12

  doAssert x1 == 12
  doAssert x2 == @[1, 2]

block: # regression test with closures
  type MyProc = proc (x: int): int
  proc even(x: int): int = x*3
  proc bar(): seq[MyProc] =
    result.add even
    result.setLen 2 # intentionally leaving 1 unassigned
  const a = bar()
  when not defined(js):
    doAssert a == bar()
  doAssert a[0](2) == 2*3
