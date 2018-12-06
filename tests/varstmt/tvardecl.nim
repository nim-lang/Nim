discard """
  output: "44"
"""
# Test the new variable declaration syntax

var
  x = 0
  s = "Hallo"
  a, b: int = 4

write(stdout, a)
writeLine(stdout, b) #OUT 44
