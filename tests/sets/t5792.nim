discard """
  matrix: "--gc:refc; --gc:arc"
"""

type
  T = enum
    a
    b
    c
  U = object
    case k: T
    of a:
      x: int
    of {b, c} - {a}:
      y: int

doAssert U(k: b, y: 1).y == 1
