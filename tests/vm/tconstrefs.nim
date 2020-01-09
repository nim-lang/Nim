import std/json

block: # case ref objects
  const j = parseJson(""" {"x1":12,"x2":"asdf","x3":[1,2]} """)
  const x1 = j["x1"].getInt
  const x2 = j["x3"].to(seq[int])
  when false:
    # pending https://github.com/nim-lang/Nim/issues/13081
    echo j["x1"].getInt

  doAssert x1 == 12
  doAssert x2 == @[1, 2]

block: # case objects
  type Foo = ref object
    x1: int
    x2: string
    x3: seq[string]
  const j1 = Foo(x1: 12, x2: "asdf", x3: @["foo", "bar"])
  doAssert j1[] == Foo(x1: 12, x2: "asdf", x3: @["foo", "bar"])[]
  doAssert $j1[] == """(x1: 12, x2: "asdf", x3: @["foo", "bar"])"""
