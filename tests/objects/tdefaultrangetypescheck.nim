discard """
  errormsg: "conversion from int literal(0) to range 1..5(int) is invalid"
  line: 9
"""

type
  Point = object
    y: int
    x: range[1..5] = 0

echo default(Point)
