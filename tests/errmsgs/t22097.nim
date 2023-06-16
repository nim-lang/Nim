discard """
  errormsg: "for a 'var' type a variable needs to be passed; but 'uint16(x)' is immutable"
"""

proc toUInt16(x: var uint16) =
  discard

var x = uint8(1)
toUInt16 x