discard """
  file: "tfinally.nim"
  output: "came\nhere\n3"
"""
# Test return in try statement:

proc main: int = 
  try:
    try:
      return 1
    finally:
      echo("came")
      return 2
  finally: 
    echo("here")
    return 3

echo main() #OUT came here 3

