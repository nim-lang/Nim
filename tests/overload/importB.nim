type
  Foo*[T] = object
    v*: T

template `+`*(x: Foo, y: Foo): untyped = x

template newvar*(r: untyped): untyped {.dirty.} =
  var r: float

template t1*(x: Foo): untyped =
  newvar(y1)
  x
template t2*(x: Foo): untyped =
  newvar(y2)
  x
