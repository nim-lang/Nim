discard """
  errormsg: "'y' is provably nil"
  line:25
"""

import strutils


type
  TObj = object
    x, y: int

proc q(x: pointer not nil) =
  nil

proc p() =
  var x: pointer
  if not x.isNil:
    q(x)
  
  let y = x
  if not y.isNil:
    q(y)
  else:
    q(y)

p()
