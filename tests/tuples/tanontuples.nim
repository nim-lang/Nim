discard """
  output: '''61, 125
(Field0: 0) (Field0: 13)'''
"""

import macros

proc `^` (a, b: int): int =
  result = 1
  for i in 1..b: result = result * a

var m = (0, 5)
var n = (56, 3)

m = (n[0] + m[1], m[1] ^ n[1])

echo m[0], ", ", m[1]

# also test we can produce unary anon tuples in a macro:
macro mm(): untyped =
  result = newTree(nnkTupleConstr, newLit(13))

proc nowTuple(): (int,) =
  result = (0,)

echo nowTuple(), " ", mm()
