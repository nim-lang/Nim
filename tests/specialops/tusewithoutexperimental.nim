{.push experimental: "callOperator".}

template `()`(a, b: int): int = a + b
let x = 1
let y = 2
doAssert x.y == 3

{.pop.}

doAssert not compiles(x.y)
