discard """
  line: 20
  errormsg: "type mismatch: got <int literal(60)> but expected 'TRange = range 0..40(int)'"
"""

type
  TRange = range[0..40]

proc p(r: TRange) =
  discard

var
  r: TRange
  y = 50
r = y

p y

const
  myConst: TRange = 60

