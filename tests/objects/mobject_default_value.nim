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
