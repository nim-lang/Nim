type
  TObj*[T] = object
    val*: T

var
  totalGlobals* = 0

proc makeObj[T](x: T): TObj[T] =
  totalGlobals += 1
  result.val = x

proc globalInstance*[T]: var TObj[T] =
  var g {.global.} = when T is int: makeObj(10) else: makeObj("hello")
  result = g

