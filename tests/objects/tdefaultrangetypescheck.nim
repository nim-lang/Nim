discard """
  errormsg: "cannot convert 0 to range 1..5(int)"
  line: 9
"""

type
  Point = object
    y: int
    x: range[1..5] = 0

echo default(Point)
