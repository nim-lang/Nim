# bug #554, #179

type T[E] =
  ref object
    elem: E

var ob: T[int]

ob = T[int](elem: 23)

doAssert ob.elem == 23

type
  TTreeIteratorA* {.inheritable.} = ref object

  TKeysIteratorA* = ref object of TTreeIteratorA  #compiles

  TTreeIterator* [T,D] {.inheritable.} = ref object

  TKeysIterator* [T,D] = ref object of TTreeIterator[T,D]  #this not

var
  it: TKeysIterator[int, string] = nil

#bug #5521
type
  Texture = enum
    Smooth
    Coarse

  FruitBase = object of RootObj
    color: int
    case kind: Texture
    of Smooth:
      skin: float64
    of Coarse:
      grain: int

  Apple = object of FruitBase
    width: int
    taste: float64

var x = Apple(kind: Smooth, skin: 1.5)
var u = x.skin

doAssert u == 1.5

type
  BaseRef {.inheritable, pure.} = ref object
    baseRef: int

  SubRef = ref object of BaseRef

  BasePtr {.inheritable, pure.} = ptr object
    basePtr: int
  SubPtr = ptr object of BasePtr

  BaseObj {.inheritable, pure.} = object
    baseObj: int

  SubObj = object of BaseObj

template baseObj[T](t: ptr T): untyped = T

proc something123(): int =
  var r : SubRef
  r.new
  var p : SubPtr
  p = create(baseObj(p))
  var r2 : ref BaseObj
  r2.new

  var accu = 0
  # trigger code generation
  accu += r.baseRef
  accu += p.basePtr
  accu += r2.baseObj

  doAssert sizeof(r[]) == sizeof(int)
  doAssert sizeof(baseObj(p)) == sizeof(int)
  doAssert sizeof(r2[]) == sizeof(int)

discard something123()
