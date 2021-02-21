import asyncdispatch, os, times

proc doubleSleep(hardSleep: int) {.async.} =
  await sleepAsync(50)
  sleep(hardSleep)

template assertTime(target, timeTook: float): untyped {.dirty.} =
  doAssert(timeTook*1000 > target - 1000, "Took too short, should've taken " &
    $target & "ms, but took " & $(timeTook*1000) & "ms")
  doAssert(timeTook*1000 < target + 1000, "Took too long, should've taken " &
    $target & "ms, but took " & $(timeTook*1000) & "ms")

var
  start: float
  fut: Future[void]

# NOTE: this uses poll(3000) to limit timing error potential.
start = epochTime()
fut = sleepAsync(40) and sleepAsync(100) and doubleSleep(20)
while not fut.finished:
  poll(1000)
assertTime(150, epochTime() - start)

start = epochTime()
fut = sleepAsync(40) and sleepAsync(100) and doubleSleep(50)
while not fut.finished:
  poll(1000)
assertTime(200, epochTime() - start)

start = epochTime()
fut = sleepAsync(40) and sleepAsync(100) and doubleSleep(20) and sleepAsync(200)
while not fut.finished:
  poll(1000)
assertTime(300, epochTime() - start)

start = epochTime()
fut = (sleepAsync(40) and sleepAsync(100) and doubleSleep(20)) or sleepAsync(300)
while not fut.finished:
  poll(1000)
assertTime(150, epochTime() - start)
