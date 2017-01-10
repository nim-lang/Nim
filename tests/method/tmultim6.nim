discard """
  output: "collide: unit, thing | collide: unit, thing | collide: thing, unit |"
"""
# Test multi methods

type
  Thing = object {.inheritable.}
  Unit[T] = object of Thing
    x: T
  Particle = object of Thing
    a, b: int

method collide(a, b: Thing) {.base, inline.} =
  quit "to override!"

method collide[T](a: Thing, b: Unit[T]) {.inline.} =
  write stdout, "collide: thing, unit | "

method collide[T](a: Unit[T], b: Thing) {.inline.} =
  write stdout, "collide: unit, thing | "

proc test(a, b: Thing) {.inline.} =
  collide(a, b)

var
  a: Thing
  b, c: Unit[string]
collide(b, Thing(c))
test(b, c)
collide(a, b)
