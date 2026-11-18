# bug #10833
type Foo*[A; B; C: static[int]] = object

proc build*[A; B; C: static[int]](field: string): Foo[A, B, C] =
  discard

proc build*[A; B; C: static[int]](): Foo[A, B, C] =
  build[A, B, C]("foo")

type
  Bar = object
  Baz = object

discard build[Bar, Baz, 1]()
