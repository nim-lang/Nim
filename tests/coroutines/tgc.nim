discard """
  target: "c"
"""

import coro

var maxOccupiedMemory = 0

proc testGC() =
  var numbers = newSeq[int](100)
  maxOccupiedMemory = max(maxOccupiedMemory, getOccupiedMem())
  suspend(0)

start(testGC)
start(testGC)
run()

GC_fullCollect()
doAssert(getOccupiedMem() < maxOccupiedMemory, "GC did not free any memory allocated in coroutines")
