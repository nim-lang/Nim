discard """
  line: 6
  errormsg: "'ugh' cannot have 'closure' calling convention"
"""

proc ugh[T](x: T) {.closure.} =
  echo "ugha"
