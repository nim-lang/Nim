discard """
  matrix: "--mm:arc --threads:on; --mm:orc --threads:on"
  output: "ok"
"""

import std/[atomics, typedthreads]

const concurrentThreads = 4

var
  escaped: pointer
  reused: pointer
  bigEscaped: pointer
  roundAddresses: array[2, array[concurrentThreads, pointer]]
  ready: Atomic[int]
  mayExit: Atomic[bool]

proc allocateEscaped() {.thread.} =
  escaped = allocShared(64)
  cast[ptr int](escaped)[] = 42

proc consumeAfterHandoff() {.thread.} =
  doAssert cast[ptr int](escaped)[] == 42
  deallocShared(escaped)
  reused = allocShared(64)
  doAssert reused == escaped
  deallocShared(reused)

# A live allocation can outlast its original thread. The next thread receives
# the same allocator and its stable handle makes the deallocation local again.
block:
  var thread: Thread[void]
  createThread(thread, allocateEscaped)
  joinThread(thread)
  createThread(thread, consumeAfterHandoff)
  joinThread(thread)

proc allocateBigEscaped() {.thread.} =
  bigEscaped = allocShared(8192)
  cast[ptr int](bigEscaped)[] = 91

proc consumeBigAfterHandoff() {.thread.} =
  doAssert cast[ptr int](bigEscaped)[] == 91
  deallocShared(bigEscaped)
  let p = allocShared(8192)
  doAssert p == bigEscaped
  deallocShared(p)

# Big chunks use a separate deferred-free queue on the stable handle.
block:
  var thread: Thread[void]
  createThread(thread, allocateBigEscaped)
  joinThread(thread)
  createThread(thread, consumeBigAfterHandoff)
  joinThread(thread)

proc allocateConcurrently(arg: tuple[round, index: int]) {.thread.} =
  let p = allocShared(80)
  roundAddresses[arg.round][arg.index] = p
  deallocShared(p)
  discard ready.fetchAdd(1, moRelease)
  while not mayExit.load(moAcquire):
    discard

proc runConcurrentRound(round: int) =
  var threads: array[concurrentThreads, Thread[tuple[round, index: int]]]
  ready.store(0, moRelaxed)
  mayExit.store(false, moRelaxed)
  for i in 0..<threads.len:
    createThread(threads[i], allocateConcurrently, (round, i))
  while ready.load(moAcquire) != concurrentThreads:
    discard
  mayExit.store(true, moRelease)
  for thread in threads.mitems:
    joinThread(thread)

# The first round establishes the peak number of simultaneous allocators. The
# following rounds must reuse those regions instead of reserving one region per
# new thread.
runConcurrentRound(0)
for _ in 0..<32:
  runConcurrentRound(1)
  for p in roundAddresses[1]:
    var found = false
    for old in roundAddresses[0]:
      if p == old:
        found = true
        break
    doAssert found

echo "ok"
