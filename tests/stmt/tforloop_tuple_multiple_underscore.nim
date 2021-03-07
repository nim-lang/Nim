discard """
  errormsg: "undeclared identifier: '_'"
"""

iterator iter(): (int, int, int) =
  yield (1, 1, 2)


for (_, i, _) in iter():
  echo _