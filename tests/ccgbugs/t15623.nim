discard """
  action: "compile"
"""

block:
  echo cast[ptr int](nil)[]

block:
  var x: ref int = nil
  echo cast[ptr int](x)[]
