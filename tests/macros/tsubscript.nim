macro foo[T](x: T) = discard
doAssert not compiles(foo[abc])

template bar[T](): untyped = T(0)
let x = bar[int]
doAssert x == 0
doAssert not compiles(bar[abc])
