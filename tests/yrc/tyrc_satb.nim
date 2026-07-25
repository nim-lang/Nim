discard """
  cmd: "nim c --mm:yrc -d:useMalloc --threads:on $file"
  output: "ok"
  disabled: "windows"
  disabled: "freebsd"
  disabled: "openbsd"
"""

# Concurrent stress for the lock-free SATB collector: mutator threads rewire
# live cyclic structures (constant dirty traffic + capture aborts) and churn
# garbage cycles while a dedicated thread runs back-to-back collections. Live
# data corruption or a lost object trips a doAssert / a growing residual.

import std/typedthreads

type Node = ref object
  next: Node        # ring structure, stable
  payload: Node     # rewired constantly -> candidates + dirty SCCs
  id: int

const NWorkers = 3
const Iters = 400_000
const RingLen = 64

var stopFlag: bool
var done: array[NWorkers, int]

proc mkRing(tag: int): seq[Node] =
  result = newSeq[Node](RingLen)
  for i in 0 ..< RingLen: result[i] = Node(id: tag + i)
  for i in 0 ..< RingLen:
    result[i].next = result[(i+1) mod RingLen]
    result[i].payload = result[(i*13+7) mod RingLen]

proc verify(ring: seq[Node]; tag: int) =
  for i in 0 ..< RingLen:
    doAssert ring[i].id == tag + i, "node corrupted"
    doAssert ring[i].next.id == tag + (i+1) mod RingLen, "ring broken"
    doAssert ring[i].payload.id >= tag and ring[i].payload.id < tag + RingLen,
      "payload points outside ring: live data corrupted"

proc worker(tid: int) {.thread.} =
  var tag = tid * 1_000_000
  var ring = mkRing(tag)
  for i in 0 ..< Iters:
    # lock-free barrier hot path: rewire a payload edge inside the live ring.
    # decs the old target (rc > 0) -> candidate; collections capture the live
    # ring concurrently and must rescue or abort, never free it.
    ring[i mod RingLen].payload = ring[(i * 7 + 3) mod RingLen]
    if (i and 8191) == 0:
      verify(ring, tag)
    if (i and 32767) == 0:
      inc tag, RingLen
      ring = mkRing(tag)   # old ring becomes a garbage cycle tangle
  verify(ring, tag)
  done[tid] = 1

proc collector() {.thread.} =
  while not stopFlag:
    GC_runOrc()

var th: array[NWorkers, Thread[int]]
var col: Thread[void]
createThread(col, collector)
for i in 0 ..< NWorkers: createThread(th[i], worker, i)
joinThreads(th)
stopFlag = true
joinThread(col)
for i in 0 ..< NWorkers: doAssert done[i] == 1
GC_fullCollect()
GC_fullCollect()
echo "ok"
