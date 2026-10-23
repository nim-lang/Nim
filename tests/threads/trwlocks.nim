discard """
  targets: "c cpp"
  matrix: "--mm:orc; --mm:refc"
  disabled: "genode"
"""

import std/[assertions, typedthreads]
include system/rwlocks

var
  lock: RwLock
  value: int

proc increment() {.thread.} =
  ## Updates the shared value while holding the write lock.
  for i in 0 ..< 1000:
    withWriteLock(lock):
      inc value

initRwLock(lock)

block:
  var workers: array[2, Thread[void]]
  for worker in workers.mitems:
    createThread(worker, increment)
  joinThreads(workers)

withReadLock(lock):
  doAssert value == 2000

deinitRwLock(lock)
