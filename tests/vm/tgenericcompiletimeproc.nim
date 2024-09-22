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

block:
  # don't fold compile time procs in typeof
  proc fail[T](x: T): T {.compileTime.} =
    doAssert false
    x
  doAssert typeof(fail(123)) is typeof(123)
  proc p(x: int): int = x

  type Foo = typeof(p(fail(123)))

block: # issue #24150, related regression
  proc w(T: type): T {.compileTime.} = default(ptr T)[]
  template y(v: auto): auto = typeof(v) is int
  discard compiles(y(w int))
  proc s(): int {.compileTime.} = discard
  discard s()
