discard """
  matrix: "--mm:arc; --mm:orc"
  valgrind: true
  output: "ok"
"""

import std/[atomics, typedthreads]
when defined(posix):
  import ./mincoreutils

var escaped: pointer

proc allocateInThread() {.thread.} =
  escaped = allocShared(sizeof(int))
  cast[ptr int](escaped)[] = 42

# The allocation keeps the worker's RegionHandle alive after the worker exits.
# Deallocating it from this thread must release both the allocation and the
# abandoned region. Repetition also exercises reuse of the worker's TLS slot.
for _ in 0..<32:
  var thread: Thread[void]
  createThread(thread, allocateInThread)
  joinThread(thread)

  doAssert cast[ptr int](escaped)[] == 42
  when defined(posix):
    doAssert isResident(escaped)
    let allocationPage = escaped
  deallocShared(escaped)
  when defined(posix):
    # The final remote deallocation releases the abandoned region and its pages.
    doAssert not isResident(allocationPage)
  escaped = nil

# Exercise the opposite finalization order: the allocation is remotely freed
# while its owner is still running, so the owner must reclaim the region when
# it subsequently exits.
var
  allocationReady: Atomic[bool]
  ownerMayExit: Atomic[bool]

proc allocateAndWait() {.thread.} =
  escaped = allocShared(sizeof(int))
  cast[ptr int](escaped)[] = 42
  allocationReady.store(true, moRelease)
  while not ownerMayExit.load(moAcquire):
    discard

var waitingThread: Thread[void]
createThread(waitingThread, allocateAndWait)
while not allocationReady.load(moAcquire):
  discard

when defined(posix):
  let remotelyFreedPage = escaped
deallocShared(escaped)
when defined(posix):
  doAssert isResident(remotelyFreedPage)
escaped = nil
ownerMayExit.store(true, moRelease)
joinThread(waitingThread)
when defined(posix):
  doAssert not isResident(remotelyFreedPage)

# Exercise remote frees that the owner consumes before it exits. Lifetime
# accounting remains matched even after the cells re-enter the local allocator.
const remotePointerCount = 257
var
  remotePointers: array[remotePointerCount, pointer]
  remotePointersReady: Atomic[bool]
  ownerMayConsume: Atomic[bool]

proc allocateConsumeAndExit() {.thread.} =
  for i in 0..<remotePointers.len:
    remotePointers[i] = allocShared(16 + (i mod 8) * 16)
  remotePointersReady.store(true, moRelease)
  while not ownerMayConsume.load(moAcquire):
    discard

  for i in 0..<8:
    let p = allocShared(16 + i * 16)
    deallocShared(p)
  doAssert getOccupiedMem() == 0

var consumingThread: Thread[void]
createThread(consumingThread, allocateConsumeAndExit)
while not remotePointersReady.load(moAcquire):
  discard
for p in remotePointers:
  deallocShared(p)
ownerMayConsume.store(true, moRelease)
joinThread(consumingThread)

# A region whose allocations were all freed locally has a zero lifetime balance;
# its handle and backing pages are reclaimed directly by the exiting owner.
var locallyFreedPage: pointer

proc allocateAndFreeLocally() {.thread.} =
  let p = allocShared(sizeof(int))
  cast[ptr int](p)[] = 23
  locallyFreedPage = p
  deallocShared(p)

var locallyFreeingThread: Thread[void]
createThread(locallyFreeingThread, allocateAndFreeLocally)
joinThread(locallyFreeingThread)
when defined(posix):
  doAssert not isResident(locallyFreedPage)

echo "ok"
