type
  Clean = object
    mem: int
  Default* = object
    poi: int = 12
    clc: Clean
    se*: range[0'i32 .. high(int32)]

  NonDefault* = object
    poi: int

  PrellDeque*[T] = object
    pendingTasks*: range[0'i32 .. high(int32)]
    head: T
    tail: T

block:
  type
    Foo = object
      x = Bar()

    Bar = object
      x: int

  var f = Foo()
  doassert f.x.x == 0

block:
  type
    Bar = object
      x: int

    Foo = object
      x = Bar()

  var f = Foo()
  doassert f.x.x == 0
