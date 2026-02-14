# Benchmark comparing atomic RC vs YRC-style buffering
# Uses `ptr` to avoid current implementation quirks

import std/[locks, atomics, os, strutils, times]

const
  NumStripes = 64
  QueueSize = 128
  NumThreads = 8
  OperationsPerThread = 1_000_000
  TestDuration = 5.0 # seconds

type
  Node = object
    rc: int # Atomic[int]
    data: int
    next: ptr Node

  Stripe = object
    toIncLen: int
    toInc: array[QueueSize, ptr Node]
    toDecLen: int
    toDec: array[QueueSize, ptr Node]

var
  gNonAtomicNodes: seq[ptr Node]
  gAtomicNodes: seq[ptr Node]
  gBufferedNodes: seq[ptr Node]
  stripes: array[NumStripes, Stripe]
  gGlobalLock: Lock
  roots: seq[ptr Node]

proc getStripeIdx(): int =
  getThreadId() and (NumStripes - 1)

# Non-atomic RC implementation (baseline - fastest possible)
proc nonAtomicIncRef(n: ptr Node) {.inline.} =
  inc n.rc

proc nonAtomicDecRef(n: ptr Node): bool {.inline.} =
  dec n.rc
  result = n.rc == 0

# Atomic RC implementation (like atomicArc)
proc atomicIncRef(n: ptr Node) {.inline.} =
  discard atomicFetchAdd(n.rc.addr, 1, ATOMIC_RELEASE)

proc atomicDecRef(n: ptr Node): bool {.inline.} =
  let old = atomicFetchSub(n.rc.addr, 1, ATOMIC_ACQ_REL)
  result = old == 1

# YRC-style buffering implementation (using atomics like -d:yrcAtomics)
proc bufferedIncRef(n: ptr Node) {.inline.} =
  let s = getStripeIdx()
  let slot = atomicFetchAdd(addr stripes[s].toIncLen, 1, ATOMIC_ACQ_REL)
  if slot < QueueSize:
    atomicStoreN(stripes[s].toInc[slot].addr, n, ATOMIC_RELEASE)
  else:
    # Overflow - merge immediately under global lock
    withLock gGlobalLock:
      discard atomicFetchAdd(n.rc.addr, 1, ATOMIC_RELEASE)
      for i in 0..<NumStripes:
        let len = atomicExchangeN(stripes[i].toIncLen.addr, 0, ATOMIC_ACQUIRE)
        for j in 0..<min(len, QueueSize):
          let x = atomicLoadN(stripes[i].toInc[j].addr, ATOMIC_ACQUIRE)
          discard atomicFetchAdd(x.rc.addr, 1, ATOMIC_RELEASE)

proc bufferedDecRef(n: ptr Node) {.inline.} =
  let s = getStripeIdx()
  let slot = atomicFetchAdd(stripes[s].toDecLen.addr, 1, ATOMIC_ACQ_REL)
  if slot < QueueSize:
    atomicStoreN(stripes[s].toDec[slot].addr, n, ATOMIC_RELEASE)
  else:
    # Overflow - merge immediately under global lock
    withLock gGlobalLock:
      let old = atomicFetchSub(n.rc.addr, 1, ATOMIC_ACQ_REL)
      if old == 1:
        roots.add(n)
      for i in 0..<NumStripes:
        let len = atomicExchangeN(stripes[i].toDecLen.addr, 0, ATOMIC_ACQUIRE)
        for j in 0..<min(len, QueueSize):
          let x = atomicLoadN(stripes[i].toDec[j].addr, ATOMIC_ACQUIRE)
          let old = atomicFetchSub(x.rc.addr, 1, ATOMIC_ACQ_REL)
          if old == 1:
            roots.add(x)

proc mergePendingOps() =
  withLock gGlobalLock:
    for i in 0..<NumStripes:
      let incLen = atomicExchangeN(stripes[i].toIncLen.addr, 0, ATOMIC_ACQUIRE)
      for j in 0..<min(incLen, QueueSize):
        let x = atomicLoadN(stripes[i].toInc[j].addr, ATOMIC_ACQUIRE)
        discard atomicFetchAdd(x.rc.addr, 1, ATOMIC_RELEASE)
      let decLen = atomicExchangeN(stripes[i].toDecLen.addr, 0, ATOMIC_ACQUIRE)
      for j in 0..<min(decLen, QueueSize):
        let x = atomicLoadN(stripes[i].toDec[j].addr, ATOMIC_ACQUIRE)
        let old = atomicFetchSub(x.rc.addr, 1, ATOMIC_ACQ_REL)
        if old == 1:
          roots.add(x)

