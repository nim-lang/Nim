discard """
  valgrind: true
  cmd: '''nim c --mm:arc -d:nimAllocStats -d:useMalloc $file'''
  output: '''1000'''
"""

import std/asyncdispatch

var count: int

proc stuff() {.async.} =
  #echo count, 1
  await sleepAsync(1)
  #echo count, 2
  count.inc

for _ in 0..<1000:
  asyncCheck stuff()

while hasPendingOperations(): poll()

echo count

setGlobalDispatcher(nil)
# the last dispatcher can stay rooted by a stale stack reference until the
# stack region is reused, and some memory managers defer the final
# destruction by one collection cycle
proc churn(n: int) {.gcsafe.} =
  if n > 0: churn(n - 1)
GC_fullCollect()
churn(1000)
GC_fullCollect()

import std/importutils
privateAccess(AllocStats)
doAssert getAllocStats().allocCount - getAllocStats().deallocCount < 10
