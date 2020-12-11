import std/locks
import timn/dbgs

var lock: Lock
initLock(lock) # xxx instead, do this on 1st call to `onceGlobal`, using `atomic`.

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

  var witness {.global.}: int
  var lock2 {.global.}: Lock
  # TODO is atomic needed?
  if witness < 2:
    withLock lock:
      if witness == 0:
        # dbg "initLock", astToStr(lock2), astToStr(body)
        initLock(lock2)
        witness = 1
    # we release the single `lock` to avoid blocking unrelated `onceGlobal` calls.
    if witness == 1:
      withLock lock2:
        if witness == 1:
          # TODO: add option `retryOnFailure`, see https://github.com/nim-lang/Nim/pull/16192/files#r540648534
          # and make sure we don't nest 2 levels of try/finally (withLock uses 1 already)
          body
          witness = 2
            # this must occur after `body` otherwise next callers will return immediately

template onceThread*(body: untyped) =
  # var witness {.threadvar.}: bool
  # var witness {.threadvar, inject.}: bool
  var witness {.threadvar, global.}: bool
  if not witness:
    echo "here"
    witness = true
    body
