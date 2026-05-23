discard """
  errormsg: "expression has no address"
"""

iterator foo(x: int): (lent int, lent int) =
  yield (x, x + 1)


var x = 12
for i in foo(x):
  echo i[0]
  echo i[1]
