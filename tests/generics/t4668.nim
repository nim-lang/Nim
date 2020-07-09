discard """
action: compile
"""

type
  FooObj*[T] = object
    v*: T
  Foo1*[T] = FooObj[T]
  Foo2* = FooObj

proc foo1(x: Foo1) = echo "foo1"
proc foo2(x: Foo2) = echo "foo2"

var x: FooObj[float]
foo1(x)  # works
foo2(x)  # works
