discard """
  matrix: "--mm:arc --threads:on; --mm:orc --threads:on"
  output: "ok"
  timeout: "30"
"""

import std/[atomics, typedthreads]

const
  pointerCount = 512
  drainCount = 2048
  iterations {.intdefine.} = 200
  sizes = [16, 64, 4000, 4096, 8192]

var
  pointers: array[pointerCount, pointer]
  mayExit: Atomic[bool]

proc owner() {.thread.} =
  for i in 0..<pointers.len:
    let size = sizes[i mod sizes.len]
    pointers[i] = allocShared(size)
    cast[ptr byte](pointers[i])[] = byte(i)

proc borrower() {.thread.} =
  while not mayExit.load(moAcquire):
    discard

proc drain() {.thread.} =
  var drained: array[drainCount, pointer]
  for i in 0..<drained.len:
    drained[i] = allocShared(sizes[i mod sizes.len])
  for p in drained:
    deallocShared(p)
  let occupied = getOccupiedMem()
  doAssert occupied == 0, "allocator retained " & $occupied & " bytes"

for _ in 0..<iterations:
  # The owner retires with live small and big allocations. The borrower checks
  # out that region while this already-running main thread returns the cells.
  # This races foreign queue publication against both directions of the
  # MemRegion handoff without creating an unbounded number of regions.
  block:
    var thread: Thread[void]
    createThread(thread, owner)
    joinThread(thread)

  mayExit.store(false, moRelaxed)
  var borrowerThread: Thread[void]
  createThread(borrowerThread, borrower)
  for i, p in pointers:
    if i == pointers.len div 2:
      # Let the borrower tear the allocator down while the second half of the
      # foreign publications are still in flight.
      mayExit.store(true, moRelease)
    deallocShared(p)
  joinThread(borrowerThread)

  block:
    var thread: Thread[void]
    createThread(thread, drain)
    joinThread(thread)

echo "ok"
