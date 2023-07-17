type
  Foo = object
    id: int

proc `=wasMoved`(x: var Foo) =
  x.id = -1

proc foo =
  var s = Foo(id: 999)
  var m = move s
  doAssert s.id == -1
  doAssert m.id == 999

foo()
