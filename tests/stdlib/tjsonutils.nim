discard """
  targets: "c cpp js"
"""

import std/jsonutils
import std/json

proc testRoundtrip[T](t: T, expected: string) =
  let j = t.toJson
  doAssert $j == expected, $j
  doAssert j.jsonTo(T).toJson == j
  var t2: T
  t2.fromJson(j)
  doAssert t2.toJson == j

import tables, sets, algorithm, sequtils, options, strtabs

type Foo = ref object
  id: int

proc `==`(a, b: Foo): bool =
  a.id == b.id

template fn() = 
  block: # toJson, jsonTo
    type Foo = distinct float
    testRoundtrip('x', """120""")
    when not defined(js):
      testRoundtrip(cast[pointer](12345)): """12345"""
      when nimvm:
        discard
        # bugs:
        # Error: unhandled exception: 'intVal' is not accessible using discriminant 'kind' of type 'TNode' [
        # Error: VM does not support 'cast' from tyNil to tyPointer
      else:
        testRoundtrip(pointer(nil)): """0"""
        testRoundtrip(cast[pointer](nil)): """0"""

    # causes workaround in `fromJson` potentially related to
    # https://github.com/nim-lang/Nim/issues/12282
    testRoundtrip(Foo(1.5)): """1.5"""

  block:
    testRoundtrip({"z": "Z", "y": "Y"}.toOrderedTable): """{"z":"Z","y":"Y"}"""
    testRoundtrip({"z": (f1: 'f'), }.toTable): """{"z":{"f1":102}}"""

  block:
    testRoundtrip({"name": "John", "city": "Monaco"}.newStringTable): """{"mode":"modeCaseSensitive","table":{"city":"Monaco","name":"John"}}"""

  block: # complex example
    let t = {"z": "Z", "y": "Y"}.newStringTable
    type A = ref object
      a1: string
    let a = (1.1, "fo", 'x', @[10,11], [true, false], [t,newStringTable()], [0'i8,3'i8], -4'i16, (foo: 0.5'f32, bar: A(a1: "abc"), bar2: A.default))
    testRoundtrip(a):
      """[1.1,"fo",120,[10,11],[true,false],[{"mode":"modeCaseSensitive","table":{"y":"Y","z":"Z"}},{"mode":"modeCaseSensitive","table":{}}],[0,3],-4,{"foo":0.5,"bar":{"a1":"abc"},"bar2":null}]"""

  block:
    # edge case when user defined `==` doesn't handle `nil` well, e.g.:
    # https://github.com/nim-lang/nimble/blob/63695f490728e3935692c29f3d71944d83bb1e83/src/nimblepkg/version.nim#L105
    testRoundtrip(@[Foo(id: 10), nil]): """[{"id":10},null]"""

  block:
    type Foo = enum f1, f2, f3, f4, f5
    type Bar = enum b1, b2, b3, b4
    let a = [f2: b2, f3: b3, f4: b4]
    doAssert b2.ord == 1 # explains the `1`
    testRoundtrip(a): """[1,2,3]"""

  block: # case object
    type Foo = object
      x0: float
      case t1: bool
      of true: z1: int8
      of false: z2: uint16
      x1: string
    testRoundtrip(Foo(t1: true, z1: 5, x1: "bar")): """{"x0":0.0,"t1":true,"z1":5,"x1":"bar"}"""
    testRoundtrip(Foo(x0: 1.5, t1: false, z2: 6)): """{"x0":1.5,"t1":false,"z2":6,"x1":""}"""
    type PFoo = ref Foo
    testRoundtrip(PFoo(x0: 1.5, t1: false, z2: 6)): """{"x0":1.5,"t1":false,"z2":6,"x1":""}"""

  block: # ref case object
    type Foo = ref object
      x0: float
      case t1: bool
      of true: z1: int8
      of false: z2: uint16
      x1: string
    testRoundtrip(Foo(t1: true, z1: 5, x1: "bar")): """{"x0":0.0,"t1":true,"z1":5,"x1":"bar"}"""
    testRoundtrip(Foo(x0: 1.5, t1: false, z2: 6)): """{"x0":1.5,"t1":false,"z2":6,"x1":""}"""

  block: # generic case object
    type Foo[T] = ref object
      x0: float
      case t1: bool
      of true: z1: int8
      of false: z2: uint16
      x1: string
    testRoundtrip(Foo[float](t1: true, z1: 5, x1: "bar")): """{"x0":0.0,"t1":true,"z1":5,"x1":"bar"}"""
    testRoundtrip(Foo[int](x0: 1.5, t1: false, z2: 6)): """{"x0":1.5,"t1":false,"z2":6,"x1":""}"""
    # sanity check: nesting inside a tuple
    testRoundtrip((Foo[int](x0: 1.5, t1: false, z2: 6), "foo")): """[{"x0":1.5,"t1":false,"z2":6,"x1":""},"foo"]"""

  block: # case object: 2 discriminants, `when` branch, range discriminant
    type Foo[T] = object
      case t1: bool
      of true:
        z1: int8
      of false:
        z2: uint16
      when T is float:
        case t2: range[0..3]
        of 0: z3: int8
        of 2,3: z4: uint16
        else: discard
    testRoundtrip(Foo[float](t1: true, z1: 5, t2: 3, z4: 12)): """{"t1":true,"z1":5,"t2":3,"z4":12}"""
    testRoundtrip(Foo[int](t1: false, z2: 7)): """{"t1":false,"z2":7}"""
    # pending https://github.com/nim-lang/Nim/issues/14698, test with `type Foo[T] = ref object`

  block: # bug: pass opt params in fromJson
    type Foo = object
      a: int
      b: string
      c: float
    type Bar = object
      foo: Foo
      boo: string
    var f: seq[Foo]
    try:
      fromJson(f, parseJson """[{"b": "bbb"}]""")
      doAssert false
    except ValueError:
      doAssert true
    fromJson(f, parseJson """[{"b": "bbb"}]""", Joptions(allowExtraKeys: true, allowMissingKeys: true))
    doAssert f == @[Foo(a: 0, b: "bbb", c: 0.0)]
    var b: Bar
    fromJson(b, parseJson """{"foo": {"b": "bbb"}}""", Joptions(allowExtraKeys: true, allowMissingKeys: true))
    doAssert b == Bar(foo: Foo(a: 0, b: "bbb", c: 0.0))
    block: # jsonTo with `opt`
      let b2 = """{"foo": {"b": "bbb"}}""".parseJson.jsonTo(Bar,  Joptions(allowExtraKeys: true, allowMissingKeys: true))
      doAssert b2 == Bar(foo: Foo(a: 0, b: "bbb", c: 0.0))

  block testHashSet:
    testRoundtrip(HashSet[string]()): "[]"
    testRoundtrip([""].toHashSet): """[""]"""
    testRoundtrip(["one"].toHashSet): """["one"]"""

    var s: HashSet[string]
    fromJson(s, parseJson("""["one","two"]"""))
    doAssert s == ["one", "two"].toHashSet

    let jsonNode = toJson(s)
    doAssert jsonNode.elems.mapIt(it.str).sorted == @["one", "two"]

  block testOrderedSet:
    testRoundtrip(["one", "two", "three"].toOrderedSet):
      """["one","two","three"]"""

  block testOption:
    testRoundtrip(some("test")): "\"test\""
    testRoundtrip(none[string]()): "null"
    testRoundtrip(some(42)): "42"
    testRoundtrip(none[int]()): "null"

  block testStrtabs:
    testRoundtrip(newStringTable(modeStyleInsensitive)):
      """{"mode":"modeStyleInsensitive","table":{}}"""

    testRoundtrip(
      newStringTable("name", "John", "surname", "Doe", modeCaseSensitive)):
        """{"mode":"modeCaseSensitive","table":{"name":"John","surname":"Doe"}}"""

  block testJoptions:
    type
      AboutLifeUniverseAndEverythingElse = object
        question: string
        answer: int

    block testExceptionOnExtraKeys:
      var guide: AboutLifeUniverseAndEverythingElse
      let json = parseJson(
        """{"question":"6*9=?","answer":42,"author":"Douglas Adams"}""")
      doAssertRaises ValueError, fromJson(guide, json)
      doAssertRaises ValueError,
                     fromJson(guide, json, Joptions(allowMissingKeys: true))

      type
        A = object
          a1,a2,a3: int
      var a: A
      let j = parseJson("""{"a3": 1, "a4": 2}""")
      doAssertRaises ValueError,
                     fromJson(a, j, Joptions(allowMissingKeys: true))

    block testExceptionOnMissingKeys:
      var guide: AboutLifeUniverseAndEverythingElse
      let json = parseJson("""{"answer":42}""")
      doAssertRaises ValueError, fromJson(guide, json)
      doAssertRaises ValueError,
                     fromJson(guide, json, Joptions(allowExtraKeys: true))

    block testAllowExtraKeys:
      var guide: AboutLifeUniverseAndEverythingElse
      let json = parseJson(
        """{"question":"6*9=?","answer":42,"author":"Douglas Adams"}""")
      fromJson(guide, json, Joptions(allowExtraKeys: true))
      doAssert guide == AboutLifeUniverseAndEverythingElse(
        question: "6*9=?", answer: 42)

    block testAllowMissingKeys:
      var guide = AboutLifeUniverseAndEverythingElse(
        question: "6*9=?", answer: 54)
      let json = parseJson("""{"answer":42}""")
      fromJson(guide, json, Joptions(allowMissingKeys: true))
      doAssert guide == AboutLifeUniverseAndEverythingElse(
        question: "6*9=?", answer: 42)

    block testAllowExtraAndMissingKeys:
      var guide = AboutLifeUniverseAndEverythingElse(
        question: "6*9=?", answer: 54)
      let json = parseJson(
        """{"answer":42,"author":"Douglas Adams"}""")
      fromJson(guide, json, Joptions(
        allowExtraKeys: true, allowMissingKeys: true))
      doAssert guide == AboutLifeUniverseAndEverythingElse(
        question: "6*9=?", answer: 42)

    type
      Foo = object
        a: array[2, string]
        case b: bool
        of false: f: float
        of true: t: tuple[i: int, s: string]
        case c: range[0 .. 2]
        of 0: c0: int
        of 1: c1: float
        of 2: c2: string

    block testExceptionOnMissingDiscriminantKey:
      var foo: Foo
      let json = parseJson("""{"a":["one","two"]}""")
      doAssertRaises ValueError, fromJson(foo, json)

    block testDoNotResetMissingFieldsWhenHaveDiscriminantKey:
      var foo = Foo(a: ["one", "two"], b: true, t: (i: 42, s: "s"),
                    c: 0, c0: 1)
      let json = parseJson("""{"b":true,"c":2}""")
      fromJson(foo, json, Joptions(allowMissingKeys: true))
      doAssert foo.a == ["one", "two"]
      doAssert foo.b
      doAssert foo.t == (i: 42, s: "s")
      doAssert foo.c == 2
      doAssert foo.c2 == ""

    block testAllowMissingDiscriminantKeys:
      var foo: Foo
      let json = parseJson("""{"a":["one","two"],"c":1,"c1":3.14159}""")
      fromJson(foo, json, Joptions(allowMissingKeys: true))
      doAssert foo.a == ["one", "two"]
      doAssert not foo.b
      doAssert foo.f == 0.0
      doAssert foo.c == 1
      doAssert foo.c1 == 3.14159

    block testExceptionOnWrongDiscirminatBranchInJson:
      var foo = Foo(b: false, f: 3.14159, c: 0, c0: 42)
      let json = parseJson("""{"c2": "hello"}""")
      doAssertRaises ValueError,
                     fromJson(foo, json, Joptions(allowMissingKeys: true))
      # Test that the original fields are not reset.
      doAssert not foo.b
      doAssert foo.f == 3.14159
      doAssert foo.c == 0
      doAssert foo.c0 == 42

    block testNoExceptionOnRightDiscriminantBranchInJson:
      var foo = Foo(b: false, f: 0, c:1, c1: 0)
      let json = parseJson("""{"f":2.71828,"c1": 3.14159}""")
      fromJson(foo, json, Joptions(allowMissingKeys: true))
      doAssert not foo.b
      doAssert foo.f == 2.71828
      doAssert foo.c == 1
      doAssert foo.c1 == 3.14159

    block testAllowExtraKeysInJsonOnWrongDisciriminatBranch:
      var foo = Foo(b: false, f: 3.14159, c: 0, c0: 42)
      let json = parseJson("""{"c2": "hello"}""")
      fromJson(foo, json, Joptions(allowMissingKeys: true,
                                   allowExtraKeys: true))
      # Test that the original fields are not reset.
      doAssert not foo.b
      doAssert foo.f == 3.14159
      doAssert foo.c == 0
      doAssert foo.c0 == 42

    when false:
      ## TODO: Implement support for nested variant objects allowing the tests
      ## bellow to pass.
      block testNestedVariantObjects:
        type
          Variant = object
            case b: bool
            of false:
              case bf: bool
              of false: bff: int
              of true: bft: float
            of true:
              case bt: bool
              of false: btf: string
              of true: btt: char

        testRoundtrip(Variant(b: false, bf: false, bff: 42)):
          """{"b": false, "bf": false, "bff": 42}"""
        testRoundtrip(Variant(b: false, bf: true, bft: 3.14159)):
          """{"b": false, "bf": true, "bft": 3.14159}"""
        testRoundtrip(Variant(b: true, bt: false, btf: "test")):
          """{"b": true, "bt": false, "btf": "test"}"""
        testRoundtrip(Variant(b: true, bt: true, btt: 'c')):
          """{"b": true, "bt": true, "btt": "c"}"""
        
        # TODO: Add additional tests with missing and extra JSON keys, both when
        # allowed and forbidden analogous to the tests for the not nested
        # variant objects.

static: fn()
fn()
