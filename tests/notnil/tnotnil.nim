discard """
  line: 13
  errormsg: "type mismatch"
"""
{.experimental: "notnil".}
type
  PObj = ref TObj not nil
  TObj = object
    x: int

proc q2(x: string) = discard

q2(nil)
