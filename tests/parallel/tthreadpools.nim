discard """
  output: "Done"
"""

import threadpool as tps
import times, os, random

block:
    var callsMade = 0

    proc simpleCall() =
        atomicInc(callsMade)

    const simpleCallIterations = 100000

    let p = tps.newThreadPool()
    for i in 0 ..< simpleCallIterations:
        p.spawn simpleCall()
    p.sync()

    doAssert(callsMade == simpleCallIterations)

block:
    proc sleepForTime(a: int) =
        sleep(a)

    const randomSeed = 12345
    var randomGen = initRand(randomSeed)

    const randomSleepIterations = 100

    let p = tps.newThreadPool()
    for i in 0 ..< randomSleepIterations:
        let s = randomGen.rand(300)
        p.spawn sleepForTime(s)
    p.sync()

block:
    proc sleepAndReturnSomeResult(a: int): int =
        sleep(a)
        return a + 1

    const randomSeed = 54312
    var randomGen = initRand(randomSeed)

    const randomSleepIterations = 100

    let p = tps.newThreadPool()
    var results = newSeq[tps.FlowVar[int]](randomSleepIterations)
    for i in 0 ..< randomSleepIterations:
        let s = randomGen.rand(300)
        results[i] = p.spawn sleepAndReturnSomeResult(s)

    randomGen = initRand(randomSeed)
    for i in 0 ..< randomSleepIterations:
        let s = randomGen.rand(300)
        doAssert(results[i].read() == s + 1)

    p.sync()

block:
    proc sleepAndReturnSomeResult(a: int): int =
        sleep(a)
        return a + 1

    const randomSeed = 83729
    var randomGen = initRand(randomSeed)

    const randomSleepIterations = 100

    let p = tps.newThreadPool()
    var results = newSeq[tps.FlowVar[int]](randomSleepIterations)
    for i in 0 ..< randomSleepIterations:
        let s = randomGen.rand(300)
        results[i] = p.spawn sleepAndReturnSomeResult(s)

    var iResults = newSeq[int](randomSleepIterations)

    iResults[5] = results[5].read()
    iResults[15] = results[15].read()

    while true:
        let i = awaitAny(results)
        if i == -1:
            break
        iResults[i] = results[i].read()

    randomGen = initRand(randomSeed)
    for i in 0 ..< randomSleepIterations:
        let s = randomGen.rand(300)
        doAssert(iResults[i] == s + 1)

    p.sync()

block:
    let p = tps.newThreadPool()
    proc sleepAndReturnSomeResult(a: int): int =
        sleep(a)
        return a + 1
    let s = p.spawn sleepAndReturnSomeResult(100)
    var numberOfSleeps = 0
    while not s.isReady:
        sleep(10)
        inc numberOfSleeps
    doAssert(^s == 101)
    doAssert(numberOfSleeps > 2)

block: # openarrays
    let p = tps.newThreadPool()
    proc sum(numbers: openarray[int]): int =
        for i in numbers:
            result += i
    let se = @[1, 2, 3]
    let s = p.spawn sum(se)
    doAssert(^s == 6)

echo "Done"
