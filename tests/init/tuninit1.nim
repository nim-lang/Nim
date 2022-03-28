discard """
  nimout: "tuninit1.nim(34, 11) Warning: use explicit initialization of 'y' for clarity [Uninit]"
  action: compile
"""

import strutils

{.warning[Uninit]:on.}

proc p =
  var x, y, z: int
  if stdin.readLine == "true":
    x = 34

    while false:
      y = 999
      break

    while true:
      if x == 12: break
      y = 9999

    try:
      z = parseInt("1233")
    except Exception:
      case x
      of 34: z = 123
      of 13: z = 34
      else: z = 8
  else:
    y = 3444
    x = 3111
    z = 0
  echo x, y, z

p()
