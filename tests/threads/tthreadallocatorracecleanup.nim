discard """
  matrix: "--mm:arc; --mm:orc"
  output: "ok"
"""

import std/[atomics, typedthreads]

const
  pointerCount = 1024
  iterations = 100

var
  pointers: array[pointerCount, pointer]
  drainPointers: array[pointerCount, pointer]
  ready: Atomic[bool]
  start: Atomic[bool]
  remoteDone: Atomic[bool]

proc owner() {.thread.} =
  for i in 0..<pointers.len:
    pointers[i] = allocShared(16 + (i mod 8) * 16)
  ready.store(true, moRelease)
  while not start.load(moAcquire):
    discard

  # Race allocator activity against remote frees. The owner can consume cells
  # while the remote thread is still publishing more queue entries.
  while not remoteDone.load(moAcquire):
    for i in 0..<8:
      let p = allocShared(16 + i * 16)
      deallocShared(p)

  # Exhaust local free lists so all remaining remote lists are consumed before
  # abandonment.
  for i in 0..<drainPointers.len:
    drainPointers[i] = allocShared(16 + (i mod 8) * 16)
  for p in drainPointers:
    deallocShared(p)
  doAssert getOccupiedMem() == 0

for iteration in 0..<iterations:
  ready.store(false, moRelaxed)
  start.store(false, moRelaxed)
  remoteDone.store(false, moRelaxed)
  var thread: Thread[void]
  createThread(thread, owner)
  while not ready.load(moAcquire):
    discard
  start.store(true, moRelease)
  for p in pointers:
    deallocShared(p)
  remoteDone.store(true, moRelease)
  joinThread(thread)

echo "ok"
