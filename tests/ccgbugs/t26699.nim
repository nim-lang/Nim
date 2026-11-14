discard """
  matrix: "--mm:orc; --mm:refc; --exceptions:setjmp"
"""

# bug #26699: `x = f()` must not corrupt `x` when `f` raises

proc r(): (array[4, int64],) =
  raise new IOError

var k = ([1'i64, 0, 0, 0],)
try:
  k = r()
except IOError:
  discard
doAssert k == ([1'i64, 0, 0, 0],)

type
  BigT = array[16, int]

proc p(raiseAt: int): BigT =
  for i in 0..high(result):
    if i == raiseAt: raise newException(ValueError, "interception")
    result[i] = i

proc main =
  var x: BigT
  x[0] = 42
  try:
    x = p(8)
  except ValueError:
    doAssert x[0] == 42
    doAssert x[1] == 0
  x = p(-1)
  doAssert x[15] == 15

main()

proc viaVar(x: var BigT) =
  x = p(3)

var g: BigT
g[5] = 7
try:
  viaVar(g)
except ValueError:
  discard
doAssert g[5] == 7
doAssert g[1] == 0

type Obj = object
  a: BigT
  s: string

proc mkObj(raiseIt: bool): Obj =
  result.s = "partial"
  if raiseIt: raise newException(ValueError, "x")
  result.a[0] = 1

var o = Obj(s: "orig")
try:
  o = mkObj(true)
except ValueError:
  discard
doAssert o.s == "orig"
o = mkObj(false)
doAssert o.s == "partial" and o.a[0] == 1
