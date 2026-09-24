discard """
  matrix: "--mm:refc; --mm:arc; --mm:orc"
  targets: "c cpp"
  output: "ok"
"""

# bug #26041: a closure iterator local was released at the `yield` that
# suspended the iterator instead of at the end of its scope.

func firstAddr[T](x: openArray[T]): ptr T =
  x[0].addr

proc churn() =
  ## Recycle enough memory that a freed payload would be reused.
  var junk: seq[seq[int]]
  for i in 0 ..< 100_000: junk.add @[-7]

block: # the local outlives the `yield`, so its payload must, too
  var p: ptr int

  iterator leak(): int {.closure.} =
    var data = @[123]
    p = firstAddr(data)
    yield 1
    yield 2 # `data`'s scope only ends here

  let it = leak
  discard it() # run to the first `yield` and suspend
  GC_fullCollect()
  churn()
  doAssert p[] == 123, "suspended iterator's seq payload was recycled"

block: # same, but the local's scope is a nested one
  var p: ptr int

  iterator leak(): int {.closure.} =
    while true:
      var data = @[456]
      p = firstAddr(data)
      yield 1
      break # `data` is never read again, but its scope reaches to here

  let it = leak
  discard it()
  GC_fullCollect()
  churn()
  doAssert p[] == 456

block: # a `try` body is a scope as well
  var p: ptr int

  iterator leak(): int {.closure.} =
    try:
      var data = @[789]
      p = firstAddr(data)
      yield 1
    finally:
      discard

  let it = leak
  discard it()
  GC_fullCollect()
  churn()
  doAssert p[] == 789

when defined(gcDestructors):
  block: # the lifted local is destroyed exactly once, with the environment
    var destroyed = 0

    type Res = object
      id: int

    proc `=destroy`(x: Res) =
      if x.id != 0: inc destroyed

    proc run() =
      iterator iter(): int {.closure.} =
        var r = Res(id: 1) # never read again; the scope is what keeps it alive
        yield 1
        yield 2

      var it = iter
      doAssert it() == 1
      doAssert destroyed == 0
      doAssert it() == 2
      doAssert destroyed == 0
      discard it() # run the iterator to completion

    run() # only now is the environment gone
    doAssert destroyed == 1, $destroyed

echo "ok"
