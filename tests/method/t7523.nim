type
  Foo = object
    bar: int

proc bar(cur: Foo, val: int, s:seq[string]) =
  discard cur.bar

proc does_fail(): Foo =
  let a = @["a"]
  result.bar(5, a)