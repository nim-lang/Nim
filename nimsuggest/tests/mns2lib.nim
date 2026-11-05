type
  Box*[T] = object
    value*: T

proc boxed*[T](x: T): Box[T] = Box[T](value: x)

template twice*(x: untyped): untyped = x + x
