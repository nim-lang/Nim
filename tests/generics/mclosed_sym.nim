
type R* = object

type Data*[T] = object
  d*: T

proc same(r:R, d:int) = echo "TEST2"

proc doIt*(d:Data, r:R) =
  r.same(1)      # Expecting this to invoke the local `same()` method
