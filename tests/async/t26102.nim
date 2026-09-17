import std/[asyncdispatch, os, typedthreads]

when defined(posix):
  proc openFds(): int =
    for _ in walkDir("/proc/self/fd"): inc result

  proc checkNoLeak =
    let before = openFds()
    for i in 0 ..< 10:
      setGlobalDispatcher(newDispatcher())
      waitFor sleepAsync(1)
      setGlobalDispatcher(nil)
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
    let after = openFds()
    doAssert after == before,
      "a terminated thread leaked " & $(after - before) & " dispatcher fds"

  checkNoLeak()
  checkThreadNoLeak()

echo "ok"
