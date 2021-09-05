discard """
  errormsg: "type mismatch: got <Foo, Foo>"
  line: 9
"""
{.undef(nimLazySemcheck).} # nimLazySemcheck would make this work; xxx maybe we can adapt the test to work with either setting
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
