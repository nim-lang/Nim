discard """
  targets: "c cpp"
  matrix: "--gc:refc; --gc:arc"
"""

# bug #1833
iterator myitems*[T](a: var seq[T]): var T {.inline.} =
  ## iterates over each item of `a` so that you can modify the yielded value.
  var i = 0
  let L = len(a)
  while i < L:
    yield a[i]
    inc(i)
    doAssert(len(a) == L, "the length of the seq changed while iterating over it")

# Works fine
var xs = @[1,2,3]
for x in myitems(xs):
  inc x

# Tuples don't work
var ys = @[(1,"a"),(2,"b"),(3,"c")]
for y in myitems(ys):
  inc y[0]

# bug #16331
type T1 = tuple[a, b: int]

proc p(b: bool): string =
  var x: T1 = (10, 20)
  x = if b: (x.b, x.a) else: (-x.b, -x.a)
  $x

assert p(false) == "(a: -20, b: -10)"
assert p(true) == "(a: 20, b: 10)"
