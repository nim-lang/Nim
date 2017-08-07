discard """
  line: 24
  errormsg: "expression expected, but found 'keyword else'"
"""

import macros

# finally optional indentation in 'if' expressions :-):
var x = if 4 != 5:
    "yes"
  else:
    "no"

macro mymacro(n): untyped {.immediate.} =
  discard

mymacro:
  echo "test"
else:
  echo "else part"

if 4 == 3:
  echo "bug"
  else:
  echo "no bug"
