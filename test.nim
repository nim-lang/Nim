import locks

var
  thr: array[0..4, Thread[tuple[a,b: int]]]
  L: Lock

proc threadFunc(interval: tuple[a,b: int]) {.thread.} =
  for i in interval.a..interval.b:
    acquire(L) # lock stdout
    echo i
    release(L)

initLock(L)

for i in 0..high(thr):
  createThread(thr[i], threadFunc, (i*10, i*10+5))
joinThreads(thr)

deinitLock(L)