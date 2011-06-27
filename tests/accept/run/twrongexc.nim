discard """
  file: "twrongexc.nim"
  outputsub: "Error: unhandled exception:  [EInvalidValue]"
"""
try:
  raise newException(EInvalidValue, "")
except EOverflow:
  echo("Error caught")
  



