import tables

type
  TX = Table[string, int]

proc foo(models: seq[Table[string, float]]): seq[float] =
  result = @[]
  for model in models.items:
    result.add model["foobar"]

# bug #686
type TType[T; A] = array[A, T]

proc foo[T](p: TType[T, range[0..1]]) =
  echo "foo"
proc foo[T](p: TType[T, range[0..2]]) =
  echo "bar"

#bug #1366

proc reversed(x) =
  for i in countdown(x.low, x.high):
    echo i

reversed(@[-19, 7, -4, 6])


