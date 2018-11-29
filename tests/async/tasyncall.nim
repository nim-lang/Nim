discard """
  exitcode: 0
"""
import times, sequtils
import asyncdispatch

const
  taskCount = 10
  sleepDuration = 50

proc futureWithValue(x: int): Future[int] {.async.} =
  await sleepAsync(sleepDuration)
  return x

proc futureWithoutValue() {.async.} =
  await sleepAsync(sleepDuration)

proc testFuturesWithValue(x: int): seq[int] =
  var tasks = newSeq[Future[int]](taskCount)

  for i in 0..<taskCount:
    tasks[i] = futureWithValue(x)

  result = waitFor all(tasks)

proc testFuturesWithoutValues() =
  var tasks = newSeq[Future[void]](taskCount)

  for i in 0..<taskCount:
    tasks[i] = futureWithoutValue()

  waitFor all(tasks)

proc testVarargs(x, y, z: int): seq[int] =
  let
    a = futureWithValue(x)
    b = futureWithValue(y)
    c = futureWithValue(z)

  result = waitFor all(a, b, c)

proc testWithDupes() =
  var
    tasks = newSeq[Future[void]](taskCount)
    fut = futureWithoutValue()

  for i in 0..<taskCount:
    tasks[i] = fut

  waitFor all(tasks)

block:
    let
      startTime = cpuTime()
      results = testFuturesWithValue(42)
      expected = repeat(42, taskCount)
      execTime = cpuTime() - startTime

    doAssert execTime * 1000 < taskCount * sleepDuration
    doAssert results == expected

block:
    let startTime = cpuTime()
    testFuturesWithoutValues()
    let execTime = cpuTime() - startTime

    doAssert execTime * 1000 < taskCount * sleepDuration

block:
    let startTime = cpuTime()
    testWithDupes()
    let execTime = cpuTime() - startTime

    doAssert execTime * 1000 < taskCount * sleepDuration

block:
    let
      startTime = cpuTime()
      results = testVarargs(1, 2, 3)
      expected = @[1, 2, 3]
      execTime = cpuTime() - startTime

    doAssert execTime * 100 < taskCount * sleepDuration
    doAssert results == expected

block:
    let
      noIntFuturesFut = all(newSeq[Future[int]]())
      noVoidFuturesFut = all(newSeq[Future[void]]())

    doAssert noIntFuturesFut.finished and not noIntFuturesFut.failed
    doAssert noVoidFuturesFut.finished and not noVoidFuturesFut.failed
    doAssert noIntFuturesFut.read() == @[]
