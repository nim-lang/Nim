import tables

type
  TX = Table[string, int]

proc foo(models: seq[TX]): seq[int] =
  result = @[]
  for model in models.items:
    result.add model["foobar"]

type
  Obj = object
    field: Table[string, string]
var t: Obj
discard initTable[type(t.field), string]()
