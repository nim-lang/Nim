discard """
  errormsg: "type mismatch"
  line: 16
"""

type
  TCallback = proc (a, b: int)

proc huh(x, y: var int) =
  x = 0
  y = x+1

proc so(c: TCallback) =
  c(2, 4)

so(huh)
