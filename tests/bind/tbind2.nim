discard """
  errormsg: "ambiguous call"
  file: "tbind2.nim"
  line: 12
"""
# Test the new ``bind`` keyword for templates

proc p1(x: int8, y: int): int = return x + y
proc p1(x: int, y: int8): int = return x - y

template tempBind(x, y): untyped =
  (bind p1(x, y))  #ERROR_MSG ambiguous call

echo tempBind(1'i8, 2'i8)
