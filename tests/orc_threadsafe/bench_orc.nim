## Benchmark: Concurrent ORC vs Native ORC
##
## Compares performance of our concurrent ORC implementations
## against Nim's native single-threaded ORC using ref types.

import std/[times, strformat]

const
  NumCycles = 100_000
  WarmupCycles = 1000

# =============================================================================
# Native ORC benchmark using Nim's ref types
# =============================================================================

type
  NativeNode = ref object
    child: NativeNode
    data: int

proc benchNativeOrc(): float =
  ## Benchmark native ORC with ref types
  # Warmup
  for i in 0..<WarmupCycles:
    let a = NativeNode(data: i)
    let b = NativeNode(data: i + 1)
    a.child = b
    b.child = a

  GC_fullCollect()

  let start = cpuTime()

  for i in 0..<NumCycles:
    let a = NativeNode(data: i)
    let b = NativeNode(data: i + 1)
    a.child = b
    b.child = a

  GC_fullCollect()

  result = cpuTime() - start

# =============================================================================
# Original Concurrent ORC (striped locks)
# =============================================================================

import ./concurrent_orc as corc

proc benchConcurrentOrc(): float =
  corc.initOrc()

  for i in 0..<WarmupCycles:
    let a = corc.newCell("A", 1)
    let b = corc.newCell("B", 1)
    corc.incRef(a)
    corc.incRef(b)
    corc.writeBarrier(addr a.children[0], b)
    corc.writeBarrier(addr b.children[0], a)
    corc.decRef(a)
    corc.decRef(b)

  corc.forceCollect()

  let start = cpuTime()

  for i in 0..<NumCycles:
    let a = corc.newCell("A", 1)
    let b = corc.newCell("B", 1)
    corc.incRef(a)
    corc.incRef(b)
    corc.writeBarrier(addr a.children[0], b)
    corc.writeBarrier(addr b.children[0], a)
    corc.decRef(a)
    corc.decRef(b)

  corc.forceCollect()

  result = cpuTime() - start
  corc.deinitOrc()

# =============================================================================
# Hybrid Concurrent ORC (atomic RC + lock-free pending log)
# =============================================================================

import ./concurrent_orc_hybrid as horc

proc benchHybridOrc(): float =
  horc.initOrc()

  for i in 0..<WarmupCycles:
    let a = horc.newCell("A", 1)
    let b = horc.newCell("B", 1)
    horc.incRef(a)
    horc.incRef(b)
    horc.writeBarrier(addr a.children[0], b)
    horc.writeBarrier(addr b.children[0], a)
    horc.decRef(a)
    horc.decRef(b)

  horc.forceCollect()

  let start = cpuTime()

  for i in 0..<NumCycles:
    let a = horc.newCell("A", 1)
    let b = horc.newCell("B", 1)
    horc.incRef(a)
    horc.incRef(b)
    horc.writeBarrier(addr a.children[0], b)
    horc.writeBarrier(addr b.children[0], a)
    horc.decRef(a)
    horc.decRef(b)

  horc.forceCollect()

  result = cpuTime() - start
  horc.deinitOrc()

# =============================================================================
# Striped Lock Direct RC
# =============================================================================

import ./concurrent_orc_striped as sorc

proc benchStripedOrc(): float =
  sorc.initOrc()

  for i in 0..<WarmupCycles:
    let a = sorc.newCell("A", 1)
    let b = sorc.newCell("B", 1)
    sorc.incRef(a)
    sorc.incRef(b)
    sorc.writeBarrier(addr a.children[0], b)
    sorc.writeBarrier(addr b.children[0], a)
    sorc.decRef(a)
    sorc.decRef(b)

  sorc.forceCollect()

  let start = cpuTime()

  for i in 0..<NumCycles:
    let a = sorc.newCell("A", 1)
    let b = sorc.newCell("B", 1)
    sorc.incRef(a)
    sorc.incRef(b)
    sorc.writeBarrier(addr a.children[0], b)
    sorc.writeBarrier(addr b.children[0], a)
    sorc.decRef(a)
    sorc.decRef(b)

  sorc.forceCollect()

  result = cpuTime() - start
  sorc.deinitOrc()

# =============================================================================
# Main
# =============================================================================

when isMainModule:
  echo "=== ORC Performance Benchmark ==="
  echo fmt"Creating and destroying {NumCycles} cycles (2 nodes each)"
  echo ""

  echo "Running Native ORC benchmark..."
  let nativeTime = benchNativeOrc()
  echo fmt"  Native ORC:       {nativeTime:.4f}s ({NumCycles.float / nativeTime:.0f} cycles/sec)"

  echo "Running Original Concurrent ORC benchmark..."
  let concurrentTime = benchConcurrentOrc()
  echo fmt"  Concurrent ORC:   {concurrentTime:.4f}s ({NumCycles.float / concurrentTime:.0f} cycles/sec)"

  echo "Running Hybrid ORC benchmark..."
  let hybridTime = benchHybridOrc()
  echo fmt"  Hybrid ORC:       {hybridTime:.4f}s ({NumCycles.float / hybridTime:.0f} cycles/sec)"

  echo "Running Striped Lock ORC benchmark..."
  let stripedTime = benchStripedOrc()
  echo fmt"  Striped ORC:      {stripedTime:.4f}s ({NumCycles.float / stripedTime:.0f} cycles/sec)"

  echo ""
  echo "=== Summary (vs Native) ==="
  echo fmt"  Original Concurrent: {concurrentTime / nativeTime:.2f}x slower"
  echo fmt"  Hybrid (atomic RC):  {hybridTime / nativeTime:.2f}x slower"
  echo fmt"  Striped (direct RC): {stripedTime / nativeTime:.2f}x slower"
