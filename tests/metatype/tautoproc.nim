discard """
  errormsg: "expression 'generate(builder)' has no type (or is ambiguous)"
"""

# bug #898

proc measureTime(e: auto) =
  discard

proc generate(a: int): void =
  discard

proc runExample =
  var builder: int = 0

  measureTime:
    builder.generate()

measureTime:
  discard
