# bug #12719: a `{.compileTime.}` seq declared together with another one

var x, y {.compileTime.}: seq[seq[int]]

macro foo = y.add @[]

foo
static: doAssert y.len == 1 and x.len == 0
