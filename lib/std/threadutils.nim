import std/locks

var lock: Lock
initLock(lock)

template onceGlobal*(body: untyped) =
  ## evaluate `body` once, even in presence of multiple threads.
  runnableExamples "--threads":
    var thr: array[2, Thread[void]]
    var count = 0
    proc threadFunc() {.thread.} =
      onceGlobal: count.inc
      doAssert count == 1
    for t in mitems(thr): t.createThread threadFunc
    joinThreads(thr)

  var witness {.global.}: bool
  withLock lock:
    if not witness:
      witness = true
      body

template onceThread*(body: untyped) =
  # var witness {.threadvar.}: bool
  # var witness {.threadvar, inject.}: bool
  var witness {.threadvar, global.}: bool
  if not witness:
    echo "here"
    witness = true
    body
