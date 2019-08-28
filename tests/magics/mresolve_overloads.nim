let foo1* = [1,2] ## c1
var foo2* = "asdf" ## c2
const foo3* = 'a' ## c3

proc `@@@`*(a: int) = discard
proc `@@@`*(a: float) = discard
proc `@@@`*[T: Ordinal](a: T) = discard

