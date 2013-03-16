discard """
  file: "tfinally3.nim"
  output: "false"
"""
# Test break in try statement:

proc main: bool = 
  while true:
    try:
      return true
    finally:
      break
  return false

echo main() #OUT false



