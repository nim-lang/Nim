discard """
  matrix: "--mm:refc; --mm:orc"
"""

# bug #26687: in place construction must not be observable
type
  O2 = object
    a, b: int
  F = object
    b: array[65536, byte]
    d: int

var gF: F
proc g(): int = gF.d
func m(x: int): int =
  if x < 0: raise newException(ValueError, "neg")
  x

proc p(w: var F) = w = F(d: g())
proc v(w: var F, x: var int) = w = F(d: x)
proc c(w: var F) =
  let cl = proc(): int = gF.d
  w = F(d: cl())
proc e(w: var O2, x: int) = w = O2(a: 1, b: m(x))

proc z() =
  gF.d = 42; p(gF); doAssert gF.d == 42
  let f = new F
  f.d = 11; v(f[], f.d); doAssert f.d == 11
  gF.d = 42; c(gF); doAssert gF.d == 42
  var o = O2(a: 13, b: 13)
  (try: e(o, -1) except ValueError: discard); doAssert o == O2(a: 13, b: 13)

z()
