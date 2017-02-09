import asyncdispatch

var fs = newFutureStream[string]()

proc alpha() {.async.} =
  for i in 0 .. 5:
    await sleepAsync(1000)
    fs.put($i)

  fs.complete("Done")

proc beta() {.async.} =
  while not fs.finished:
    echo(await fs.takeAsync())

  echo("Finished")

asyncCheck alpha()
waitFor beta()

