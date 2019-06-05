discard """
  output: '''true
true
true
true
true
true
'''
"""

# issue #7615
import macros

template table(name: string) {.pragma.}

type
   User {.table("tuser").} = object
      id: int
      name: string
      age: int

echo User.hasCustomPragma(table)


## crash: Error: internal error: (filename: "sempass2.nim", line: 560, column: 19)
macro m1(T: typedesc): untyped =
  getAST hasCustomPragma(T, table)
echo m1(User) # Oops crash


## This works
macro m2(T: typedesc): untyped =
  result = quote do:
    `T`.hasCustomPragma(table)
echo m2(User)



block:
  template noserialize() {.pragma.}

  type
    Point[T] = object
      x, y: T

    ReplayEventKind = enum
      FoodAppeared, FoodEaten, DirectionChanged

  # ref #11415
  # this works, since `foodPos` is inside of a variant kind with a
  # single `of` element
  block:
    type
      ReplayEvent = object
        time: float
        pos {.noserialize.}: Point[float] # works before fix
        case kind: ReplayEventKind
        of FoodEaten:
          foodPos {.noserialize.}: Point[float] # also works, only in one branch
        of DirectionChanged, FoodAppeared:
          playerPos: float

    let ev = ReplayEvent(
        pos: Point[float](x: 5.0, y: 1.0),
        time: 1.2345,
        kind: FoodEaten,
        foodPos: Point[float](x: 5.0, y: 1.0)
      )
    echo ev.pos.hasCustomPragma(noserialize)
    echo ev.foodPos.hasCustomPragma(noserialize)

  # ref 11415
  # this did not work, since `foodPos` is inside of a variant kind with a
  # two `of` elements
  block:
    type
      ReplayEvent = object
        case kind: ReplayEventKind
        of FoodEaten, FoodAppeared:
          foodPos {.noserialize.}: Point[float] # did not work, because in two branches
        of DirectionChanged:
          playerPos: float

    let ev = ReplayEvent(
        kind: FoodEaten,
        foodPos: Point[float](x: 5.0, y: 1.0)
      )
    echo ev.foodPos.hasCustomPragma(noserialize)
