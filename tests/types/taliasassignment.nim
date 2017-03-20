discard """
  output: '''19
(c: 0)
(c: 13)
@[(c: 11)]
@[(c: 17)]'''
"""
# bug #5238

type
  Rgba8 = object
    c: int
  BlenderRgb*[ColorT] = object

template getColorType*[C](x: typedesc[BlenderRgb[C]]): typedesc = C

type
  ColorT = getColorType(BlenderRgb[int])

proc setColor(c: var ColorT) =
  c = 19

var n: ColorT
n.setColor()
echo n

type
  ColorType = getColorType(BlenderRgb[Rgba8])

var x: ColorType
echo x

proc setColor(c: var ColorType) =
  c = Rgba8(c: 13)

proc setColor(c: var seq[ColorType]) =
  c[0] = Rgba8(c: 11)

proc setColorArray(c: var openArray[ColorType]) =
  c[0] = Rgba8(c: 17)

x.setColor()
echo x

var y = @[Rgba8(c:15)]
y.setColor()
echo y

y.setColorArray()
echo y