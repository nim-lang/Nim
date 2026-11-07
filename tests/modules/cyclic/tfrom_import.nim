discard """
  joinable: false
  output: '''
2 green 11 3
true false 7
'''
"""

# `from m {.cyclic.} import x`: `x` is not declared yet when the imports of
# the group run, it is imported once `m` declared it.
from forms/mfrom_import {.cyclic.} import fb, Color, toInt, B

type
  A* = object
    b*: B

proc fa*(): int = 1

let i: int = green # the converter and the enum's fields are imported too
echo fb(), " ", green, " ", i, " ", A(b: B(x: 3)).b.x
echo compiles(fb()), " ", compiles(hidden()), " ", mfrom_import.hidden()
