discard """
  errormsg: "invalid indentation"
  line: 24
"""

import macros

# finally optional indentation in 'if' expressions :-):
var x = if 4 != 5:
    "yes"
  else:
    "no"

macro mymacro(n, b): untyped =
  discard

mymacro:
  echo "test"
else:
  echo "else part"

if 4 == 3:
  echo "bug"
  else:
  echo "no bug"
