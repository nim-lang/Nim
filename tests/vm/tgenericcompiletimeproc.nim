block: # issue #10753
  proc foo(x: int): int {.compileTime.} = x
  const a = foo(123)
  doAssert foo(123) == a

  proc bar[T](x: T): T {.compileTime.} = x
  const b = bar(123)
  doAssert bar(123) == b
  const c = bar("abc")
  doAssert bar("abc") == c

block: # issue #22021
  proc foo(x: static int): int {.compileTime.} = x + 1
  doAssert foo(123) == 124
