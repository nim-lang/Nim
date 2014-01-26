discard """
  output: "collide: unit, thing | collide: unit, thing | collide: thing, unit |"
"""
# Test multi methods

type
  TThing = object {.inheritable.}
  TUnit[T] = object of TThing
    x: T
  TParticle = object of TThing
    a, b: int
    
method collide(a, b: TThing) {.inline.} =
  quit "to override!"
  
method collide[T](a: TThing, b: TUnit[T]) {.inline.} =
  write stdout, "collide: thing, unit | "

method collide[T](a: TUnit[T], b: TThing) {.inline.} =
  write stdout, "collide: unit, thing | "

proc test(a, b: TThing) {.inline.} =
  collide(a, b)

var
  a: TThing
  b, c: TUnit[string]
collide(b, TThing(c))
test(b, c)
collide(a, b)
