discard """
  targets: "c cpp"
  matrix: "--mm:refc; --mm:arc"
  output: "ok"
"""

# lfSingleUse path: a var T call result used directly is T& in C++,
# genDeref must not emit '*' for it.
block: # bug: C++ genDeref wrongly emitted '*' for a T& reference
  type Obj = object
    field: tuple[a, b: int]
  func get(v: var Obj): var tuple[a, b: int] = v.field
  var v = Obj(field: (1, 2))
  doAssert get(v).a == 1
  doAssert get(v).b == 2
  get(v).a = 99
  doAssert v.field.a == 99
  # tuple unpacking also takes the lfSingleUse path
  var (xa, xb) = get(v)
  doAssert xa == 99
  doAssert xb == 2

# temp path: cAddr turns T& into T*, so '*' must still be emitted.
block: # ensure the temp path still generates '*' dereference
  proc id(x: var int): var int = x
  var n = 42
  doAssert id(n) == 42
  id(n) = 99
  doAssert n == 99
  # nested call: inner result goes to a temp, outer takes lfSingleUse
  doAssert id(id(n)) == 99
  id(id(n)) = 100
  doAssert n == 100

echo "ok"
