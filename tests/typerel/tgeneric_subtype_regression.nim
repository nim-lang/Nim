discard """
  errormsg: "type mismatch: got <FooRef[system.string]>"
  line: 15
"""

# bug #4478

type
  Foo[T] = object
  FooRef[T] = ref Foo[T]

proc takeFoo[T](foo: Foo[T]): int = discard

proc g(x: FooRef[string]) =
  echo x.takeFoo() != 8

var x: FooRef[string]

g(x)
