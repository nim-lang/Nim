
type
  TA = object
    x, y: int
  
  TB = object of TA
    z: int
    
  TC = object of TB
    whatever: string
  
proc p(a: var TA) = nil
proc p(b: var TB) = nil

var c: TC

p(c)

