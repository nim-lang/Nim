discard """
  output: '''@[1]
@[1, 1]
@[1, 2, 1]
@[1, 3, 3, 1]
@[1, 4, 6, 4, 1]
@[1, 5, 10, 10, 5, 1]
@[1, 6, 15, 20, 15, 6, 1]
@[1, 7, 21, 35, 35, 21, 7, 1]
@[1, 8, 28, 56, 70, 56, 28, 8, 1]
@[1, 9, 36, 84, 126, 126, 84, 36, 9, 1]'''
"""

import sequtils

proc pascal(n: int) =
  var row = @[1]
  for r in 1..n:
    echo row
    row = zip(row & @[0], @[0] & row).mapIt(it[0] + it[1])

pascal(10)

# bug #3499 last snippet fixed
# bug 705  last snippet fixed
