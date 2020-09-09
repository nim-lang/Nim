discard """
  errormsg: "type mismatch"
  line: 13
"""
{.experimental: "strictNotNil".}

type
  PObj = ref TObj not nil
  TObj = object
    x: int

proc q2(x: string) = discard

q2(nil)
