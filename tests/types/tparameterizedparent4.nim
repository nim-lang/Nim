discard """
  errormsg: "attempt to redefine: 'grain'"
  file: "tparameterizedparent4.nim"
  line: 23
"""
# bug #5264
type
  Texture = enum
    Smooth
    Coarse

  FruitBase = object of RootObj
    color: int
    grain: string

  Apple[T] = object of T
    width: int
    tast_e: float64
    case kind: Texture
    of Smooth:
      skin: float64
    of Coarse:
      grain: int

proc setColor(self: var FruitBase, c: int) =
  self.color = c

var x = Apple[FruitBase](kind: Smooth, skin: 1.5)
x.setColor(14)
echo x
