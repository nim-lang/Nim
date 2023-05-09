type
  Foo = object

using
  c: Foo
  x, y: int

proc usesSig(c) = discard

proc foobar(c, y) = discard

usesSig(Foo())
foobar(Foo(), 123)
doAssert not compiles(usesSig(123))
doAssert not compiles(foobar(Foo(), Foo()))
doAssert not compiles(foobar(123, 123))
