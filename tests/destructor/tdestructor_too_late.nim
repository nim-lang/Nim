discard """
  errormsg: "cannot bind another '=destroy' to: Obj; previous declaration was constructed here implicitly: tdestructor_too_late.nim(7, 16)"
"""
type Obj* = object
  v*: int

proc something(this: sink Obj) = 
  discard
type _ = typeof(something) # D20210905T125411_forceSemcheck_compiles
proc `=destroy`(this: var Obj) =
  echo "igotdestroyed"
  this.v = -1

var test* = Obj(v: 42)