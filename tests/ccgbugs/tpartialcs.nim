
# bug #2551

type Tup = tuple
  A, a: int

type Obj = object
  A, a: int

var x: Tup # This works.
var y: Obj # This doesn't.

# bug #2212

proc f() =
  let
    p = 1.0
    P = 0.25 + 0.5

f()
