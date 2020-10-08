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
  # let f7 = f6
  # doAssert f7[0].f4 == "abc"

block: # case ref objects
  const j = parseJson(""" {"x1":12,"x2":"asdf","x3":[1,2]} """)
  const x1 = j["x1"].getInt
  const x2 = j["x3"].to(seq[int])
  when false:
    # pending https://github.com/nim-lang/Nim/issues/13081
    echo j["x1"].getInt

  doAssert x1 == 12
  doAssert x2 == @[1, 2]
