import atomics
import locks


type
  Once* = object
    finished: Atomic[bool]
    lock: Lock

proc initOnce*(once: var Once) =
  once.finished.store(false)
  initLock(once.lock)

template once*(alreadyExecuted: Once, body: untyped) =
  runnableExamples:
    var block1: Once
    var count = 0
    initOnce(block1)


    for i in 1 .. 10:
      once(block1):
        inc count

    doAssert count == 1
  if not alreadyExecuted.finished.load:
    withLock alreadyExecuted.lock:
      try:
        body
      finally:
        alreadyExecuted.finished.store(true)
