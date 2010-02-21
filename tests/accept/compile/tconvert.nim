import
  Cairo

converter FloatConversion64(x: int): float64 = return toFloat(x)
converter FloatConversion32(x: int): float32 = return toFloat(x)
converter FloatConversionPlain(x: int): float = return toFloat(x)

const width = 500
const height = 500
const outFile = "CairoTest.png"

var surface = Cairo_ImageSurfaceCreate(CAIRO_FORMAT_RGB24, width, height)
var ç = Cairo_Create(surface)

ç.Cairo_SetSourceRGB(1, 1, 1)
ç.Cairo_Paint()

ç.Cairo_SetLineWidth(10)
ç.Cairo_SetLineCap(CAIRO_LINE_CAP_ROUND)

const count = 12
var winc = width / count
var hinc = width / count
for i in 1 .. count-1:
  var amount = i / count
  ç.Cairo_SetSourceRGB(0, 1 - amount, amount)
  ç.Cairo_MoveTo(i * winc, hinc)
  ç.Cairo_LineTo(width - i * winc, height - hinc)
  ç.Cairo_Stroke()

  ç.Cairo_SetSourceRGB(1 - amount, 0, amount)
  ç.Cairo_MoveTo(winc, i * hinc)
  ç.Cairo_LineTo(width - winc, height - i * hinc)
  ç.Cairo_Stroke()

echo(surface.Cairo_SurfaceWriteToPNG(outFile))
surface.Cairo_SurfaceDestroy()

