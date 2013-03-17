discard """
  output: "b"
"""

type
  TA = object of TObject
    x, y: int
  
  TB = object of TA
    z: int
    
  TC = object of TB
    whatever: string
  
proc p(a: var TA) = echo "a"
proc p(b: var TB) = echo "b"

var c: TC

p(c)

