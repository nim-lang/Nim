
# bug #4328
type
    foo[T] = object
        z: T

proc test[T](x: foo[T], p: proc(a: T) = nil) =
    discard

var d: foo[int]
d.test()  # <- param omitted
