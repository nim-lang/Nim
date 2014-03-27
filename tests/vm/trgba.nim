discard """
  output: '''[127, 127, 0, 255]
[127, 127, 0, 255]
'''
"""

#bug #1009
type
  TAggRgba8* = array[4, byte]

template R*(self: TAggRgba8): Byte = self[0]   
template G*(self: TAggRgba8): Byte = self[1]   
template B*(self: TAggRgba8): Byte = self[2]   
template A*(self: TAggRgba8): Byte = self[3]   

template `R=`*(self: TAggRgba8, val: Byte) = 
  self[0] = val   
template `G=`*(self: TAggRgba8, val: Byte) =   
  self[1] = val   
template `B=`*(self: TAggRgba8, val: Byte) =   
  self[2] = val   
template `A=`*(self: TAggRgba8, val: Byte) =   
  self[3] = val   

proc ABGR* (val: int| int64): TAggRgba8 =
  var V = val
  result.R = V and 0xFF
  V = V shr 8
  result.G = V and 0xFF
  V = V shr 8
  result.B = V and 0xFF
  result.A = (V shr 8) and 0xFF

const
  c1 = ABGR(0xFF007F7F) 
echo ABGR(0xFF007F7F).repr, c1.repr
