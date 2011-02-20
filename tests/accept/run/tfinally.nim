discard """
  file: "tfinally.nim"
  output: "came here 3"
"""
# Test return in try statement:

proc main: int = 
  try:
    try:
      return 1
    finally:
      stdout.write("came ")
      return 2
  finally: 
    stdout.write("here ")
    return 3
    
echo main() #OUT came here 3



