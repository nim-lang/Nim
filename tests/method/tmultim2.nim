discard """
  file: "tmultim2.nim"
  output: '''collide: unit, thing
collide: unit, thing
collide: thing, unit
collide: thing, thing'''
"""
# Test multi methods

type
  TThing = object {.inheritable.}
  TUnit = object of TThing
    x: int
  TParticle = object of TThing
    a, b: int
    
method collide(a, b: TThing) {.inline.} =
  echo "collide: thing, thing"
  
method collide(a: TThing, b: TUnit) {.inline.} =
  echo "collide: thing, unit"

method collide(a: TUnit, b: TThing) {.inline.} =
  echo "collide: unit, thing"

proc test(a, b: TThing) {.inline.} =
  collide(a, b)

proc staticCollide(a, b: TThing) {.inline.} =
  procCall collide(a, b)


var
  a: TThing
  b, c: TUnit
collide(b, c) # ambiguous (unit, thing) or (thing, unit)? -> prefer unit, thing!
test(b, c)
collide(a, b)
staticCollide(a, b)
