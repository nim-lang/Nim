type
  Foo[M] = proc() : M

proc bar[M](f : Foo[M]) =
  discard f()

proc baz() : int = 42

bar(baz)