##[
This testcase checks borrowing the field access operator via a type pragma.
]##

type
  Point = object
    x: int

  DistinctPoint {.borrow: `.`.} = distinct Point

block:
  let point = DistinctPoint(Point(x: 1))
  doAssert point.x == 1
