discard """
output: "50005000"
"""
import asyncdispatch

proc asyncRecursionCycle*(counter: int): Future[int] =
  var retFuture = newFuture[int]("asyncRecursionTest")
  retFuture.complete(counter + 1)
  return retFuture

proc asyncRecursionTest*(): Future[int] {.async.} =
  var i = 0
  result = 0
  while i < 10_000:
    inc(result, await asyncRecursionCycle(i))
    inc(i)

when true:
  setGlobalDispatcher(newDispatcher())
  var i = waitFor asyncRecursionTest()
  echo i
