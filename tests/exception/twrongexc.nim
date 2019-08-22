discard """
  outputsub: "Error: unhandled exception:  [ValueError]"
  exitcode: "1"
"""
try:
  raise newException(ValueError, "")
except OverflowError:
  echo("Error caught")
