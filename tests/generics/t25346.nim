# issue #25346

type
  Foo[T] = seq[T] or set[T]

proc foo[T](x: Foo[T]) = discard
foo(@['a', 'b'])
foo({'a', 'b'})

type
  Bar[T] = seq[T] or ptr UncheckedArray[T]

proc bar[T](x: Bar[T]) = discard
var x = @[1, 2]
bar(x)
bar(cast[ptr UncheckedArray[int]](addr x[0]))
