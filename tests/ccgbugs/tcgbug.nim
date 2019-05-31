discard """
output: '''
success
M1 M2
'''
"""

type
  TObj = object
    x, y: int
  PObj = ref TObj

proc p(a: PObj) =
  a.x = 0

proc q(a: var PObj) =
  a.p()

var
  a: PObj
new(a)
q(a)

# bug #914
when defined(windows):
  var x = newWideCString("Hello")

echo "success"


# bug #833

type
  PFuture*[T] = ref object
    value*: T
    finished*: bool
    cb: proc (future: PFuture[T]) {.closure.}

var k = PFuture[void]()


##bug #9297
import strutils

type
  MyKind = enum
    M1, M2, M3

  MyObject {.exportc: "ExtObject"} = object
    case kind: MyKind
      of M1: a:int
      of M2: b:float
      of M3: c:cstring

  MyObjectRef {.exportc: "ExtObject2"} = ref object
    case kind: MyKind
      of M1: a:int
      of M2: b:float
      of M3: c:cstring

proc newMyObject(kind: MyKind, val: string): MyObject =
  result = MyObject(kind: kind)

  case kind
    of M1: result.a = parseInt(val)
    of M2: result.b = parseFloat(val)
    of M3: result.c = val

proc newMyObjectRef(kind: MyKind, val: string): MyObjectRef =
  result = MyObjectRef(kind: kind)
  case kind
    of M1: result.a = parseInt(val)
    of M2: result.b = parseFloat(val)
    of M3: result.c = val


echo newMyObject(M1, "2").kind, " ", newMyObjectRef(M2, "3").kind
