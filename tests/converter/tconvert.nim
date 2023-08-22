
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

# issue #6544
converter withVar(b: var string): int = ord(b[1])

block:
  var x = "101"
  var y: int = x # instantiate withVar
  doAssert(y == ord('0'))


######################
# bug #3503
type Foo = object
  r: float

converter toFoo(r: float): Foo =
  result.r = r

proc `+=`*(x: var Foo, r: float) =
  x.r += r

var a: Foo
a.r += 3.0

