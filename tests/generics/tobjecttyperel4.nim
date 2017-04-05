discard """
  msg: '''uint32
uint32
float
uint32
uint32
float'''
  output: '''(weight: 17.0, color: 11)
(weight: 0.0, color: 11.0, width: 17)
0'''
"""
# bug 5570
import macros

type
  BaseFruit[T] = object of RootObj
    color: T

  Banana[T] = object of BaseFruit[uint32]
    weight: T

macro getTypeName(typ: typed): untyped =
  echo getType(typ).repr

proc setColor[K](self: var BaseFruit[K], c: uint32) =
  getTypeName(self.color)
  self.color = c

var x: Banana[float64]
x.weight = 17
getTypeName(x.color)
x.setColor(11)
echo x

type
  BaseCar[T, K] = object of RootObj
    color: T
    width: K

  Wagon[T] = object of BaseCar[T, uint32]
    weight: T

proc setColor[T, K](self: var BaseCar[T, K], c: float) =
  getTypeName(self.color)
  self.color = c

proc setWidth[T, K](self: var BaseCar[T, K], w: uint32) =
  getTypeName(self.width)
  self.width = w

var y: Wagon[float64]
getTypeName(y.color)
getTypeName(y.width)
y.setWidth(17)
y.setColor(11)
echo y

# bug 5602
type
  Foo[T] = object of RootObj
  Bar[T] = object of Foo[seq[T]]

proc p[T](f: Foo[T]): T = discard

var s: Bar[float]
echo p(s).len
