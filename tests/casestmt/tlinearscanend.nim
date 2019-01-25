discard """
action: compile
"""

import strutils

var x = 343

case stdin.readline.parseInt
of 0:
  echo "most common case"
of 1:
  {.linearScanEnd.}
  echo "second most common case"
of 2: echo "unlikely: use branch table"
else:
  echo "unlikely too: use branch table"


case x
of 23: echo "23"
of 343: echo "343"
of 21: echo "21"
else:
  {.linearScanEnd.}
  echo "default"
