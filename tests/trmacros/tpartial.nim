discard """
  output: '''-2'''
"""

proc p(x, y: int; cond: bool): int =
  result = if cond: x + y else: x - y

template optP{p(x, y, true)}(x, y): untyped = x - y
template optP{p(x, y, false)}(x, y): untyped = x + y

echo p(2, 4, true)
