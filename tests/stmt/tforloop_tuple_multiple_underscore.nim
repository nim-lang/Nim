discard """
  errormsg: "the special identifier '_' is ignored in declarations and cannot be used"
"""

iterator iter(): (int, int, int) =
  yield (1, 1, 2)


for (_, i, _) in iter():
  echo _
