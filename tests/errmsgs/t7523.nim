discard """
  action: compile
  errormsg: "field access 'result.bar' conflicts with procedure call 'bar', rename the field or call as 'bar(result,...)'"
"""
type
  Foo = object
    bar: int

proc bar(cur: Foo, val: int) =
  discard cur.bar

proc does_fail(): Foo =
  result.bar(5)
