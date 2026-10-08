discard """
  matrix: "--mm:refc; --mm:orc"
"""

# bug #26393
type Foo = ref object
  a: Foo
  v: int

proc foo() =
  var x = Foo(a: nil, v: 1)
  x = Foo(a: x, v: 2)
  doAssert x.v == 2
  doAssert x.a.v == 1
  doAssert x.a.a.isNil
  x = Foo(a: Foo(a: x, v: 3), v: 4)
  doAssert x.v == 4 and x.a.v == 3 and x.a.a.v == 2 and x.a.a.a.v == 1
  x = x.a
  doAssert x.v == 3 and x.a.v == 2
  x.a = Foo(a: x, v: 5)
  doAssert x.a.v == 5 and x.a.a == x

static: foo()
foo()
