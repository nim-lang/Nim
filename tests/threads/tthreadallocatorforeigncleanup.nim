discard """
  matrix: "--mm:arc --tlsEmulation:off; --mm:orc --tlsEmulation:off"
  disabled: "windows"
  output: "ok"
"""

import std/posix
import ./mincoreutils

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
