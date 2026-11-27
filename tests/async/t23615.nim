discard """
  valgrind: true
  cmd: '''nim c --mm:orc -d:nimAllocStats -d:useMalloc $file'''
  output: '''ok'''
"""

# bug #23615: exceptions caught by a typed except branch in a closure
# iterator (and thus in any async proc) leaked under ARC/ORC.

import std/[asyncdispatch, importutils]

privateAccess(AllocStats)

block: # pure closure iterator, the minimal form of the bug
  proc runIter() =
    iterator it(): int {.closure.} =
      try:
        yield 1
        raise newException(ValueError, "x")
      except ValueError:
        discard
      yield 2
    var f = it
    doAssert f() == 1
    doAssert f() == 2
  let base = getAllocStats()
  runIter()
  GC_fullCollect()
  let after = getAllocStats()
  doAssert after.allocCount - after.deallocCount ==
           base.allocCount - base.deallocCount, $base & " " & $after

block: # the async incarnation from the issue
  proc err {.async.} =
    raise newException(ValueError, "err1")

  proc amain {.async.} =
    await sleepAsync(1)
    for _ in 0..<50:
      try:
        await err()
      except ValueError:
        discard

  waitFor amain()
  doAssert not hasPendingOperations()
  setGlobalDispatcher(nil)
  # the dispatcher can stay rooted by a stale stack reference until the
  # stack region is overwritten, and some memory managers defer the final
  # destruction by one collection cycle
  proc churn(n: int) =
    if n > 0: churn(n - 1)
  GC_fullCollect()
  churn(1000)
  GC_fullCollect()

let stats = getAllocStats()
doAssert stats.allocCount - stats.deallocCount < 10, $stats
echo "ok"
