block:
  {.push experimental: "callOperator".}

  template `()`(a, b: int): int = a + b
  let x = 1
  let y = 2
  doAssert x.y == 3
  doAssert compiles(x.y)
  let z = 3.0
  doAssert not compiles(x.z)

  {.pop.}

  doAssert not compiles(x.y)
  doAssert not compiles(x.z)

block:
  {.push experimental: "dotOperators".}

  template `.`(a, b: string): string = a & b
  let x = "x"
  let y = "y"
  doAssert x.y == "xy"
  doAssert compiles(x.y)
  let z = 'z'
  doAssert not compiles(x.z)

  {.pop.}

  doAssert not compiles(x.y)
  doAssert not compiles(x.z)