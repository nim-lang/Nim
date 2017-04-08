import json, macros, strutils

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

var x = Replay(
  events: @[
    ReplayEvent(
      time: 1.2345,
      kind: FoodEaten,
      foodPos: Point[float](x: 5.0, y: 1.0)
    )
  ]
)

let node = %x

echo(node)

let y = to(node, Replay)
doAssert y.events[0].time == 1.2345
doAssert y.events[0].kind == FoodEaten
doAssert y.events[0].foodPos.x == 5.0
doAssert y.events[0].foodPos.y == 1.0
echo(y.repr)