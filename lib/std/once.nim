when compileOption("threads"):
  import std/[atomics, locks]


type
  Once* = object    ## A object that ensures a block of code is executed once.
    when compileOption("threads"):
      finished: Atomic[bool]
      lock: Lock
    else:
      finished: bool

proc `=destroy`*(once: var Once) {.inline.} =
  when compileOption("threads"):
    deinitLock(once.lock)

proc init*(once: var Once) =
  ## Initializes a `Once` object.
  when compileOption("threads"):
    once.finished.store(false, moRelaxed)
    initLock(once.lock)

template once*(cond: var Once, body: untyped) =
  ## Executes a block of code only once (the first time the block is reached).
  ## It is thread-safe.
  runnableExamples("--gc:orc --threads:on"):
    var block1: Once
    var count = 0
    init(block1)

    for i in 1 .. 10:
      once(block1):
        inc count

      # only the first `block1` is executed
      once(block1):
        count = 888

    assert count == 1

  when compileOption("threads"):
    if not cond.finished.load(moAcquire):
      withLock cond.lock:
        if not cond.finished.load(moRelaxed):
          try:
            body
          finally:
            cond.finished.store(true, moRelease)
  else:
    if not cond.finished:
      try:
        body
      finally:
        cond.finished = true


## The code block is executed only once among threads.
runnableExamples("--gc:orc --threads:on"):
  block:
    var thr: array[0..4, Thread[void]]
    var block1: Once
    var count = 0
    init(block1)
    proc threadFunc() {.thread.} =
      for i in 1 .. 10:
        once(block1):
          inc count
    for i in 0..high(thr):
      createThread(thr[i], threadFunc)
    joinThreads(thr)
    assert count == 1

## The code blocks is executed per thread.
runnableExamples("--gc:orc --threads:on"):
  block:
    var thr: array[0..4, Thread[void]]
    var count = 0
    proc threadFunc() {.thread.} =
      var block1: Once
      init(block1)
      for i in 1 .. 10:
        once(block1):
          inc count
    for i in 0..high(thr):
      createThread(thr[i], threadFunc)
    joinThreads(thr)
    assert count == thr.len
