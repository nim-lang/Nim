
block: # basic test
  proc doStuff[T](a: SomeInteger): T = discard
  proc doStuff[T;Y](a: SomeInteger, b: Y): Y = discard
  assert typeof(doStuff[int](100)) is int
  assert typeof(doStuff[int](100, 1.0)) is float
  assert typeof(doStuff[int](100, "Hello")) is string

  proc t[T](x: T; z: int | float): seq[T] = result.add(x & $z)

  assert t[string]("Hallo", 2.0) == @["Hallo" & $2.0]

  proc t2[T](z: int | float): seq[T] = result.add($z)

  assert t2[string](2.0) == @[$2.0]

block: # template test
  template someThing[T;Y](a: SomeFloat, b: SomeOrdinal): (T, Y) = (a, b)
  assert typeof(someThing[float64, int](1.0, 100)) is (float64, int)

block: # static test
  proc t[T](s: static bool) = discard
  proc t2[T](s: static string) = discard
  t[string](true)
  t2[int]("hello")
  t2[string]("world")
  t2[float]("test222222")
