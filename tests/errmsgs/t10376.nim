discard """
  errormsg: "finalizer must be a direct reference to a proc"
  line: 29
"""

type
  A = ref object

proc my_callback(a: A) {. nimcall .} =
  discard

proc foo(callback: proc(a: A) {. nimcall .}) =
  var x1: A
  new(x1, proc (x: A) {.nimcall.} = discard)
  var x2: A
  new(x2, func (x: A) {.nimcall.} = discard)

  var x3: A
  proc foo1(a: A) {.nimcall.} = discard
  new(x3, foo1)
  var x4: A
  func foo2(a: A) {.nimcall.} = discard
  new(x4, foo2)

  var x5: A
  new(x5, my_callback)

  var x6: A
  new(x6, callback)

foo(my_callback)
