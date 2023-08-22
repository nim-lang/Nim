import asyncdispatch

proc completeOnReturn(fut: FutureVar[string], x: bool) {.async.} =
  if x:
    fut.mget() = ""
    fut.mget.add("foobar")
    return

proc completeOnImplicitReturn(fut: FutureVar[string], x: bool) {.async.} =
  if x:
    fut.mget() = ""
    fut.mget.add("foobar")

proc failureTest(fut: FutureVar[string], x: bool) {.async.} =
  if x:
    raise newException(Exception, "Test")

proc manualComplete(fut: FutureVar[string], x: bool) {.async.} =
  if x:
    fut.mget() = "Hello World"
    fut.complete()
    return

proc main() {.async.} =
  var fut: FutureVar[string]

  fut = newFutureVar[string]()
  await completeOnReturn(fut, true)
  doAssert(fut.read() == "foobar")

  fut = newFutureVar[string]()
  await completeOnImplicitReturn(fut, true)
  doAssert(fut.read() == "foobar")

  fut = newFutureVar[string]()
  let retFut = failureTest(fut, true)
  yield retFut
  doAssert(fut.read().len == 0)
  doAssert(fut.finished)

  fut = newFutureVar[string]()
  await manualComplete(fut, true)
  doAssert(fut.read() == "Hello World")


waitFor main()
