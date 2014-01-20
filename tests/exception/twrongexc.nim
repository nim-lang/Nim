discard """
  file: "twrongexc.nim"
  outputsub: "Error: unhandled exception:  [EInvalidValue]"
  exitcode: "1"
"""
try:
  raise newException(EInvalidValue, "")
except EOverflow:
  echo("Error caught")
  



