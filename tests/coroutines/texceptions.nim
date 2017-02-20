import coro
var
  stackCheckValue = 1100220033
  numbers = newSeq[int](10)
  i = 0

proc testExceptions(id: int, sleep: float) =
  try:
    numbers[i] = id; inc(i)
    suspend(sleep)
    numbers[i] = id; inc(i)
    raise (ref ValueError)()
  except:
    numbers[i] = id; inc(i)
    suspend(sleep)
    numbers[i] = id; inc(i)
  suspend(sleep)
  numbers[i] = id; inc(i)

start(proc() = testExceptions(1, 0.01))
start(proc() = testExceptions(2, 0.011))
run()
doAssert(stackCheckValue == 1100220033, "Thread stack got corrupted")
doAssert(numbers == @[1, 2, 1, 2, 1, 2, 1, 2, 1, 2], "Coroutines executed in incorrect order")
