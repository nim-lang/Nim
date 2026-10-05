discard """
  matrix: "--mm:arc; --mm:orc"
"""

import std/[atomics, typedthreads]

const numChunks = 23 # More than the allocator's bounded drain can process.

var
  pointers: array[numChunks, pointer]
  allocated: Atomic[bool]
  continueAllocating: Atomic[bool]

proc allocPointers() {.thread.} =
  for i in 0..<pointers.len:
    pointers[i] = allocShared(8192)
  allocated.store(true, moRelease)

  while not continueAllocating.load(moAcquire):
    discard

  # The first allocation drains MaxSteps + 1 chunks. The second allocation
  # must still be able to find and drain the remainder.
  for _ in 0..1:
    let p = allocShared(8192)
    deallocShared(p)

  doAssert getOccupiedMem() == 0

var thread: Thread[void]
createThread(thread, allocPointers)

while not allocated.load(moAcquire):
  discard

for p in pointers:
  deallocShared(p)
continueAllocating.store(true, moRelease)

joinThread(thread)
