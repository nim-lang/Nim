discard """
  file: "tfinally2.nim"
  output: "ABCD"
"""
# Test break in try statement:

proc main: int = 
  try:
    block AB:
      try:
        try:
          break AB
        finally:
          stdout.write("A")
        stdout.write("skipped")
      finally: 
        block B:
          stdout.write("B")
      stdout.write("skipped")
    stdout.write("C")
  finally:
    stdout.writeln("D")
    
discard main() #OUT ABCD



