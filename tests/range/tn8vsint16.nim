discard """
  output: '''-9'''
"""

type
  n32 = range[0..high(int)]
  n8* = range[0'i8..high(int8)]

proc `+`*(a: n32, b: n32{nkIntLit}): n32 = discard

proc `-`*(a: n8, b: n8): n8 = n8(system.`-`(a, b))

var x, y: n8
var z: int16

# ensure this doesn't call our '-' but system.`-` for int16:
echo z - n8(9)

