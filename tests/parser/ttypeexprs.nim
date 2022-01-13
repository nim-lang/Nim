proc foo[T: ptr int | ptr string](x: T) = discard
var x = "abc"
foo(addr x)
