discard """
  errormsg: "undeclared identifier: '_'"
"""

iterator iter(): (int, int) =
  yield (1, 2)
  yield (3, 4)
  yield (1, 2)
  yield (3, 4)
  yield (1, 2)
  yield (3, 4)


for (_, i) in iter():
  echo _

