block:
  template foo(a: untyped, b: untyped = a(0)): untyped =
    let x = a(0)
    let y = b
    (x, y)
  proc bar(x: int): int = x + 1
  doAssert foo(bar, b = bar(0)) == (1, 1)
  doAssert foo(bar) == (1, 1)

block: # issue #23506
  var a: string
  template foo(x: int; y = x) =
    a = $($x, $y)
  foo(1)
  doAssert a == "(\"1\", \"1\")"
