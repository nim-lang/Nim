discard """
  errormsg: "ambiguous call"
  file: "told_bind_expr.nim"
  line: 13
"""

# Pre-0.9 deprecated bind expression syntax

proc p1(x: int8, y: int): int = return x + y
proc p1(x: int, y: int8): int = return x - y

template tempBind(x, y): untyped =
  (bind p1(x, y))  #ERROR_MSG ambiguous call

echo tempBind(1'i8, 2'i8)
