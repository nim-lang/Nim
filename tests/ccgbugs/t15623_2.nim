discard """
  output: '''0
0
'''
"""

# bug #15623
block:
  echo cast[int](cast[ptr int](nil))

block:
  var x: ref int = nil
  echo cast[int](cast[ptr int](x))
