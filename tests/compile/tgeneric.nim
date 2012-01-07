import tables

type
  TX = TTable[string, int]

proc foo(models: seq[TTable[string, float]]): seq[float] =
  result = @[]
  for model in models.items:
    result.add model["foobar"]


