type
  SomeObj = object of RootObj

  Foo[T, U] = object
    x: T
    y: U

template someTemplate[T](): tuple[id: int32, obj: T] =
  var result: tuple[id: int32, obj: T] = (0'i32, T())
  result

let ret = someTemplate[SomeObj]()

# https://github.com/nim-lang/Nim/issues/7829
proc inner*[T](): int =
  discard

template outer*[A](): untyped =
  inner[A]()

template outer*[B](x: int): untyped =
  inner[B]()

var i1 = outer[int]()
var i2 = outer[int](i1)

# https://github.com/nim-lang/Nim/issues/7883
template t1[T: int|int64](s: string): T =
   var t: T
   t

template t1[T: int|int64](x: int, s: string): T =
   var t: T
   t

var i3: int = t1[int]("xx")

