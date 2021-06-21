discard """
  errormsg: "can raise an unlisted exception: Exception"
  line: 10
"""

proc foo() {.raises: [].} =
  try:
    discard
  except ValueError:
    raise

foo()
