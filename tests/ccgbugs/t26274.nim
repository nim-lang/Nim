discard """
  matrix: "--mm:refc; --mm:orc"
  ccodecheck: "\\i !@('ty' ('Object_F' / 'Tuple' / 'Array') [a-zA-Z0-9_]* \\s+ 'T' [0-9]+ '_;')"
"""

# bug #26274: constructors whose elements cannot read the destination are
# built directly in it, without a (potentially huge) stack temporary.
type
  F = object
    b: array[24576, byte]
    d: int
  R = ref object
    x: int
    f: F
  T = (array[24576, byte], int)
  A = array[4, int]

var g = 3

func inc1(x: int): int = x + 1

proc p(w: var F, x: int) = w = F(d: x)

proc local(w: var F) =
  # a local cannot be reached through a var parameter
  let y = w.d
  w = F(d: inc1(y))

proc toLocal(o: R; y: var F): int =
  # neither a ref nor a var parameter can point to a local
  var loc: F
  loc = F(d: o.x + y.d)
  result = loc.d

proc heap(o: R) =
  # a ref cannot point to a global
  o.f = F(d: g + 1)

proc tup(w: var T; x: int) = w = (default(array[24576, byte]), x)

proc arr(w: var A; x: int) = w = [x, x, x, x]

var s: F
s.b[0] = 42
p(s, 1)
doAssert s.b[0] == 0
doAssert s.d == 1
local(s)
doAssert s.d == 2
doAssert toLocal(R(x: 1), s) == 3
let o = R()
heap(o)
doAssert o.f.d == 4
var t: T
tup(t, 5)
doAssert t[1] == 5
var a: A
arr(a, 6)
doAssert a == [6, 6, 6, 6]
