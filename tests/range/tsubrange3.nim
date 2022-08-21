discard """
  outputsub: "value out of range: 50 notin 0 .. 40 [RangeDefect]"
  exitcode: "1"
"""

type
  TRange = range[0..40]

proc p(r: TRange) =
  discard

var
  r: TRange
  y = 50
r = y

#p y
