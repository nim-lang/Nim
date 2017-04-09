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

