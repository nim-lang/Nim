discard """
  matrix: "--parsem:on --sinkInference:on"
  output: "igotdestroyed"
"""

# `--parsem:on` variant of tests/destructor/tdestructor_too_late: the body of
# `something` no longer lifts `=destroy` before the explicit one is declared, so
# the explicit one binds.
type Obj* = object
  v*: int

proc something(this: sink Obj) = 
  discard

proc `=destroy`(this: var Obj) =
  echo "igotdestroyed"
  this.v = -1

var test* = Obj(v: 42)