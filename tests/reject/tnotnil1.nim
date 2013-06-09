discard """
  errormsg: "'y' is provably nil"
  line:22
"""

import strutils


type
  TObj = object
    x, y: int

proc q(x: pointer not nil) =
  nil

proc p() =
  var x: pointer
  let y = x
  if not y.isNil:
    q(y)
  else:
    q(y)

p()
