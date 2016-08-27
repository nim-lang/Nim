discard """
  errormsg: "invalid context for '^' as 'foo()' has side effects"
  line: "9"
"""
# XXX This needs to be fixed properly!
proc foo(): seq[int] {.sideEffect.} =
  echo "ha"

let f = foo()[^1]

