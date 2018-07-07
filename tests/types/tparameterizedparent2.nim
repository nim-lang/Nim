discard """
  output: '''(width: 11, color: 13)
(width: 15, weight: 13, taste: 11, color: 14)
(width: 17, color: 16)
(width: 12.0, taste: "yummy", color: 13)
(width: 0, tast_e: 0.0, kind: Smooth, skin: 1.5, color: 12)'''
"""
# bug #5264
type
  Texture = enum
    Smooth
    Coarse

  FruitBase = object of RootObj
    color: int

  Level2Fruit = object of FruitBase
    taste: int

  AppleBanana = object of Level2Fruit
    weight: int

  BaseFruit[T] = object of RootObj
    color: T

  Apple[T] = object of T
    width: int

  Peach[X, T, Y] = object of T
    width: X
    taste: Y

  Lemon[T] = object of T
    width: int
    tast_e: float64
    case kind: Texture
    of Smooth:
      skin: float64
    of Coarse:
      grain: int

var x: Apple[FruitBase]
x.color = 13
x.width = 11
echo x

proc setColor(self: var FruitBase, c: int) =
  self.color = c

proc setTaste[T](self: var Apple[T], c: int) =
  self.taste = c

#proc setColor[T](self: var BaseFruit[T], c: int) =
#  self.color = c

var y: Apple[AppleBanana]
y.setColor(14)
y.setTaste(11)
y.weight = 13
y.width = 15
echo y

var w: Apple[BaseFruit[int]]
w.width = 17
w.color = 16
echo w

var z: Peach[float64, BaseFruit[int], string]
z.width = 12
z.taste = "yummy"
#z.setColor(13) #this trigger other bug
z.color = 13
echo z

var k = Lemon[FruitBase](kind: Smooth, skin: 1.5)
k.setColor(12)
echo k
