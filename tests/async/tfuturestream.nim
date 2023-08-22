discard """
output: '''
0
1
2
3
4
5
Done
Finished
'''
"""
import asyncdispatch

var fs = newFutureStream[int]()

proc alpha() {.async.} =
  for i in 0 .. 5:
    await fs.write(i)
    await sleepAsync(100)

  echo("Done")
  fs.complete()

proc beta() {.async.} =
  while not fs.finished:
    let (hasValue, value) = await fs.read()
    if hasValue:
      echo(value)

  echo("Finished")

asyncCheck alpha()
waitFor beta()

template ensureCallbacksAreScheduled =
  # callbacks are called directly if the dispatcher is not running
  discard getGlobalDispatcher()

proc testCompletion() {.async.} =
  ensureCallbacksAreScheduled

  var stream = newFutureStream[string]()

  for i in 1..5:
    await stream.write($i)

  var readFuture = stream.readAll()
  stream.complete()
  yield readFuture
  let data = readFuture.read()
  doAssert(data.len == 5, "actual data len = " & $data.len)

waitFor testCompletion()

# TODO: Something like this should work eventually.
# proc delta(): FutureStream[string] {.async.} =
#   for i in 0 .. 5:
#     await sleepAsync(1000)
#     result.put($i)

#   return ""

# proc omega() {.async.} =
#   let fut = delta()
#   while not fut.finished():
#     echo(await fs.takeAsync())

#   echo("Finished")

# waitFor omega()