proc benchmarkNonAtomicRC() =
  var ops = 0
  let startTime = cpuTime()
  let endTime = startTime + TestDuration

  while cpuTime() < endTime:
    for i in 0..<OperationsPerThread:
      let idx = ops mod gNonAtomicNodes.len
      let node = gNonAtomicNodes[idx]
      nonAtomicIncRef(node)
      if nonAtomicDecRef(node):
        # Would free here, but we're just benchmarking RC ops
        discard
      ops += 1

  let elapsed = cpuTime() - startTime
  echo "Non-Atomic RC: ", ops, " ops in ", elapsed.formatFloat(ffDecimal, 3), "s = ",
       (ops.float / elapsed).formatFloat(ffDecimal, 0), " ops/s"

proc benchmarkAtomicRC() =
  var ops = 0
  let startTime = cpuTime()
  let endTime = startTime + TestDuration

  while cpuTime() < endTime:
    for i in 0..<OperationsPerThread:
      let idx = ops mod gAtomicNodes.len
      let node = gAtomicNodes[idx]
      atomicIncRef(node)
      if atomicDecRef(node):
        # Would free here, but we're just benchmarking RC ops
        discard
      ops += 1

  let elapsed = cpuTime() - startTime
  echo "Atomic RC: ", ops, " ops in ", elapsed.formatFloat(ffDecimal, 3), "s = ",
       (ops.float / elapsed).formatFloat(ffDecimal, 0), " ops/s"

proc benchmarkBufferedRC() =
  var ops = 0
  let startTime = cpuTime()
  let endTime = startTime + TestDuration

  while cpuTime() < endTime:
    for i in 0..<OperationsPerThread:
      let idx = ops mod gBufferedNodes.len
      let node = gBufferedNodes[idx]
      bufferedIncRef(node)
      bufferedDecRef(node)
      ops += 1

  # Final merge (simulating collection at end)
  mergePendingOps()
  let elapsed = cpuTime() - startTime
  echo "Buffered RC: ", ops, " ops in ", elapsed.formatFloat(ffDecimal, 3), "s = ",
       (ops.float / elapsed).formatFloat(ffDecimal, 0), " ops/s"

var gOpsAtomic: int64
var gOpsBuffered: int64

proc workerAtomicRC(threadId: int) {.thread.} =
  var ops = 0
  let startTime = cpuTime()
  let endTime = startTime + TestDuration

  while cpuTime() < endTime:
    for i in 0..<OperationsPerThread:
      {.cast(gcsafe).}:
        let idx = (ops + threadId) mod gAtomicNodes.len
        let node = gAtomicNodes[idx]
      atomicIncRef(node)
      if atomicDecRef(node):
        discard
      ops += 1

  discard atomicFetchAdd(gOpsAtomic.addr, ops.int64, ATOMIC_RELAXED)
  let elapsed = cpuTime() - startTime
  echo "Thread ", threadId, " (Atomic): ", ops, " ops in ", elapsed.formatFloat(ffDecimal, 3), "s"


proc workerBufferedRC(threadId: int) {.thread.} =
  var ops = 0
  let startTime = cpuTime()
  let endTime = startTime + TestDuration

  while cpuTime() < endTime:
    {.cast(gcsafe).}:
      for i in 0..<OperationsPerThread:
        let idx = (ops + threadId) mod gBufferedNodes.len
        let node = gBufferedNodes[idx]
        bufferedIncRef(node)
        bufferedDecRef(node)
        ops += 1

  # Final merge (simulating collection at end)
  {.cast(gcsafe).}:
    mergePendingOps()
  discard atomicFetchAdd(gOpsBuffered.addr, ops.int64, ATOMIC_RELAXED)
  let elapsed = cpuTime() - startTime
  echo "Thread ", threadId, " (Buffered): ", ops, " ops in ", elapsed.formatFloat(ffDecimal, 3), "s"

