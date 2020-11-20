import json

type
  Foo = object
    ii*: int
    data*: JsonNode

block:
  const jt = """{"ii": 123, "data": ["some", "data"]}"""
  let js = parseJson(jt)
  discard js.to(Foo)

block:
  const jt = """{"ii": 123}"""
  let js = parseJson(jt)
  doAssertRaises(KeyError):
    echo js.to(Foo)
