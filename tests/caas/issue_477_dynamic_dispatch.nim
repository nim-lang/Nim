type
  TThing = object of TObject
  TUnit = object of TThing
    x: int

method collide(a, b: TThing) {.inline.} =
  quit "to override!"

method collide(a: TThing, b: TUnit) {.inline.} =
  echo "collide1"

method collide(a: TUnit, b: TThing) {.inline.} =
  echo "collide2"

var
  a, b: TUnit

when isMainModule:
  collide(a, b) # output: 2
