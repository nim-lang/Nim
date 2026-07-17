discard """
  matrix: "--mm:arc; --mm:orc"
  disabled: "windows"
  output: "ok"
"""

import std/posix

var
  escaped: array[2, pointer]
  locallyFreedPage: pointer

proc worker(_: pointer): pointer {.noconv.} =
  # Repeated setup/teardown on one foreign thread must create independent
  # allocator lifetimes without affecting Nim-managed threads.
  for i in 0..<escaped.len:
    setupForeignThreadGc()
    escaped[i] = allocShared(sizeof(int))
    cast[ptr int](escaped[i])[] = i
    tearDownForeignThreadGc()

  setupForeignThreadGc()
  let p = allocShared(sizeof(int))
  cast[ptr int](p)[] = 42
  locallyFreedPage = p
  deallocShared(p)
  tearDownForeignThreadGc()
  result = nil

proc getpagesize(): cint {.importc, header: "<unistd.h>".}
proc mincore(p: pointer, length: csize_t, residency: ptr uint8): cint {.
  importc, header: "<sys/mman.h>".}

proc isResident(p: pointer): bool =
  let pageSize = uint(getpagesize())
  let page = cast[pointer](cast[uint](p) - cast[uint](p) mod pageSize)
  var residency: uint8
  result = mincore(page, csize_t(pageSize), addr residency) == 0 and
    (residency and 1) != 0

var thread: Pthread
doAssert pthread_create(addr thread, nil, worker, nil) == 0
doAssert pthread_join(thread, nil) == 0

for i, p in escaped:
  doAssert cast[ptr int](p)[] == i
  doAssert isResident(p)
  deallocShared(p)
  doAssert not isResident(p)

# With no escaped allocations, foreign teardown performs reclamation itself.
doAssert not isResident(locallyFreedPage)

echo "ok"
