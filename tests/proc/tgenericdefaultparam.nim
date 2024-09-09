block: # issue #16700
  type MyObject[T] = object
    x: T
  proc initMyObject[T](value = T.default): MyObject[T] =
    MyObject[T](x: value)
  var obj = initMyObject[int]()

block: # issue #20916
  type
    SomeX = object
      v: int
  var val = 0
  proc f(_: type int, x: SomeX, v = x.v) =
    doAssert v == 42
    val = v
  proc a(): proc() =
    let v = SomeX(v: 42)
    var tmp = proc() =
      int.f(v)
    tmp
  a()()
  doAssert val == 42
