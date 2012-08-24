discard """
  file: "tmultim2.nim"
  output: "collide: unit, thing collide: unit, thing collide: thing, unit"
"""
# Test multi methods

type
  TThing = object {.inheritable.}
  TUnit = object of TThing
    x: int
  TParticle = object of TThing
    a, b: int
    
method collide(a, b: TThing) {.inline.} =
  quit "to override!"
  
method collide(a: TThing, b: TUnit) {.inline.} =
  write stdout, "collide: thing, unit "

method collide(a: TUnit, b: TThing) {.inline.} =
  write stdout, "collide: unit, thing "

proc test(a, b: TThing) {.inline.} =
  collide(a, b)

var
  a: TThing
  b, c: TUnit
collide(b, c) # ambiguous (unit, thing) or (thing, unit)? -> prefer unit, thing!
test(b, c)
collide(a, b)
#OUT collide: unit, thing collide: unit, thing collide: thing, unit




