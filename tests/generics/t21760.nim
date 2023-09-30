import std/tables

type Url = object

proc myInit(_: type[Url], params = default(Table[string, string])): Url =
  discard

discard myInit(Url)