discard """
  file: "tcountup.nim"
  output: "0123456789"
"""

# Test new countup and unary < 

for i in 0 .. < 10'i64: 
  stdout.write(i)
  
#OUT 0123456789



