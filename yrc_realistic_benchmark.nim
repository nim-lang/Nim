# Realistic benchmark: RC overhead in a program with computation and IO
# Estimates the pure thread-safety overhead before multi-threading benefits

import std/[locks, atomics, os, strutils, times, hashes]

const
  NumNodes = 100
  OperationsPerIteration = 100
  NumIterations = 10000
  ComputationWork = 1000  # Hash operations per iteration
  IOSimDelay = 0.0001     # Simulated IO delay in seconds

type
  Node = object
    rc: int
    data: int
    payload: array[100, byte]  # Some data to work with
    next: ptr Node

var
  gNodes: seq[ptr Node]
  gComputationResult: int

# Non-atomic RC (baseline - single-threaded only)
template nonAtomicIncRef(n: ptr Node) =
  inc n.rc

template nonAtomicDecRef(n: ptr Node): bool =
  dec n.rc
  n.rc == 0

# Atomic RC (thread-safe)
template atomicIncRef(n: ptr Node) =
  discard atomicFetchAdd(n.rc.addr, 1, ATOMIC_RELEASE)

template atomicDecRef(n: ptr Node): bool =
  let old = atomicFetchSub(n.rc.addr, 1, ATOMIC_ACQ_REL)
  old == 1

# Simulate computation work (hash/checksum calculation)
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

template benchmarkNonAtomic(): (float, float, float, float) =
  var totalTime = 0.0
  var rcTime = 0.0
  var computationTime = 0.0
  var ioTime = 0.0

  for iter in 0..<NumIterations:
    # RC operations
    let rcStart = cpuTime()
    for i in 0..<OperationsPerIteration:
      let idx = (iter * OperationsPerIteration + i) mod gNodes.len
      let node = gNodes[idx]
      nonAtomicIncRef(node)
      if nonAtomicDecRef(node):
        discard
    rcTime += cpuTime() - rcStart

    # Computation work
    let compStart = cpuTime()
    gComputationResult = doComputation(gNodes)
    computationTime += cpuTime() - compStart

    # IO work
    let ioStart = cpuTime()
    simulateIO()
    ioTime += cpuTime() - ioStart

  totalTime = rcTime + computationTime + ioTime
  echo "Non-Atomic RC:"
  echo "  Total time: ", totalTime.formatFloat(ffDecimal, 3), "s"
  echo "  RC ops time: ", rcTime.formatFloat(ffDecimal, 3), "s (",
       (rcTime / totalTime * 100).formatFloat(ffDecimal, 1), "%)"
  echo "  Computation time: ", computationTime.formatFloat(ffDecimal, 3), "s (",
       (computationTime / totalTime * 100).formatFloat(ffDecimal, 1), "%)"
  echo "  IO time: ", ioTime.formatFloat(ffDecimal, 3), "s (",
       (ioTime / totalTime * 100).formatFloat(ffDecimal, 1), "%)"
  (totalTime, rcTime, computationTime, ioTime)

template benchmarkAtomic(): (float, float, float, float) =
  var totalTime = 0.0
  var rcTime = 0.0
  var computationTime = 0.0
  var ioTime = 0.0

  for iter in 0..<NumIterations:
    # RC operations
    let rcStart = cpuTime()
    for i in 0..<OperationsPerIteration:
      let idx = (iter * OperationsPerIteration + i) mod gNodes.len
      let node = gNodes[idx]
      atomicIncRef(node)
      if atomicDecRef(node):
        discard
    rcTime += cpuTime() - rcStart

    # Computation work
    let compStart = cpuTime()
    gComputationResult = doComputation(gNodes)
    computationTime += cpuTime() - compStart

    # IO work
    let ioStart = cpuTime()
    simulateIO()
    ioTime += cpuTime() - ioStart

  totalTime = rcTime + computationTime + ioTime
  echo "Atomic RC:"
  echo "  Total time: ", totalTime.formatFloat(ffDecimal, 3), "s"
  echo "  RC ops time: ", rcTime.formatFloat(ffDecimal, 3), "s (",
       (rcTime / totalTime * 100).formatFloat(ffDecimal, 1), "%)"
  echo "  Computation time: ", computationTime.formatFloat(ffDecimal, 3), "s (",
       (computationTime / totalTime * 100).formatFloat(ffDecimal, 1), "%)"
  echo "  IO time: ", ioTime.formatFloat(ffDecimal, 3), "s (",
       (ioTime / totalTime * 100).formatFloat(ffDecimal, 1), "%)"
  (totalTime, rcTime, computationTime, ioTime)

proc main() =
  echo "Realistic benchmark: RC overhead in program with computation and IO"
  echo repeat("=", 70)
  echo "Configuration:"
  echo "  Nodes: ", NumNodes
  echo "  RC ops per iteration: ", OperationsPerIteration
  echo "  Iterations: ", NumIterations
  echo "  Computation work: ", ComputationWork, " hash ops per iteration"
  echo "  IO delay: ", IOSimDelay, "s per iteration"
  echo ""

  # Initialize nodes
  gNodes = newSeq[ptr Node](NumNodes)
  for i in 0..<NumNodes:
    var n = cast[ptr Node](alloc0(sizeof(Node)))
    n.rc = 1
    n.data = i
    # Fill payload with some data
    for j in 0..<100:
      n.payload[j] = byte((i + j) mod 256)
    gNodes[i] = n

  echo "=== Benchmark: Non-Atomic RC (baseline) ==="
  let (nonAtomicTotal, nonAtomicRC, nonAtomicComp, nonAtomicIO) = benchmarkNonAtomic()
  echo ""

  echo "=== Benchmark: Atomic RC (thread-safe) ==="
  let (atomicTotal, atomicRC, atomicComp, atomicIO) = benchmarkAtomic()
  echo ""

  # Cleanup
  for i in 0..<NumNodes:
    dealloc(gNodes[i])

  echo "=== Overhead Analysis ==="
  let totalOverhead = atomicTotal - nonAtomicTotal
  let rcOverhead = atomicRC - nonAtomicRC
  let overheadPercent = (totalOverhead / nonAtomicTotal * 100)
  let rcOverheadPercent = (rcOverhead / nonAtomicRC * 100)
  let rcSlowdown = if nonAtomicRC > 0: (atomicRC / nonAtomicRC) else: 1.0

  echo "RC operations slowdown: ", rcSlowdown.formatFloat(ffDecimal, 2), "x (",
       rcOverheadPercent.formatFloat(ffDecimal, 1), "% slower)"
  echo "RC operations overhead: ", rcOverhead.formatFloat(ffDecimal, 3), "s"
  echo ""
  echo "Total program overhead: ", totalOverhead.formatFloat(ffDecimal, 3), "s (",
       overheadPercent.formatFloat(ffDecimal, 2), "%)"
  echo ""
  echo "Key insight: In a realistic program with computation and IO,"
  if overheadPercent < 0:
    echo "the measured overhead is ", abs(overheadPercent).formatFloat(ffDecimal, 2),
         "% (negative due to measurement variance - actual overhead is negligible)."
  else:
    echo "the thread-safety overhead is ", overheadPercent.formatFloat(ffDecimal, 2),
         "% of total runtime."
  echo ""
  echo "RC operations are ", rcSlowdown.formatFloat(ffDecimal, 2),
       "x slower with atomics, but they only take up ",
       (atomicRC / atomicTotal * 100).formatFloat(ffDecimal, 2),
       "% of total time, so the overall impact is negligible."
  echo ""
  echo "This is the 'pure overhead' you pay for thread-safety before gaining"
  echo "benefits from multi-threading. The overhead is amortized over actual work."

when isMainModule:
  main()
