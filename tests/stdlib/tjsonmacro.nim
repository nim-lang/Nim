discard """
  file: "tjsonmacro.nim"
  output: ""
"""
import json, strutils, options, tables

when isMainModule:
  # Tests inspired by own use case (with some additional tests).
  # This should succeed.
  type
    Point[T] = object
      x, y: T

    ReplayEventKind* = enum
      FoodAppeared, FoodEaten, DirectionChanged

    ReplayEvent* = object
      time*: float
      case kind*: ReplayEventKind
      of FoodAppeared, FoodEaten:
        foodPos*: Point[float]
      of DirectionChanged:
        playerPos*: float

    Replay* = ref object
      events*: seq[ReplayEvent]
      test: int
      test2: string
      test3: bool
      testNil: string

  var x = Replay(
    events: @[
      ReplayEvent(
        time: 1.2345,
        kind: FoodEaten,
        foodPos: Point[float](x: 5.0, y: 1.0)
      )
    ],
    test: 18827361,
    test2: "hello world",
    test3: true,
    testNil: nil
  )

  let node = %x

  let y = to(node, Replay)
  doAssert y.events[0].time == 1.2345
  doAssert y.events[0].kind == FoodEaten
  doAssert y.events[0].foodPos.x == 5.0
  doAssert y.events[0].foodPos.y == 1.0
  doAssert y.test == 18827361
  doAssert y.test2 == "hello world"
  doAssert y.test3
  doAssert y.testNil.isNil

  # Test for custom object variants (without an enum) and with an else branch.
  block:
    type
      TestVariant = object
        name: string
        case age: uint8
        of 2:
          preSchool: string
        of 8:
          primarySchool: string
        else:
          other: int

    var node = %{
      "name": %"Nim",
      "age": %8,
      "primarySchool": %"Sandtown"
    }

    var result = to(node, TestVariant)
    doAssert result.age == 8
    doAssert result.name == "Nim"
    doAssert result.primarySchool == "Sandtown"

    node = %{
      "name": %"⚔️Foo☢️",
      "age": %25,
      "other": %98
    }

    result = to(node, TestVariant)
    doAssert result.name == node["name"].getStr()
    doAssert result.age == node["age"].getInt().uint8
    doAssert result.other == node["other"].getBiggestInt()

  # TODO: Test object variant with set in of branch.
  # TODO: Should we support heterogenous arrays?

  # Tests that verify the error messages for invalid data.
  block:
    type
      Person = object
        name: string
        age: int

    var node = %{
      "name": %"Dominik"
    }

    try:
      discard to(node, Person)
      doAssert false
    except KeyError as exc:
      doAssert("age" in exc.msg)
    except:
      doAssert false

    node["age"] = %false

    try:
      discard to(node, Person)
      doAssert false
    except JsonKindError as exc:
      doAssert("age" in exc.msg)
    except:
      doAssert false

    type
      PersonAge = enum
        Fifteen, Sixteen

      PersonCase = object
        name: string
        case age: PersonAge
        of Fifteen:
          discard
        of Sixteen:
          id: string

    try:
      discard to(node, PersonCase)
      doAssert false
    except JsonKindError as exc:
      doAssert("age" in exc.msg)
    except:
      doAssert false

  # Test the example in json module.
  block:
    let jsonNode = parseJson("""
      {
        "person": {
          "name": "Nimmer",
          "age": 21
        },
        "list": [1, 2, 3, 4]
      }
    """)

    type
      Person = object
        name: string
        age: int

      Data1 = object # TODO: Codegen bug when changed to ``Data``.
        person: Person
        list: seq[int]

    var data = to(jsonNode, Data1)
    doAssert data.person.name == "Nimmer"
    doAssert data.person.age == 21
    doAssert data.list == @[1, 2, 3, 4]

  # Test non-variant enum fields.
  block:
    type
      EnumType = enum
        Foo, Bar

      TestEnum = object
        field: EnumType

    var node = %{
      "field": %"Bar"
    }

    var result = to(node, TestEnum)
    doAssert result.field == Bar

  # Test ref type in field.
  block:
    var jsonNode = parseJson("""
      {
        "person": {
          "name": "Nimmer",
          "age": 21
        },
        "list": [1, 2, 3, 4]
      }
    """)

    type
      Person = ref object
        name: string
        age: int

      Data = object
        person: Person
        list: seq[int]

    var data = to(jsonNode, Data)
    doAssert data.person.name == "Nimmer"
    doAssert data.person.age == 21
    doAssert data.list == @[1, 2, 3, 4]

    jsonNode = parseJson("""
      {
        "person": null,
        "list": [1, 2, 3, 4]
      }
    """)
    data = to(jsonNode, Data)
    doAssert data.person.isNil

  block:
    type
      FooBar = object
        field: float

    let x = parseJson("""{ "field": 5}""")
    let data = to(x, FooBar)
    doAssert data.field == 5.0

  block:
    type
      BirdColor = object
        name: string
        rgb: array[3, float]

    type
      Bird = object
        age: int
        height: float
        name: string
        colors: array[2, BirdColor]

    var red = BirdColor(name: "red", rgb: [1.0, 0.0, 0.0])
    var blue = Birdcolor(name: "blue", rgb: [0.0, 0.0, 1.0])
    var b = Bird(age: 3, height: 1.734, name: "bardo", colors: [red, blue])
    let jnode = %b
    let data = jnode.to(Bird)
    doAssert data == b

  block:
    type
      MsgBase = ref object of RootObj
        name*: string

      MsgChallenge = ref object of MsgBase
        challenge*: string

    let data = %*{"name": "foo", "challenge": "bar"}
    let msg = data.to(MsgChallenge)
    doAssert msg.name == "foo"
    doAssert msg.challenge == "bar"

  block:
    type
      Color = enum Red, Brown
      Thing = object
        animal: tuple[fur: bool, legs: int]
        color: Color

    var j = parseJson("""
      {"animal":{"fur":true,"legs":6},"color":"Red"}
    """)

    let parsed = to(j, Thing)
    doAssert parsed.animal.fur
    doAssert parsed.animal.legs == 6
    doAssert parsed.color == Red

  block:
    type
      Car = object
        engine: tuple[name: string, capacity: float]
        model: string

    let j = """
      {"engine": {"name": "V8", "capacity": 5.5}, "model": "Skyline"}
    """

    var i = 0
    proc mulTest: JsonNode =
      i.inc()
      return parseJson(j)

    let parsed = mulTest().to(Car)
    doAssert parsed.engine.name == "V8"

    doAssert i == 1

  block:
    # Option[T] support!
    type
      Car1 = object # TODO: Codegen bug when `Car`
        engine: tuple[name: string, capacity: Option[float]]
        model: string
        year: Option[int]

    let noYear = """
      {"engine": {"name": "V8", "capacity": 5.5}, "model": "Skyline"}
    """

    let noYearParsed = parseJson(noYear)
    let noYearDeser = to(noYearParsed, Car1)
    doAssert noYearDeser.engine.capacity == some(5.5)
    doAssert noYearDeser.year.isNone
    doAssert noYearDeser.engine.name == "V8"

    # Issue #7433
    type
      Obj2 = object
        n1: int
        n2: Option[string]
        n3: bool

    var j = %*[ { "n1": 4, "n2": "ABC", "n3": true },
                { "n1": 1, "n3": false },
                { "n1": 1, "n2": "XYZ", "n3": false } ]

    let jDeser = j.to(seq[Obj2])
    doAssert jDeser[0].n2.get() == "ABC"
    doAssert jDeser[1].n2.isNone()

    # Issue #6902
    type
      Obj = object
        n1: int
        n2: Option[int]
        n3: Option[string]
        n4: Option[bool]
        
    var j0 = parseJson("""{"n1": 1, "n2": null, "n3": null, "n4": null}""")
    let j0Deser = j0.to(Obj)
    doAssert j0Deser.n1 == 1
    doAssert j0Deser.n2.isNone()
    doAssert j0Deser.n3.isNone()
    doAssert j0Deser.n4.isNone()

  # Table[T, Y] support.
  block:
    type
      Friend = object
        name: string
        age: int

      Dynamic = object
        name: string
        friends: Table[string, Friend]

    let data = """
      {"friends": {
                    "John": {"name": "John", "age": 35},
                    "Elizabeth": {"name": "Elizabeth", "age": 23}
                  }, "name": "Dominik"}
    """

    let dataParsed = parseJson(data)
    let dataDeser = to(dataParsed, Dynamic)
    doAssert dataDeser.name == "Dominik"
    doAssert dataDeser.friends["John"].age == 35
    doAssert dataDeser.friends["Elizabeth"].age == 23

  # JsonNode support
  block:
    type
      Test = object
        name: string
        fallback: JsonNode

    let data = """
      {"name": "FooBar", "fallback": 56.42}
    """

    let dataParsed = parseJson(data)
    let dataDeser = to(dataParsed, Test)
    doAssert dataDeser.name == "FooBar"
    doAssert dataDeser.fallback.kind == JFloat
    doAssert dataDeser.fallback.getFloat() == 56.42

  # int64, float64 etc support.
  block:
    type
      Test1 = object
        a: int8
        b: int16
        c: int32
        d: int64
        e: uint8
        f: uint16
        g: uint32
        h: uint64
        i: float32
        j: float64

    let data = """
      {"a": 1, "b": 2, "c": 3, "d": 4, "e": 5, "f": 6, "g": 7,
       "h": 8, "i": 9.9, "j": 10.10}
    """

    let dataParsed = parseJson(data)
    let dataDeser = to(dataParsed, Test1)
    doAssert dataDeser.a == 1
    doAssert dataDeser.f == 6
    doAssert dataDeser.i == 9.9'f32
  
  # deserialize directly into a table
  block:
    let s = """{"a": 1, "b": 2}"""
    let t = parseJson(s).to(Table[string, int])
    doAssert t["a"] == 1
    doAssert t["b"] == 2