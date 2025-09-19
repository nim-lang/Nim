# issue #4554 comment

type Obj[T] = object
  b: T

converter test1[T](a: Obj[T]): T = a.b

proc doStuff(a: int, b: float) = discard

doStuff(Obj[int](b: 1), Obj[float](b: 1.2)) # Error: type mismatch: got <Obj[system.int], Obj[system.float]>
