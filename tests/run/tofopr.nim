discard """
  file: "tofopr.nim"
  output: "falsetrue"
"""
# Test is operator

type
  TMyType = object {.inheritable.}
    len: int
    data: string
    
  TOtherType = object of TMyType
   
proc p(x: TMyType): bool = 
  return x of TOtherType
    
var
  m: TMyType
  n: TOtherType

write(stdout, p(m))
write(stdout, p(n))

#OUT falsetrue


