type
  Foo[T] = distinct seq[T]
  Bar[T] = object

proc newFoo[T](): Foo[T] = Foo[T](newSeq[T]())

var x = newFoo[Bar[int]]()
