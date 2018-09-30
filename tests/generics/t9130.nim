when true:
  # stack overflow
  template baz1*(iter: untyped): untyped =
    runnableExamples:
      import sugar
      proc fun(a: proc(x:int): int) = discard
      baz1(fun(x:int => x))
    discard

  proc foo1[A](ts: A) =
    baz1(ts)

when true:
  # ok
  template baz2*(iter: untyped): untyped =
    runnableExamples:
      import sugar
      proc fun(a: proc(x:int): int) = discard
      baz2(fun(x:int => x))
    discard

  proc foo2(ts: int) =
    baz2(ts)

when true:
  # stack overflow
  template baz3*(iter: untyped): untyped =
    runnableExamples:
      baz3(fun(x:int => x))
    discard

  proc foo3[A](ts: A) =
    baz3(ts)
