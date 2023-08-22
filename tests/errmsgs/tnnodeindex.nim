discard """
  errormsg: "index 5 not in 0 .. 2"
  line: 7
"""
import macros
macro t(x: untyped): untyped =
  result = x[5]
t([1, 2, 3])
