discard """
  errormsg: "ValueError can raise an unlisted exception: ValueError"
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
