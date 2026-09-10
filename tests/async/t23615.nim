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
  GC_fullCollect()

let stats = getAllocStats()
doAssert stats.allocCount - stats.deallocCount < 10, $stats
echo "ok"
