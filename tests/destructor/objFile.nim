type Obj* = object
  v*: int

proc `=destroy`(this: var Obj) =
  echo "igotdestroyed"
  this.v = -1

var test* = Obj(v: 42)
