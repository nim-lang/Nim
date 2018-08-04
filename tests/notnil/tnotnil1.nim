discard """
  errormsg: "'y' is provably nil"
  line:38
"""

import strutils
{.experimental: "notnil".}

type
  TObj = object
    x, y: int

type
  superstring = string not nil


proc q(s: superstring) =
  echo s

proc p2() =
  var a: string = "I am not nil"
  q(a) # but this should and does not

p2()

proc q(x: pointer not nil) =
  discard

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
