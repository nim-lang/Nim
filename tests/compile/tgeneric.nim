import tables

type
  TX = TTable[string, int]

proc foo(models: seq[TTable[string, float]]): seq[float] =
  result = @[]
  for model in models.items:
    result.add model["foobar"]

# bug #686
type TType[T; A] = array[A, T]

proc foo[T](p: TType[T, range[0..1]]) =
  echo "foo"
proc foo[T](p: TType[T, range[0..2]]) =
  echo "bar"


