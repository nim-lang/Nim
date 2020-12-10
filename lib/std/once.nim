import std/[atomics, locks]


type
  Once* = object    ## A object that ensures a block of code is executed once.
    finished: Atomic[bool]
    lock: Lock

proc initOnce*(once: var Once) =
  ## Initializes a `Once` object.
  once.finished.store(false)
  initLock(once.lock)

template once*(cond: Once, body: untyped) =
  ## Executes a block of code only once (the first time the block is reached).
  ## It is thread-safe.
  runnableExamples:
    var block1: Once
    var count = 0
    initOnce(block1)

    for i in 1 .. 10:
      once(block1):
        inc count

      # only the first `block1` is executed
      once(block1):
        count = 888

    doAssert count == 1

  if not cond.finished.load(moAcquire):
    withLock cond.lock:
      # TODO load a value without atomic
      if not cond.finished.load(moRelaxed):
        try:
          body
        finally:
          cond.finished.store(true, moRelease)
