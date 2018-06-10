discard """
  line: 20
  errormsg: "cannot convert 60 to TRange"
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

