discard """
  errormsg: "type mismatch: got <Foo, Foo>"
  line: 8
"""
proc g[T](x: T) =
  bind `+`
  # because we bind `+` here, we must not find the `+` for 'Foo' below:
  echo x + x

type
  Foo = object
    a: int

proc `+`(a, b: Foo): Foo = Foo(a: a.a+b.a)

g(3)
g(Foo(a: 8))
