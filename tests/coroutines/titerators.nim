discard """
  targets: "c"
disabled: true
"""

# Timers are always flakey on the testing servers.

import coro
include system/timers

var
  stackCheckValue = 1100220033
  numbers = newSeqOfCap[int](10)

iterator theIterator(id: int, sleep: float): int =
  for i in 0..<5:
    yield 10 * id + i
    suspend(sleep)

proc theCoroutine(id: int, sleep: float32) =
  for n in theIterator(id, sleep):
    numbers.add(n)

var start = getTicks()
start(proc() = theCoroutine(1, 0.01))
start(proc() = theCoroutine(2, 0.011))
run()

var executionTime = getTicks() - start
doAssert(stackCheckValue == 1100220033, "Thread stack got corrupted")
doAssert(numbers == @[10, 20, 11, 21, 12, 22, 13, 23, 14, 24], "Coroutines executed in incorrect order")
