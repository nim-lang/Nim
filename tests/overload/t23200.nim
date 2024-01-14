import std/[sugar, sequtils]

proc dosomething(iter: int -> (iterator: int)) =
  discard

proc dosomething(iter: int -> seq[int]) =
  discard

proc makeSeq(x: int): seq[int] =
  @[x]

# Works fine with 1.6.12 and 1.6.14
dosomething(makeSeq)

# Works with 1.6.12, fails with 1.6.14
dosomething((y) => makeSeq(y))
