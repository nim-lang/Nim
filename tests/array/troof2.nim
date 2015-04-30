discard """
  errormsg: "invalid context for '^' as 'foo()' has side effects"
  line: "9"
"""

proc foo(): seq[int] =
  echo "ha"

let f = foo()[^1]

