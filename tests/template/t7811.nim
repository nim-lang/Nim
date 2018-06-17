template foo(x: string): untyped =
  len(x=x)
assert(foo("bar") == 3)
