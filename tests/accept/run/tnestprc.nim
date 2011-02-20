discard """
  file: "tnestprc.nim"
  output: "10"
"""
# Test nested procs without closures

proc Add3(x: int): int = 
  proc add(x, y: int): int {.noconv.} = 
    result = x + y
    
  result = add(x, 3)
  
echo Add3(7) #OUT 10



