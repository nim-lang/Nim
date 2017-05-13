type
  SomeObj = object of RootObj

  Foo[T, U] = object
    x: T
    y: U

template someTemplate[T](): tuple[id: int32, obj: T] =
  var result: tuple[id: int32, obj: T] = (0'i32, T())
  result

let ret = someTemplate[SomeObj]()

