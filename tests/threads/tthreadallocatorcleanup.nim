discard """
  matrix: "--mm:arc; --mm:orc"
  valgrind: true
  output: "ok"
"""

import std/[atomics, typedthreads]

var escaped: pointer

when defined(posix):
  proc getpagesize(): cint {.importc, header: "<unistd.h>".}
  proc mincore(p: pointer, length: csize_t, residency: ptr uint8): cint {.
    importc, header: "<sys/mman.h>".}

  proc isResident(p: pointer): bool =
    let pageSize = uint(getpagesize())
    let page = cast[pointer](cast[uint](p) - cast[uint](p) mod pageSize)
    var residency: uint8
    result = mincore(page, csize_t(pageSize), addr residency) == 0 and
      (residency and 1) != 0

proc allocateInThread() {.thread.} =
  escaped = allocShared(sizeof(int))
  cast[ptr int](escaped)[] = 42

# The allocation keeps the worker's MemRegion alive after the worker exits.
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

echo "ok"
