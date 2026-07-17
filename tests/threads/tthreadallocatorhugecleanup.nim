discard """
  matrix: "--mm:arc; --mm:orc"
  disabled: "windows"
  output: "ok"
"""

import std/typedthreads

const hugeAllocationSize =
  # These are the allocator's MaxFli boundaries. The 64-bit POSIX mapping is
  # virtual; this test only commits the page touched below.
  when sizeof(int) == 8: 1 shl 30
  else: 16 * 1024

var
  escaped: pointer
  ordinaryEscaped: pointer

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

proc allocateHugeChunk() {.thread.} =
  ordinaryEscaped = allocShared(sizeof(int))
  cast[ptr int](ordinaryEscaped)[] = 17
  escaped = allocShared(hugeAllocationSize)
  cast[ptr byte](escaped)[] = 42

var thread: Thread[void]
createThread(thread, allocateHugeChunk)
joinThread(thread)

doAssert cast[ptr byte](escaped)[] == 42
doAssert cast[ptr int](ordinaryEscaped)[] == 17
when defined(posix):
  doAssert isResident(escaped)
  doAssert isResident(ordinaryEscaped)
  let
    allocationPage = escaped
    ordinaryAllocationPage = ordinaryEscaped

# The ordinary chunk is covered by the handle's orphaned heap links. Its page
# stays mapped until the huge allocation performs the final remote release.
deallocShared(ordinaryEscaped)
when defined(posix):
  doAssert isResident(allocationPage)
  doAssert isResident(ordinaryAllocationPage)
deallocShared(escaped)
when defined(posix):
  # Huge chunks bypass heapLinks and must be drained from the abandoned
  # handle's deferred big-chunk list before the ordinary pages are released.
  doAssert not isResident(allocationPage)
  doAssert not isResident(ordinaryAllocationPage)

echo "ok"
