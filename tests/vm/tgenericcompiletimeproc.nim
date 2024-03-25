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

block: # issue #19365
  proc f[T](x: static T): T {.compileTime.} = x + x
  doAssert f(123) == 246
  doAssert f(1.0) == 2.0
