proc foo[T](a: openArray[T]) = discard

var x: array[0 .. 3, int]
foo(x)
var y: array[3 .. 6, int]
doAssert not compiles(foo(y))
foo(array[0 .. 3, int](y))
foo(array[0 .. y.len - 1, int](y))
var z: array[-3 .. 0, int]
doAssert not compiles(foo(z))
foo(array[0 .. 3, int](z))
foo(array[0 .. z.len - 1, int](z))

proc bar[I, T](a: array[I, T]) = foo(a)
bar(x)
doAssert not compiles(bar(y))
bar(array[0 .. 3, int](y))
bar(array[0 .. y.len - 1, int](y))
doAssert not compiles(bar(z))
bar(array[0 .. 3, int](z))
bar(array[0 .. z.len - 1, int](z))
