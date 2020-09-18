discard """
  output: '''(10, (20, ))
42
(x: 900.0, y: 900.0)
(x: 900.0, y: 900.0)
(x: 900.0, y: 900.0)'''
"""

import strutils, sequtils

# bug #668

type
  TThing = ref object
    data: int
    children: seq[TThing]

proc `$`(t: TThing): string =
  result = "($1, $2)" % @[$t.data, join(map(t.children, proc(th: TThing): string = $th), ", ")]

proc somethingelse(): seq[TThing] =
  result = @[TThing(data: 20, children: @[])]

proc dosomething(): seq[TThing] =
  result = somethingelse()

  result = @[TThing(data: 10, children: result)]

echo($dosomething()[0])


# bug #9844

proc f(v: int): int = v

type X = object
  v: int

var x = X(v: 42)

x = X(v: f(x.v))
echo x.v


# bug #11525
type
  Point[T] = object
    x, y: T

proc adjustPos[T](width, height: int, pos: Point[T]): Point[T] =
  result = pos

  result = Point[T](
    x: pos.x - (width / 2),
    y: pos.y - (height / 2)
  )

proc adjustPos2[T](width, height: int, pos: Point[T]): Point[T] =
  result = pos

  result = Point[T](
    x: result.x - (width / 2),
    y: result.y - (height / 2)
  )

proc adjustPos3(width, height: int, pos: Point): Point =
  result = pos

  result = Point(
    x: result.x - (width / 2),
    y: result.y - (height / 2)
  )

echo adjustPos(200, 200, Point[float](x: 1000, y: 1000))
echo adjustPos2(200, 200, Point[float](x: 1000, y: 1000))
echo adjustPos3(200, 200, Point[float](x: 1000, y: 1000))
