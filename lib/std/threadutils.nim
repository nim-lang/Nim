import std/locks

var lock: Lock
initLock(lock)

# var lockSubs: seq[Lock]

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
  # var lockIndex {.global.}: int
  # TODO is atomic needed?
  if not witness:
    # var lockSub {.global.}: Lock
    # initLock(lock)
    withLock lock:
      # lockSubs
      if not witness:
        witness = true
        # this could take a while
        # lockSubs
        # lockIndex
        body

template onceThread*(body: untyped) =
  # var witness {.threadvar.}: bool
  # var witness {.threadvar, inject.}: bool
  var witness {.threadvar, global.}: bool
  if not witness:
    echo "here"
    witness = true
    body
