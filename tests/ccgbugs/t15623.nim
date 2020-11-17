discard """
  action: "compile"
"""

# bug #15623
block:
  echo cast[ptr int](nil)[]

block:
  var x: ref int = nil
  echo cast[ptr int](x)[]
