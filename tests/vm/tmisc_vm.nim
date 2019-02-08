discard """
  output: '''[127, 127, 0, 255]
[127, 127, 0, 255]
'''

  nimout: '''caught Exception'''
"""

#bug #1009
type
  TAggRgba8* = array[4, byte]

template R*(self: TAggRgba8): byte = self[0]
template G*(self: TAggRgba8): byte = self[1]
template B*(self: TAggRgba8): byte = self[2]
template A*(self: TAggRgba8): byte = self[3]

template `R=`*(self: TAggRgba8, val: byte) =
  self[0] = val
template `G=`*(self: TAggRgba8, val: byte) =
  self[1] = val
template `B=`*(self: TAggRgba8, val: byte) =
  self[2] = val
template `A=`*(self: TAggRgba8, val: byte) =
  self[3] = val

proc ABGR*(val: int| int64): TAggRgba8 =
  var V = val
  result.R = byte(V and 0xFF)
  V = V shr 8
  result.G = byte(V and 0xFF)
  V = V shr 8
  result.B = byte(V and 0xFF)
  result.A = byte((V shr 8) and 0xFF)

const
  c1 = ABGR(0xFF007F7F)
echo ABGR(0xFF007F7F).repr, c1.repr


# bug 8740

static:
  try:
    raise newException(ValueError, "foo")
  except Exception:
    echo "caught Exception"
  except Defect:
    echo "caught Defect"
  except ValueError:
    echo "caught ValueError"

# bug #10538

block:
  proc fun1(): seq[int] =
    try:
      try:
        result.add(1)
        return
      except:
        result.add(-1)
      finally:
        result.add(2)
    finally:
      result.add(3)
    result.add(4)

  let x1 = fun1()
  const x2 = fun1()
  doAssert(x1 == x2)
