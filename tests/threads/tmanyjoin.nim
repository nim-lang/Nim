discard """
  outputsub: "129"
"""

import os, locks

type
  MarkerObj = object
    lock: Lock
    counter: int
  Marker = ptr MarkerObj

const
  ThreadsCount = 129
  SleepTime = 250

proc worker(p: Marker) {.thread.} =
  acquire(p.lock)
  inc(p.counter)
  release(p.lock)
  sleep(SleepTime)

var p = cast[Marker](allocShared0(sizeof(MarkerObj)))
initLock(p.lock)
var ts = newSeq[Thread[Marker]](ThreadsCount)
for i in 0..<ts.len:
  createThread(ts[i], worker, p)

joinThreads(ts)
echo p.counter
