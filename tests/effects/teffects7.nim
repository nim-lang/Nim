discard """
  errormsg: "can raise an unlisted exception: ref ValueError"
  line: 10
"""
{.push warningAsError[Effect]: on.}
proc foo() {.raises: [].} =
  try:
    discard
  except KeyError:
    raise newException(ValueError, "foo")
  except Exception:
    discard

foo()

{.pop.}
