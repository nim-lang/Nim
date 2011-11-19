proc foo[T](thing: T) =
    discard thing

var a: proc (thing: int) = foo[int]

