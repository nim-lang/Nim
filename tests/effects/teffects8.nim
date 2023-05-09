discard """
  errormsg: "can raise an unlisted exception: Exception"
  line: 10
"""
{.push warningAsError[Effect]: on.}
proc foo() {.raises: [].} =
  try:
    discard
  except ValueError:
    raise

foo()
{.pop.}
