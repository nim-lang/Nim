type
  Foo[T] = object
    x:T
  Bar[T,R] = Foo[T]
  Baz = Bar[int,float]

proc qux[T,R](x: Bar[T,R]) = discard

var b:Baz
b.qux()