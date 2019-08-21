import std/lambdas

proc mbar*(a0: int, funx: aliassym): auto =
  ("mbar", a0, funx(a0))

iterator iota3(): auto =
  for i in 0..<3: yield i

const iota3Bis* = alias2 iota3
