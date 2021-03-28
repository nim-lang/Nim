discard """
  targets: "c"
  disabled: true
"""

import coro
var
  stackCheckValue = 1100220033
  numbers = newSeqOfCap[int](10)

proc testExceptions(id: int, sleep: float) =
  try:
    numbers.add(id)
    suspend(sleep)
    numbers.add(id)
    raise (ref ValueError)()
  except:
    suspend(sleep)
    numbers.add(id)
    suspend(sleep)
    numbers.add(id)
  suspend(sleep)
  numbers.add(id)

start(proc() = testExceptions(1, 0.01))
start(proc() = testExceptions(2, 0.011))
coro.run()
doAssert(stackCheckValue == 1100220033, "Thread stack got corrupted")
doAssert(numbers == @[1, 2, 1, 2, 1, 2, 1, 2, 1, 2], "Coroutines executed in incorrect order")
