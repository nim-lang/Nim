import std/locks

var lock: Lock
initLock(lock)

template onceGlobal*(retryOnFailure: bool, body: untyped) =
  ## Evaluate `body` once, even in presence of multiple threads. If `body` is
  ## executing in thread A, thread B will block until A returns from this block.
  ## Each template instantiation of `onceGlobal` has its own lock to avoid blocking
  ## each other.
  ## If thread A raises, whether thread B re-executes `body` depends on whether
  ## `retryOnFailure`.
  runnableExamples "--threads":
    from std/os import sleep
    var thr: array[2, Thread[void]]
    var count = 0
    var count2 = 0
    proc threadFunc() {.thread.} =
      for j in 0..<3:
        onceGlobal:
          while count2 == 0: sleep(10)
          count.inc
      doAssert count == 1
    for t in mitems(thr): t.createThread threadFunc
    for j in 0..<3:
      onceGlobal: # no deadlock, this has its own lock
        sleep(10)
        count2.inc
    doAssert count2 == 1
    joinThreads(thr)
  runnableExamples:
    # each instantiation is independant:
    var count = 0
    proc bar[T](a: T): int =
      onceGlobal: count.inc
      result = count
    doAssert bar(1) == 1
    doAssert bar(2) == 1
    doAssert bar(3.1) == 2
    doAssert bar(4.2) == 2
    doAssert bar(5.1'f32) == 3

  var witness {.global.}: int
  var lock2 {.global.}: Lock

  # TODO is atomic needed?
  if witness < 2:
    withLock lock:
      if witness == 0:
        initLock(lock2)
        witness = 1
    # we release the single `lock` to avoid blocking unrelated `onceGlobal` calls.
    if witness == 1:
      withLock lock2:
        if witness == 1:
          # TODO: add option `retryOnFailure`, see https://github.com/nim-lang/Nim/pull/16192/files#r540648534
          # and make sure we don't nest 2 levels of try/finally (withLock uses 1 already)
          try:
            # `witness = 2` must not occur before `body` otherwise next callers will return immediately
            body
            if retryOnFailure: witness = 2
          finally:
            if not retryOnFailure: witness = 2

template onceGlobal*(body: untyped) =
  ## overload with `retryOnFailure = false`.
  onceGlobal(false, body)

template onceThread*(body: untyped) =
  ## Evaluate `body` once per thread. Like `onceGlobal`, each instantiation
  ## is independant.
  runnableExamples:
    var count = 0
    proc fn(n: int) =
      for i in 0..<3:
        onceThread:
          count.inc
      if n > 1: fn(n-1) # re-entrant code
    fn(3)
    doAssert count == 1
    onceThread: # each instance is unique
      count.inc
    doAssert count == 2

  var witness {.threadvar, global.}: bool
  if not witness:
    body
    witness = true
