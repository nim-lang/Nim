import asyncdispatch, os, times

proc doubleSleep(hardSleep: int) {.async.} =
  await sleepAsync(100)
  sleep(hardSleep)

template assertTime(target, timeTook: float): untyped {.dirty.} =
  assert(timeTook*1000 > target - 50, "Took too short, should've taken " &
    $target & "ms, but took " & $(timeTook*1000) & "ms")
  assert(timeTook*1000 < target + 50, "Took too long, should've taken " &
    $target & "ms, but took " & $(timeTook*1000) & "ms")

var start: float

start = epochTime()
waitFor sleepAsync(50) and sleepAsync(150) and doubleSleep(40)
assertTime(150, epochTime() - start)

start = epochTime()
waitFor sleepAsync(50) and sleepAsync(150) and doubleSleep(100)
assertTime(200, epochTime() - start)

start = epochTime()
waitFor sleepAsync(50) and sleepAsync(150) and doubleSleep(40) and sleepAsync(300)
assertTime(300, epochTime() - start)

start = epochTime()
waitFor sleepAsync(50) and sleepAsync(150) and doubleSleep(100) and sleepAsync(300)
assertTime(300, epochTime() - start)

start = epochTime()
waitFor (sleepAsync(50) and sleepAsync(150) and doubleSleep(40)) or sleepAsync(700)
assertTime(150, epochTime() - start)

start = epochTime()
waitFor (sleepAsync(50) and sleepAsync(150) and doubleSleep(100)) or sleepAsync(700)
assertTime(200, epochTime() - start)
