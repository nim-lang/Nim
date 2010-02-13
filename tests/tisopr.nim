# Test is operator

type
  TMyType = object
    len: int
    data: string
    
  TOtherType = object of TMyType
   
proc p(x: TMyType): bool = 
  return x is TOtherType
    
var
  m: TMyType
  n: TOtherType

write(stdout, p(m))
write(stdout, p(n))

#OUT falsetrue
