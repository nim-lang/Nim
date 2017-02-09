import asyncdispatch

var fs = newFutureStream[string]()

proc alpha() {.async.} =
  for i in 0 .. 5:
    fs.put($i)
    await sleepAsync(1000)

  fs.complete()

proc beta() {.async.} =
  while not fs.finished():
    echo(await fs.takeAsync())

  echo("Finished")

asyncCheck alpha()
asyncCheck beta()