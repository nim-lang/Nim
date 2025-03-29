import std/options

type
  Foo[D: static int; T] = T
  Bar[D] = Option[D]
  Bizz = Foo[1, string]
  Buzz = Foo[2, Option[string]]

assert  Bar[string].D is string
assert Bizz.D == 1
assert Buzz.D == 2
