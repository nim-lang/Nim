discard """
  errormsg: "can raise an unlisted exception: ref FloatingPointError"
  line: 10
"""

proc foo() {.raises: [].} =
  try:
    discard
  except KeyError:
    raise newException(FloatingPointError, "foo")
  except Exception:
    discard

foo()
