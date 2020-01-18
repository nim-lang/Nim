import asyncdispatch, os, times

proc doubleSleep(hardSleep: int) {.async.} =
  await sleepAsync(100)
  sleep(hardSleep)

template assertTime(target, timeTook: float): untyped {.dirty.} =
  assert(timeTook*1000 > target - 1000, "Took too short, should've taken " &
    $target & "ms, but took " & $(timeTook*1000) & "ms")
  assert(timeTook*1000 < target + 1000, "Took too long, should've taken " &
    $target & "ms, but took " & $(timeTook*1000) & "ms")

var
  start: float
  fut: Future[void]

# NOTE: this uses poll(3000) to limit timing error potential.
start = epochTime()
fut = sleepAsync(50) and sleepAsync(150) and doubleSleep(40)
while not fut.finished:
  poll(3000)
assertTime(150, epochTime() - start)

start = epochTime()
fut = sleepAsync(50) and sleepAsync(150) and doubleSleep(100)
while not fut.finished:
  poll(3000)
assertTime(200, epochTime() - start)

start = epochTime()
fut = sleepAsync(50) and sleepAsync(150) and doubleSleep(40) and sleepAsync(300)
while not fut.finished:
  poll(3000)
assertTime(300, epochTime() - start)

start = epochTime()
fut = sleepAsync(50) and sleepAsync(150) and doubleSleep(100) and sleepAsync(300)
while not fut.finished:
  poll(3000)
assertTime(300, epochTime() - start)

start = epochTime()
fut = (sleepAsync(50) and sleepAsync(150) and doubleSleep(40)) or sleepAsync(700)
while not fut.finished:
  poll(3000)
assertTime(150, epochTime() - start)

start = epochTime()
fut = (sleepAsync(50) and sleepAsync(150) and doubleSleep(100)) or sleepAsync(700)
while not fut.finished:
  poll(3000)
assertTime(200, epochTime() - start)
