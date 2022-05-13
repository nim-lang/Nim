discard """
  matrix: "--gc:arc"
  errormsg: "expression cannot be cast to int"
"""

block: # bug #16558
  var value = "hi there"
  var keepInt: int
  keepInt = cast[int](value)
