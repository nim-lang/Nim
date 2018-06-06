
converter FloatConversion64(x: int): float64 = return toFloat(x)
converter FloatConversion32(x: int): float32 = return toFloat(x)
converter FloatConversionPlain(x: int): float = return toFloat(x)

const width = 500
const height = 500

proc ImageSurfaceCreate(w, h: float) = discard

ImageSurfaceCreate(width, height)

type TFoo = object

converter toPtr*(some: var TFoo): ptr TFoo = (addr some)


proc zoot(x: ptr TFoo) = discard
var x: Tfoo
zoot(x)
