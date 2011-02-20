discard """
  file: "twrongexc.nim"
  output: "Error: unhandled exception [EInvalidValue]"
"""
try:
  raise newException(EInvalidValue, "")
except EOverflow:
  echo("Error caught")
  



