import tables

type
  TX = TTable[string, int]

proc foo(models: seq[TX]): seq[int] =
  result = @[]
  for model in models.items:
    result.add model["foobar"]


