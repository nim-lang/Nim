discard """
  errormsg: "type mismatch"
  line: 12
"""

type
  Light = object
    case
    of Red: duration: int
    of Off: discard
proc Off(x: int): int = x + 1
discard Off("x")
