import std/[asyncdispatch, os, typedthreads]

when defined(posix):
  proc openFds(): int =
    for _ in walkDir("/proc/self/fd"): inc result

  proc churn(n: int) {.gcsafe.} =
    # overwrites deep stack frames so that stale stack references to the
    # dropped dispatcher (conservative stack scanning) die
    if n > 0: churn(n - 1)

  proc collectFully() =
    # two collections: some memory managers defer the final destruction of
    # the dropped dispatcher's selector by one collection cycle
    GC_fullCollect()
    churn(1000)
    GC_fullCollect()

  proc checkNoLeak =
    let before = openFds()
    for i in 0 ..< 10:
      setGlobalDispatcher(newDispatcher())
      waitFor sleepAsync(1)
      setGlobalDispatcher(nil)
    collectFully()
    let after = openFds()
    doAssert after == before,
      "dropping a dispatcher leaked " & $(after - before) & " fds"

  proc worker() =
    discard getGlobalDispatcher()
    waitFor sleepAsync(1)

  proc checkThreadNoLeak =
    let before = openFds()
    var t: Thread[void]
    createThread(t, worker)
    joinThread(t)
    collectFully()
    let after = openFds()
    doAssert after == before,
      "a terminated thread leaked " & $(after - before) & " dispatcher fds"

  checkNoLeak()
  checkThreadNoLeak()

echo "ok"