proc main() =
  echo "Initializing benchmark..."

  # Initialize global lock (still needed for overflow handling)
  initLock(gGlobalLock)
  # Stripe arrays are already zero-initialized

  # Create test nodes
  const NumNodes = 1000
  gNonAtomicNodes = newSeq[ptr Node](NumNodes)
  gAtomicNodes = newSeq[ptr Node](NumNodes)
  gBufferedNodes = newSeq[ptr Node](NumNodes)

  var one = 1 # stupid hack

  for i in 0..<NumNodes:
    var n0 = cast[ptr Node](alloc0(sizeof(Node)))
    n0.rc = 1  # Non-atomic initialization
    n0.data = i
    gNonAtomicNodes[i] = n0

    var n1 = cast[ptr Node](alloc0(sizeof(Node)))
    atomicStore(addr n1.rc, addr one, ATOMIC_RELAXED)
    n1.data = i
    gAtomicNodes[i] = n1

    var n2 = cast[ptr Node](alloc0(sizeof(Node)))
    atomicStore(addr n2.rc, addr one, ATOMIC_RELAXED)
    n2.data = i
    gBufferedNodes[i] = n2

  echo "\n=== Single-threaded benchmark ==="
  benchmarkNonAtomicRC()
  benchmarkAtomicRC()
  benchmarkBufferedRC()

  echo "\n=== Multi-threaded benchmark (", NumThreads, " threads) ==="

  # Atomic RC multi-threaded
  var zero = 0'i64
  atomicStore(addr gOpsAtomic, addr zero, ATOMIC_RELAXED)
  var threadsAtomic: array[NumThreads, Thread[int]]
  let startAtomic = cpuTime()
  for i in 0..<NumThreads:
    createThread(threadsAtomic[i], workerAtomicRC, i)
  for i in 0..<NumThreads:
    joinThread(threadsAtomic[i])
  let elapsedAtomic = cpuTime() - startAtomic
  let totalOpsAtomic = atomicLoadN(addr gOpsAtomic, ATOMIC_RELAXED)
  if elapsedAtomic > 0.0:
    echo "Total Atomic RC: ", totalOpsAtomic, " ops in ", elapsedAtomic.formatFloat(ffDecimal, 3), "s = ",
         (totalOpsAtomic.int64.float / elapsedAtomic).formatFloat(ffDecimal, 0), " ops/s"
  else:
    echo "Total Atomic RC: ", totalOpsAtomic, " ops (timing issue)"

  # Buffered RC multi-threaded
  atomicStore(addr gOpsBuffered, addr zero, ATOMIC_RELAXED)
  var threadsBuffered: array[NumThreads, Thread[int]]
  let startBuffered = cpuTime()
  for i in 0..<NumThreads:
    createThread(threadsBuffered[i], workerBufferedRC, i)
  for i in 0..<NumThreads:
    joinThread(threadsBuffered[i])
  # Final merge for all threads
  let mergeStart = cpuTime()
  mergePendingOps()
  let mergeTime = cpuTime() - mergeStart
  let elapsedBuffered = cpuTime() - startBuffered
  let totalOpsBuffered = atomicLoadN(addr gOpsBuffered, ATOMIC_RELAXED)
  if elapsedBuffered > 0.0:
    echo "Total Buffered RC: ", totalOpsBuffered, " ops in ", elapsedBuffered.formatFloat(ffDecimal, 3), "s = ",
         (totalOpsBuffered.int64.float / elapsedBuffered).formatFloat(ffDecimal, 0), " ops/s"
    echo "  (merge overhead: ", mergeTime.formatFloat(ffDecimal, 3), "s)"
  else:
    echo "Total Buffered RC: ", totalOpsBuffered, " ops (timing issue)"

  if elapsedAtomic > 0.0 and elapsedBuffered > 0.0:
    let atomicRate = totalOpsAtomic.int64.float / elapsedAtomic
    let bufferedRate = totalOpsBuffered.int64.float / elapsedBuffered
    echo "\n=== Summary ==="
    echo "Multi-threaded: Atomic vs Buffered = ", (atomicRate / bufferedRate).formatFloat(ffDecimal, 2), "x faster"
    echo "Multi-threaded: Buffered vs Atomic = ", (bufferedRate / atomicRate).formatFloat(ffDecimal, 2), "x slower"
    echo "\nOverhead analysis:"
    echo "  Atomic overhead (single-threaded): Check Non-Atomic vs Atomic from first run"
    echo "  Multi-threaded overhead: ", (atomicRate / bufferedRate).formatFloat(ffDecimal, 2), "x"
    echo "  Contention helps buffering by: ", ((238142454.0 / 50083545.0) / (atomicRate / bufferedRate)).formatFloat(ffDecimal, 2), "x"

  # Cleanup
  for i in 0..<NumNodes:
    dealloc(gNonAtomicNodes[i])
    dealloc(gAtomicNodes[i])
    dealloc(gBufferedNodes[i])

when isMainModule:
  main()
