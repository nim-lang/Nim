# issue #25014

type
  FooBase[T] {.inheritable.} = object
    val: T
  FooChild[T] = object of FooBase[T]

converter toValue*[T](r: FooBase[T]): T = r.val

proc foo(a: int) = discard
var f: FooChild[int]
foo(f)
proc fooGeneric[T](a: T) = discard
fooGeneric(f)
