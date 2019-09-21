import asyncdispatch, os, times

proc doubleSleep(hardSleep: int) {.async.} =
  await sleepAsync(200)
  sleep(hardSleep)

template assertTime(target, timeTook: float): untyped {.dirty.} =
  assert(timeTook*1000 > target - 10, "Took too short, should've taken " &
    $target & "ms, but took " & $(timeTook*1000) & "ms")
  assert(timeTook*1000 < target + 10, "Took too long, should've taken " &
    $target & "ms, but took " & $(timeTook*1000) & "ms")

var start: float

start = epochTime()
waitFor sleepAsync(100) and sleepAsync(300) and doubleSleep(80)
assertTime(300, epochTime() - start)

start = epochTime()
waitFor sleepAsync(100) and sleepAsync(300) and doubleSleep(120)
assertTime(320, epochTime() - start)

start = epochTime()
waitFor sleepAsync(100) and sleepAsync(300) and doubleSleep(80) and sleepAsync(400)
assertTime(400, epochTime() - start)

start = epochTime()
waitFor sleepAsync(100) and sleepAsync(300) and doubleSleep(120) and sleepAsync(400)
assertTime(400, epochTime() - start)

start = epochTime()
waitFor (sleepAsync(100) and sleepAsync(300) and doubleSleep(80)) or sleepAsync(1400)
assertTime(300, epochTime() - start)

start = epochTime()
waitFor (sleepAsync(100) and sleepAsync(300) and doubleSleep(120)) or sleepAsync(1400)
assertTime(320, epochTime() - start)
