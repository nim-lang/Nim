import
  Cairo

converter FloatConversion64(x: int): float64 = return toFloat(x)
converter FloatConversion32(x: int): float32 = return toFloat(x)
converter FloatConversionPlain(x: int): float = return toFloat(x)

const width = 500
const height = 500
const outFile = "CairoTest.png"

var surface = Cairo.ImageSurfaceCreate(CAIRO.FORMAT_RGB24, width, height)
var ç = Cairo.Create(surface)

ç.SetSourceRGB(1, 1, 1)
ç.Paint()

ç.SetLineWidth(10)
ç.SetLineCap(CAIRO.LINE_CAP_ROUND)

const count = 12
var winc = width / count
var hinc = width / count
for i in 1 .. count-1:
  var amount = i / count
  ç.SetSourceRGB(0, 1 - amount, amount)
  ç.MoveTo(i * winc, hinc)
  ç.LineTo(width - i * winc, height - hinc)
  ç.Stroke()

  ç.SetSourceRGB(1 - amount, 0, amount)
  ç.MoveTo(winc, i * hinc)
  ç.LineTo(width - winc, height - i * hinc)
  ç.Stroke()

echo(surface.WriteToPNG(outFile))
surface.Destroy()

type TFoo = object

converter toPtr*(some: var TFoo): ptr TFoo = (addr some)


proc zoot(x: ptr TFoo) = nil
var x: Tfoo
zoot(x)
