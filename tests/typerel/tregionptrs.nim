discard """
  errormsg: "type mismatch: got <BPtr> but expected 'APtr = ptr[RegionA, int]'"
  line: 16
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
