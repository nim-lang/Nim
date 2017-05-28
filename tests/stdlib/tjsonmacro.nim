discard """
  file: "tjsonmacro.nim"
  output: ""
"""
import json, strutils

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
    doAssert result.age == node["age"].getNum().uint8
    doAssert result.other == node["other"].getNum()

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