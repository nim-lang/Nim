discard """
  errormsg: "cannot convert 60 to TRange"
  line: 20
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
