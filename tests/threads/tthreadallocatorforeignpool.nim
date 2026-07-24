discard """
  matrix: "--mm:arc --threads:on --tlsEmulation:off; --mm:orc --threads:on --tlsEmulation:off"
  disabled: "windows"
  output: "ok"
"""

import std/posix

var
  escaped: pointer
  reused: pointer

proc allocateOnForeignThread(_: pointer): pointer {.noconv.} =
  setupForeignThreadGc()
  escaped = allocShared(96)
  cast[ptr int](escaped)[] = 73
  tearDownForeignThreadGc()
  result = nil

proc reuseOnForeignThread(_: pointer): pointer {.noconv.} =
  setupForeignThreadGc()
  doAssert cast[ptr int](escaped)[] == 73
  deallocShared(escaped)
  reused = allocShared(96)
  doAssert reused == escaped
  deallocShared(reused)
  tearDownForeignThreadGc()
  result = nil

proc consumeDeferredFree(_: pointer): pointer {.noconv.} =
  setupForeignThreadGc()
  let first = allocShared(96)
  let second = allocShared(96)
  # The first allocation advances the active chunk and collects its deferred
  # foreign frees. The next allocation reuses the remotely returned cell.
  doAssert second == escaped
  deallocShared(first)
  deallocShared(second)
  tearDownForeignThreadGc()
  result = nil

proc run(worker: proc(_: pointer): pointer {.noconv.}) =
  var thread: Pthread
  doAssert pthread_create(addr thread, nil, worker, nil) == 0
  doAssert pthread_join(thread, nil) == 0

# setup/teardown is the checkout/return boundary. A distinct native thread can
# safely inherit the allocator even while one of its allocations is still live.
run(allocateOnForeignThread)
run(reuseOnForeignThread)

# A free that arrives while the allocator is idle is queued on its handle and
# consumed after that allocator is handed to another foreign thread.
run(allocateOnForeignThread)
deallocShared(escaped)
run(consumeDeferredFree)

echo "ok"
