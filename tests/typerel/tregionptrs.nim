discard """
  line: 16
  errormsg: "type mismatch: got <BPtr> but expected 'APtr = ptr[RegionA, int]'"
"""

type
  RegionA = object
  APtr = RegionA ptr int
  RegionB = object
  BPtr = RegionB ptr int

var x,xx: APtr
var y: BPtr
x = nil
x = xx
x = y
