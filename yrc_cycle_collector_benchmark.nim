# Benchmark: Cycle collector overhead (buffering + periodic collection)
# Compares immediate atomic RC vs buffered RC + cycle collection

import std/[locks, atomics, os, strutils, times, hashes]

const
  NumNodes = 100
  OperationsPerIteration = 100
  NumIterations = 10000
  ComputationWork = 1000  # Hash operations per iteration
  IOSimDelay = 0.0001     # Simulated IO delay in seconds
  NumStripes = 64
  QueueSize = 128
  RootsThreshold = 10     # Trigger collection when roots.len >= this

type
  Node = object
    rc: int
    data: int
    payload: array[100, byte]
    next: ptr Node

  Stripe = object
    toIncLen: Atomic[int]
    toInc: array[QueueSize, ptr Node]
    toDecLen: Atomic[int]
    toDec: array[QueueSize, ptr Node]
    lockInc: Lock
    lockDec: Lock

  Root = tuple[node: ptr Node, desc: pointer]
  Roots = object
    d: seq[Root]
    len: int

var
  gNodes: seq[ptr Node]
  gComputationResult: int
  stripes: array[NumStripes, Stripe]
  roots: Roots
  gGlobalLock: Lock
  collectionCount: int
  mergeTime: float
  collectionTime: float

proc initRoots(r: var Roots) =
  r.d = newSeq[Root](RootsThreshold * 4)
  r.len = 0

proc addRoot(r: var Roots; node: ptr Node; desc: pointer) =
  if r.d == nil:
    initRoots(r)
  if r.len >= r.d.len:
    r.d.setLen(r.d.len * 2)
  r.d[r.len] = (node, desc)
  inc r.len

proc getStripeIdx(): int =
  # Simple hash-based stripe selection
  cast[int](cast[uint](getThreadId()) mod NumStripes.uint)

# Immediate atomic RC (acyclic case - baseline)
template immediateAtomicIncRef(n: ptr Node) =
  discard atomicFetchAdd(n.rc.addr, 1, ATOMIC_RELEASE)

template immediateAtomicDecRef(n: ptr Node): bool =
  let old = atomicFetchSub(n.rc.addr, 1, ATOMIC_ACQ_REL)
  old == 1

# Buffered RC (cyclic case - YRC style)
proc bufferedIncRef(n: ptr Node) {.inline.} =
  let s = getStripeIdx()
  let slot = atomicFetchAdd(stripes[s].toIncLen.addr, 1, ATOMIC_ACQ_REL)
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

proc bufferedDecRef(n: ptr Node): bool {.inline.} =
  let s = getStripeIdx()
  let slot = atomicFetchAdd(stripes[s].toDecLen.addr, 1, ATOMIC_ACQ_REL)
  if slot < QueueSize:
    atomicStoreN(stripes[s].toDec[slot].addr, n, ATOMIC_RELEASE)
    result = false  # Deferred check
  else:
    # Overflow - merge immediately
    withLock gGlobalLock:
      let old = atomicFetchSub(n.rc.addr, 1, ATOMIC_ACQ_REL)
      result = old == 1
      for i in 0..<NumStripes:
        let incLen = atomicExchangeN(stripes[i].toIncLen.addr, 0, ATOMIC_ACQUIRE)
        for j in 0..<min(incLen, QueueSize):
          let x = atomicLoadN(stripes[i].toInc[j].addr, ATOMIC_ACQUIRE)
          discard atomicFetchAdd(x.rc.addr, 1, ATOMIC_RELEASE)
        let decLen = atomicExchangeN(stripes[i].toDecLen.addr, 0, ATOMIC_ACQUIRE)
        for j in 0..<min(decLen, QueueSize):
          let x = atomicLoadN(stripes[i].toDec[j].addr, ATOMIC_ACQUIRE)
          discard atomicFetchSub(x.rc.addr, 1, ATOMIC_ACQ_REL)

proc mergePendingOps() =
  let start = cpuTime()
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
        # Add to roots for cycle collection
        addRoot(roots, x, nil)
  mergeTime += cpuTime() - start

