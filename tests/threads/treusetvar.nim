discard """
  outputsub: "65"
"""

import locks

type
  MarkerObj = object
    lock: Lock
    counter: int
  Marker = ptr MarkerObj

const
  ThreadsCount = 65

proc worker(p: Marker) {.thread.} =
  acquire(p.lock)
  inc(p.counter)
  release(p.lock)

var p = cast[Marker](allocShared0(sizeof(MarkerObj)))
initLock(p.lock)

for i in 0..(ThreadsCount - 1):
  var thread: Thread[Marker]
  createThread(thread, worker, p)
  joinThread(thread)
echo p.counter
