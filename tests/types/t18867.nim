import std/macros

macro assertSameType(x: typed, y: typed): untyped =
  assert sameType(x, y)

type G[T] = T

assertSameType(float(1.0), G[float](1.0))
assertSameType(G[float](1.0), float(1.0))
