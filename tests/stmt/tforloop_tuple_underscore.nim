discard """
  errormsg: "the special identifier '_' is ignored in declarations and cannot be used"
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

