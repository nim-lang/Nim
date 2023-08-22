discard """
  output: '''12
empty
he, no return type;
abc a string
ha'''
"""

proc ReturnT[T](x: T): T =
  when T is void:
    echo "he, no return type;"
  else:
    result = x & " a string"

proc nothing(x, y: void): void =
  echo "ha"

proc callProc[T](p: proc (x: T) {.nimcall.}, x: T) =
  when T is void:
    p()
  else:
    p(x)

proc intProc(x: int) =
  echo x

proc emptyProc() =
  echo "empty"

callProc[int](intProc, 12)
callProc[void](emptyProc)


ReturnT[void]()
echo ReturnT[string]("abc")
nothing()

block: # typeof(stmt)
  proc fn1(): auto =
    discard
  proc fn2(): auto =
    1
  doAssert type(fn1()) is void
  doAssert typeof(fn1()) is void
  doAssert typeof(fn1()) isnot int

  doAssert type(fn2()) isnot void
  doAssert typeof(fn2()) isnot void
  when typeof(fn1()) is void: discard
  else: doAssert false

  doAssert typeof(1+1) is int
  doAssert typeof((discard)) is void

  type A1 = typeof(fn1())
  doAssert A1 is void
  type A2 = type(fn1())
  doAssert A2 is void
  doAssert A2 is A1

  when false:
    # xxx: MCS/UFCS doesn't work here: Error: expression 'fn1()' has no type (or is ambiguous)
    type A3 = fn1().type
  proc bar[T](a: T): string = $T
  doAssert bar(1) == "int"
  doAssert bar(fn1()) == "void"

  proc bar2[T](a: T): bool = T is void
  doAssert not bar2(1)
  doAssert bar2(fn1())

  block:
    proc bar3[T](a: T): T = a
    let a1 = bar3(1)
    doAssert compiles(block:
      let a1 = bar3(fn2()))
    doAssert not compiles(block:
      let a2 = bar3(fn1()))
    doAssert compiles(block: bar3(fn1()))
    doAssert compiles(bar3(fn1()))
    doAssert typeof(bar3(fn1())) is void
    doAssert not compiles(sizeof(bar3(fn1())))

  block:
    var a = 1
    doAssert typeof((a = 2)) is void
    doAssert typeof((a = 2; a = 3)) is void
    doAssert typeof(block:
      a = 2; a = 3) is void

  block:
    var a = 1
    template bad1 = echo (a; a = 2)
    doAssert not compiles(bad1())

  block:
    template bad2 = echo (nonexistent; discard)
    doAssert not compiles(bad2())
