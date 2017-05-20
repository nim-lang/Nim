discard """
  nimout: "type uint32\ntype uint32"
  output: "(weight: 17.0, color: 100)"
"""

import macros

type
  BaseFruit[T] = object of RootObj
    color: T

  Banana[T] = object of BaseFruit[uint32]
    weight: T

macro printTypeName(typ: typed): untyped =
  echo "type ", getType(typ).repr

proc setColor[K](self: var BaseFruit[K], c: int) =
  printTypeName(self.color)
  self.color = uint32(c)

var x: Banana[float64]
x.weight = 17
printTypeName(x.color)
x.setColor(100)
echo x

