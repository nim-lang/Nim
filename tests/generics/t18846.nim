type
  Either[T, U] = object of RootObj
    t: T
    u: U

  E = object of Either[float, string]

proc test(T: typedesc, e: Either[T, T]) =
  echo "matched ", typeof(e)
  echo e

proc test1[T](e: Either[T, auto]) =
  echo "matched ", typeof(e)
  echo e

proc test2[T](e: Either[T, T]) =
  echo "matched ", typeof(e)
  echo e

proc makeE(): E =
  result.t = -1.0
  result.u = "string"

doAssert false == compiles(test(int, makeE()))
doAssert false == compiles(test1[int](makeE()))

# This doesn't compile as expected
doAssert false == compiles(test2[int](makeE()))
