discard """
  file: "tsubrange.nim"
  outputsub: "value 50 out of range [EOutOfRange]"
  exitcode: "1"
"""

type
  TRange = range[0..40]
  
proc p(r: TRange) =
  nil
  
var
  r: TRange
  y = 50
r = y

#p y
  
