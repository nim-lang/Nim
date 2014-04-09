discard """
  line: 16
  errormsg: "type mismatch: got (BPtr) but expected 'APtr'"
"""

type
  RegionA = object
  APtr = ptr[RegionA, int]
  RegionB = object
  BPtr = ptr[RegionB, int]
  
var x,xx: APtr
var y: BPtr
x = nil
x = xx
x = y
