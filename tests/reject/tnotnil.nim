discard """
  line: 11
  errormgs: "type mismatch"
"""

type
  PObj = ref TObj not nil
  TObj = object
    x: int

var x: PObj = nil

proc p(x: string not nil): int =
  result = 45

