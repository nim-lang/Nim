let mfoo1* = [1,2] ## c1
var mfoo2* = "asdf" ## c2
const mfoo3* = 'a' ## c3

proc `@@@`*(a: int) = discard
proc `@@@`*(a: float) = discard
proc `@@@`*[T: Ordinal](a: T) = discard