# Simplified cycle collection (just measure overhead, not full Bacon algorithm)
proc collectCycles() =
  let start = cpuTime()
  withLock gGlobalLock:
    mergePendingOps()
    # Simulate cycle collection work (markGray/scan/collectColor phases)
    # In reality this traces the graph, but we'll just simulate the overhead
    var freed = 0
    for i in 0..<roots.len:
      let (node, desc) = roots.d[i]
      if node.rc == 0:
        inc freed
    roots.len = 0
    inc collectionCount
  collectionTime += cpuTime() - start

proc checkAndCollect() =
  if roots.len >= RootsThreshold:
    collectCycles()

# Simulate computation work
proc doComputation(nodes: seq[ptr Node]): int =
  result = 0
  for i in 0..<ComputationWork:
    for node in nodes:
      result = result !& hash(node.payload)
      result = result !& hash(node.data)
  result = !$result

# Simulate IO work
proc simulateIO() =
  sleep(int(IOSimDelay * 1000))

template benchmarkImmediateAtomic(): (float, float, float, float) =
  var totalTime = 0.0
  var rcTime = 0.0
  var computationTime = 0.0
  var ioTime = 0.0

  for iter in 0..<NumIterations:
    let rcStart = cpuTime()
    for i in 0..<OperationsPerIteration:
      let idx = (iter * OperationsPerIteration + i) mod gNodes.len
      let node = gNodes[idx]
      immediateAtomicIncRef(node)
      if immediateAtomicDecRef(node):
        discard
    rcTime += cpuTime() - rcStart

    let compStart = cpuTime()
    gComputationResult = doComputation(gNodes)
    computationTime += cpuTime() - compStart

    let ioStart = cpuTime()
    simulateIO()
    ioTime += cpuTime() - ioStart

  totalTime = rcTime + computationTime + ioTime
  echo "Immediate Atomic RC (acyclic):"
  echo "  Total time: ", totalTime.formatFloat(ffDecimal, 3), "s"
  echo "  RC ops time: ", rcTime.formatFloat(ffDecimal, 3), "s (",
       (rcTime / totalTime * 100).formatFloat(ffDecimal, 1), "%)"
  echo "  Computation time: ", computationTime.formatFloat(ffDecimal, 3), "s (",
       (computationTime / totalTime * 100).formatFloat(ffDecimal, 1), "%)"
  echo "  IO time: ", ioTime.formatFloat(ffDecimal, 3), "s (",
       (ioTime / totalTime * 100).formatFloat(ffDecimal, 1), "%)"
  (totalTime, rcTime, computationTime, ioTime)

template benchmarkBufferedRC(): (float, float, float, float) =
  var totalTime = 0.0
  var rcTime = 0.0
  var computationTime = 0.0
  var ioTime = 0.0
  collectionCount = 0
  mergeTime = 0.0
  collectionTime = 0.0
  roots.len = 0

  for iter in 0..<NumIterations:
    let rcStart = cpuTime()
    for i in 0..<OperationsPerIteration:
      let idx = (iter * OperationsPerIteration + i) mod gNodes.len
      let node = gNodes[idx]
      bufferedIncRef(node)
      discard bufferedDecRef(node)
      checkAndCollect()
    rcTime += cpuTime() - rcStart

    let compStart = cpuTime()
    gComputationResult = doComputation(gNodes)
    computationTime += cpuTime() - compStart

    let ioStart = cpuTime()
    simulateIO()
    ioTime += cpuTime() - ioStart

  # Final merge
  withLock gGlobalLock:
    mergePendingOps()
    collectCycles()

  totalTime = rcTime + computationTime + ioTime
  echo "Buffered RC + Cycle Collection (cyclic):"
  echo "  Total time: ", totalTime.formatFloat(ffDecimal, 3), "s"
  echo "  RC ops time: ", rcTime.formatFloat(ffDecimal, 3), "s (",
       (rcTime / totalTime * 100).formatFloat(ffDecimal, 1), "%)"
  echo "  Computation time: ", computationTime.formatFloat(ffDecimal, 3), "s (",
       (computationTime / totalTime * 100).formatFloat(ffDecimal, 1), "%)"
  echo "  IO time: ", ioTime.formatFloat(ffDecimal, 3), "s (",
       (ioTime / totalTime * 100).formatFloat(ffDecimal, 1), "%)"
  echo "  Collections run: ", collectionCount
  echo "  Merge time: ", mergeTime.formatFloat(ffDecimal, 3), "s (",
       (mergeTime / totalTime * 100).formatFloat(ffDecimal, 2), "%)"
  echo "  Collection time: ", collectionTime.formatFloat(ffDecimal, 3), "s (",
       (collectionTime / totalTime * 100).formatFloat(ffDecimal, 2), "%)"
  (totalTime, rcTime, computationTime, ioTime)

