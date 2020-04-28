discard """
  errormsg: "can raise an unlisted exception: ref FloatingPointDefect"
  line: 10
"""

proc foo() {.raises: [].} =
  try:
    discard
  except KeyError:
    raise newException(FloatingPointDefect, "foo")
  except Exception:
    discard

foo()
