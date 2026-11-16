discard """
  errormsg: "no generic parameters allowed for Y"
"""

# bug #14478
type
  X = ref object
    child: Y[int]
  
  Y = object
    x: X

var x = Y(x: nil)