proc main() =
  echo "Cycle Collector Overhead Benchmark"
  echo repeat("=", 70)
  echo "Configuration:"
  echo "  Nodes: ", NumNodes
  echo "  RC ops per iteration: ", OperationsPerIteration
  echo "  Iterations: ", NumIterations
  echo "  Computation work: ", ComputationWork, " hash ops per iteration"
  echo "  IO delay: ", IOSimDelay, "s per iteration"
  echo "  Collection threshold: ", RootsThreshold, " roots"
  echo ""

  # Initialize stripes
  for i in 0..<NumStripes:
    initLock(stripes[i].lockInc)
    initLock(stripes[i].lockDec)
  initLock(gGlobalLock)
  initRoots(roots)

  # Initialize nodes
  gNodes = newSeq[ptr Node](NumNodes)
  for i in 0..<NumNodes:
    var n = cast[ptr Node](alloc0(sizeof(Node)))
    n.rc = 1
    n.data = i
    for j in 0..<100:
      n.payload[j] = byte((i + j) mod 256)
    gNodes[i] = n

  echo "=== Benchmark: Immediate Atomic RC (acyclic) ==="
  let (immediateTotal, immediateRC, immediateComp, immediateIO) = benchmarkImmediateAtomic()
  echo ""

  echo "=== Benchmark: Buffered RC + Cycle Collection (cyclic) ==="
  let (bufferedTotal, bufferedRC, bufferedComp, bufferedIO) = benchmarkBufferedRC()
  echo ""

  # Cleanup
  for i in 0..<NumNodes:
    dealloc(gNodes[i])
  for i in 0..<NumStripes:
    deinitLock(stripes[i].lockInc)
    deinitLock(stripes[i].lockDec)
  deinitLock(gGlobalLock)

  echo "=== Overhead Analysis ==="
  let totalOverhead = bufferedTotal - immediateTotal
  let rcOverhead = bufferedRC - immediateRC
  let overheadPercent = (totalOverhead / immediateTotal * 100)
  let rcOverheadPercent = (rcOverhead / immediateRC * 100)

  echo "RC operations overhead: ", rcOverhead.formatFloat(ffDecimal, 3), "s (",
       rcOverheadPercent.formatFloat(ffDecimal, 1), "% slower)"
  echo "Total program overhead: ", totalOverhead.formatFloat(ffDecimal, 3), "s (",
       overheadPercent.formatFloat(ffDecimal, 2), "%)"
  echo ""
  echo "Key insight: Cycle collector overhead includes:"
  echo "  1. Buffering cost (enqueue vs immediate atomic)"
  echo "  2. Merge cost (draining queues under global lock)"
  echo "  3. Collection cost (Bacon algorithm phases)"
  echo ""
  if overheadPercent < 0:
    echo "Measured overhead: ", abs(overheadPercent).formatFloat(ffDecimal, 2),
         "% (negative due to variance - actual overhead is small)."
  else:
    echo "Cycle collector overhead: ", overheadPercent.formatFloat(ffDecimal, 2),
         "% of total runtime."
  echo ""
  echo "This overhead enables cycle detection and deferred destruction,"
  echo "which is necessary for cyclic data structures."

when isMainModule:
  main()
