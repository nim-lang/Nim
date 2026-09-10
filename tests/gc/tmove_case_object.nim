discard """
  matrix: "--mm:refc; --mm:orc"
"""

type
  A = object of RootObj

  V = object
    case g: bool
    of true:
      v: A
    of false:
      e: string

var r = V(g: true, v: A())
discard move r
GC_fullCollect()

type
  Kind = enum nested, other
  Nested = object
    case kind: Kind
    of nested:
      case enabled: bool
      of true: payload: A
      of false: message: string
    of other:
      discard

var n = Nested(kind: nested, enabled: true, payload: A())
discard move n
GC_fullCollect()

# Moving from the other branch must keep its value alive and leave the source
# in the default state.
var s = V(g: false, e: "hello")
let moved = move s
doAssert moved.e == "hello"
doAssert not s.g
doAssert s.e.len == 0

# Reinitializing the zeroed value must also restore embedded object type
# headers.
type W = object
  a: A
  value: V
  text: string

var w = W(a: A(), value: V(g: true, v: A()), text: "content")
let movedW = move w
doAssert movedW.text == "content"
doAssert cast[ptr pointer](addr w.a)[] != nil
doAssert not w.value.g
doAssert w.value.e.len == 0
doAssert w.text.len == 0
GC_fullCollect()
