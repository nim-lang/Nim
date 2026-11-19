type
  Point* = object
    x*: int
  Other* = object
    x*: int

proc newPoint*(): Point = Point(x: 1)
