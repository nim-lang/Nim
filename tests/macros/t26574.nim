# bug #26574
import std/macros

type
  X[T] = object
    x: T

type
  Y = X[int]

macro a(t: typed) =
  let impl = t.getImpl()
  doAssert impl[2][0].sameType(X.getType())
  doAssert impl[2][0].getType().sameType(X.getType())

a(Y)
