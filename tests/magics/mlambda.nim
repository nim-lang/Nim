import std/lambdas

{.push experimental: "alias".}

proc mbar*(a0: int, funx: aliassym): auto =
  ("mbar", a0, funx(a0))

iterator iota3(): auto =
  for i in 0..<3: yield i

const iota3Bis* = alias2 iota3

{.pop.}

import std/macros

macro elementType*(a: untyped): untyped =
  ## return element type of `a`, which can be any iterable (value or iterator
  ## expresssion)
  runnableExamples:
    iterator myiter(n: int): auto =
      for i in 0..<n: yield i
    iterator myiter2(n: int): auto {.closure.} =
      for i in 0..<n: yield i
    doAssert elementType(@[1,2]) is int
    doAssert elementType("asdf") is char
    doAssert elementType(myiter(3)) is int
    doAssert elementType(myiter2(3)) is int
  # xxx move to std/typetraits
  template fun(b): untyped =
    typeof(block: (for ai in b: ai))
  getAst(fun(a))
