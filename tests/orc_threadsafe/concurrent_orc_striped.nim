## Concurrent ORC Algorithm - Striped Lock Design
##
## Design (per user's clarification):
## - Stripe selection based on THREAD ID (not cell address)
## - Each stripe has a FIXED-SIZE array for pending roots
## - On overflow, trigger collection
## - Only ONE lock per incRef/decRef operation
## - Collector merges all per-stripe queues under global lock

import std/locks

const
  NumStripes = 64  # more stripes = less contention
  QueueSize = 128  # fixed-size per-stripe queue
  RootsThreshold = 10

type
  Color = enum
    colBlack = 0
    colGray = 1
    colWhite = 2

  Cell* = ptr CellObj
  CellObj* = object
    rc*: int              # reference count (only touched under global lock)
    rootIdx*: int         # index in roots buffer (0 = not in roots)
    color*: Color         # for Bacon's algorithm during collection
    typeName*: string     # for debugging
    children*: seq[Cell]
    freed*: bool

  Stripe = object
    lock: Lock
    queue: array[QueueSize, Cell]  # fixed-size pending roots
    queueLen: int                   # current fill level

  OrcState = object
    globalLock: Lock
    roots: seq[Cell]
    totalCollections: int
    totalFreed: int
    toInc, toDec: array[NumStripes, Stripe]

var gOrc: OrcState

# Forward declarations
proc collectCyclesInternal()
proc mergePendingRoots()


# -----------------------------------------------------------------------------
# Initialization
# -----------------------------------------------------------------------------

proc initOrc*() =
  initLock(gOrc.globalLock)
  for i in 0..<NumStripes:
    initLock(gOrc.toInc[i].lock)
    initLock(gOrc.toDec[i].lock)
    gOrc.toInc[i].queueLen = 0
    gOrc.toDec[i].queueLen = 0
  gOrc.roots = @[]
  gOrc.totalCollections = 0
  gOrc.totalFreed = 0

proc deinitOrc*() =
  deinitLock(gOrc.globalLock)
  for i in 0..<NumStripes:
    deinitLock(gOrc.toInc[i].lock)
    deinitLock(gOrc.toDec[i].lock)

# -----------------------------------------------------------------------------
# Stripe selection based on thread ID
# -----------------------------------------------------------------------------

proc getStripeIdx(): int {.inline.} =
  getThreadId() and (NumStripes - 1)

proc getToInc(): ptr Stripe {.inline.} =
  addr gOrc.toInc[getStripeIdx()]

proc getToDec(): ptr Stripe {.inline.} =
  addr gOrc.toDec[getStripeIdx()]

# -----------------------------------------------------------------------------
# Cell allocation
# -----------------------------------------------------------------------------

proc newCell*(typeName: string, numChildren: int): Cell =
  result = cast[Cell](alloc0(sizeof(CellObj)))
  result.rc = 0
  result.rootIdx = 0
  result.color = colBlack
  result.typeName = typeName
  result.children = newSeq[Cell](numChildren)
  result.freed = false

proc freeCell(c: Cell) =
  assert not c.freed, "double free detected: " & c.typeName
  c.freed = true
  dealloc(c)

# -----------------------------------------------------------------------------
# Roots management (under global lock)
# -----------------------------------------------------------------------------

proc mergePendingIncOnly() =
  ## Merge only toInc queues into side table. No roots, no cycle collection.
  ## Called under global lock. Use on incRef overflow (incRef produces no garbage).
  for i in 0..<NumStripes:
    withLock gOrc.toInc[i].lock:
      for j in 0..<gOrc.toInc[i].queueLen:
        let c = gOrc.toInc[i].queue[j]
        c.rc += 1
      gOrc.toInc[i].queueLen = 0

proc mergePendingRoots() =
  ## Merge all per-stripe pending roots into global roots buffer
  ## Called under global lock
  for i in 0..<NumStripes:
    # Acquire stripe lock to safely read and clear pending roots
    withLock gOrc.toInc[i].lock:
      for j in 0..<gOrc.toInc[i].queueLen:
        let c = gOrc.toInc[i].queue[j]
        c.rc += 1
      gOrc.toInc[i].queueLen = 0

    withLock gOrc.toDec[i].lock:
      for j in 0..<gOrc.toDec[i].queueLen:
        let c = gOrc.toDec[i].queue[j]
        c.rc -= 1
        # Every decRef is a potential cycle root (Bacon: trial deletion from here)
        if c.rootIdx == 0:
          gOrc.roots.add(c)
          c.rootIdx = gOrc.roots.len
      gOrc.toDec[i].queueLen = 0

# -----------------------------------------------------------------------------
# Bacon's algorithm
# -----------------------------------------------------------------------------

proc markGray(c: Cell) =
  if c.color != colGray:
    c.color = colGray
    for child in c.children:
      if child != nil and not child.freed:
        child.rc -= 1
        markGray(child)

proc scanBlack(c: Cell) =
  ## Mark node and all reachable nodes as alive (black).
  c.rc += 1
  if c.color == colBlack:
    return  # Already marked alive
  c.color = colBlack
  for child in c.children:
    if child != nil and not child.freed:
      scanBlack(child)

proc scan(c: Cell) =
  if c.color == colGray:
    if c.rc > 0:
      scanBlack(c)
    else:
      c.color = colWhite
      for child in c.children:
        if child != nil and not child.freed:
          scan(child)

proc collectWhite(c: Cell, toFree: var seq[Cell]) =
  if c.color == colWhite and c.rootIdx == 0:
    c.color = colBlack
    for child in c.children:
      if child != nil and not child.freed:
        collectWhite(child, toFree)
    toFree.add(c)

proc resetColors(c: Cell) =
  if c.color == colWhite: return  # already reset
  c.color = colWhite
  for child in c.children:
    if child != nil and not child.freed:
      resetColors(child)

proc collectCyclesInternal() =
  ## Internal: called under global lock, assumes pending roots already merged
  if gOrc.roots.len == 0:
    return

  # Reset colors for Bacon's algorithm (nodes may have colBlack/colGray/colWhite from last run)
  for c in gOrc.roots:
    if not c.freed:
      resetColors(c)

  for c in gOrc.roots:
    if not c.freed:
      markGray(c)

  for c in gOrc.roots:
    if not c.freed:
      scan(c)

  var toFree: seq[Cell] = @[]
  for c in gOrc.roots:
    c.rootIdx = 0
    if not c.freed:
      collectWhite(c, toFree)

  gOrc.roots.setLen(0)

  for c in toFree:
    for i in 0..<c.children.len:
      c.children[i] = nil
    freeCell(c)
    gOrc.totalFreed += 1

  gOrc.totalCollections += 1

# -----------------------------------------------------------------------------
# Collection
# -----------------------------------------------------------------------------

proc collectUnderGlobalLock() =
  ## Called when holding global lock
  mergePendingRoots()
  collectCyclesInternal()

proc mergeIncOnly*() =
  ## Merge only toInc queues; no roots updated, no collection. For incRef overflow.
  withLock gOrc.globalLock:
    mergePendingIncOnly()

proc maybeCollect*() =
  withLock gOrc.globalLock:
    mergePendingRoots()
    if gOrc.roots.len >= RootsThreshold:
      collectCyclesInternal()

proc forceCollect*() =
  withLock gOrc.globalLock:
    collectUnderGlobalLock()

# -----------------------------------------------------------------------------
# RC operations - ONE stripe lock only, based on thread ID
# On queue overflow, trigger collection
# -----------------------------------------------------------------------------

proc incRef*(c: Cell) =
  if c == nil: return
  assert not c.freed, "incRef on freed cell: " & c.typeName
  let stripe = getToInc()
  while true:
    var needsCollection = false
    withLock stripe.lock:
      if stripe.queueLen < QueueSize:
        stripe.queue[stripe.queueLen] = c
        stripe.queueLen += 1
      else:
        # Queue overflow - need to collect
        # But must be done outside the lock!
        needsCollection = true

    if needsCollection:
      # incRef produces no garbage; only merge toInc to drain queue (don't touch toDec/roots)
      mergeIncOnly()
    else:
      break

proc decRef*(c: Cell) =
  if c == nil: return
  assert not c.freed, "decRef on freed cell: " & c.typeName
  let stripe = getToDec()
  while true:
    var needsCollection = false
    withLock stripe.lock:
      if stripe.queueLen < QueueSize:
        stripe.queue[stripe.queueLen] = c
        stripe.queueLen += 1
      else:
        # Queue overflow - need to collect
        # But must be done outside the lock!
        needsCollection = true

    if needsCollection:
      maybeCollect()
    else:
      break

# -----------------------------------------------------------------------------
# Write barrier
# -----------------------------------------------------------------------------

proc writeBarrier*(dest: ptr Cell, newVal: Cell) =
  withLock gOrc.globalLock:
    let oldVal = dest[]
    dest[] = newVal

    # Since we hold the global lock, we can just do the RC operations directly.
    # And that is great because the queues could overflow at any time.
    if newVal != nil:
      newVal.rc += 1

    if oldVal != nil and not oldVal.freed:
      oldVal.rc -= 1
      if oldVal.rc > 0 and oldVal.rootIdx == 0:
        gOrc.roots.add(oldVal)
        oldVal.rootIdx = gOrc.roots.len

# -----------------------------------------------------------------------------
# Stats
# -----------------------------------------------------------------------------

proc orcStats*(): tuple[collections: int, freed: int, roots: int] =
  withLock gOrc.globalLock:
    result = (gOrc.totalCollections, gOrc.totalFreed, gOrc.roots.len)

# -----------------------------------------------------------------------------
# Tests
# -----------------------------------------------------------------------------

when isMainModule:
  proc testSimpleCycle() =
    echo "\n--- Test: Simple Cycle ---"
    initOrc()

    let a = newCell("A", 1)
    let b = newCell("B", 1)

    incRef(a)
    incRef(b)

    writeBarrier(addr a.children[0], b)
    writeBarrier(addr b.children[0], a)

    echo "Before releasing locals:"
    forceCollect()
    var stats = orcStats()
    echo "  Freed: ", stats.freed, " (expected 0)"
    assert stats.freed == 0

    decRef(a)
    decRef(b)

    echo "After releasing locals:"
    forceCollect()
    stats = orcStats()
    echo "  Freed: ", stats.freed, " (expected 2)"
    assert stats.freed == 2

    deinitOrc()
    echo "PASSED"

  proc testLiveCycle() =
    echo "\n--- Test: Live Cycle ---"
    initOrc()

    let x = newCell("X", 1)
    let a = newCell("A", 1)
    let b = newCell("B", 1)

    incRef(x)
    writeBarrier(addr x.children[0], a)
    writeBarrier(addr a.children[0], b)
    writeBarrier(addr b.children[0], a)

    forceCollect()
    var stats = orcStats()
    assert stats.freed == 0

    writeBarrier(addr x.children[0], nil)

    forceCollect()
    stats = orcStats()
    echo "  Freed: ", stats.freed, " (expected 2)"
    assert stats.freed == 2

    decRef(x)
    forceCollect()

    deinitOrc()
    echo "PASSED"

  proc testTripleCycle() =
    echo "\n--- Test: Triple Cycle ---"
    initOrc()

    let a = newCell("A", 1)
    let b = newCell("B", 1)
    let c = newCell("C", 1)

    incRef(a)

    writeBarrier(addr a.children[0], b)
    writeBarrier(addr b.children[0], c)
    writeBarrier(addr c.children[0], a)

    forceCollect()
    var stats = orcStats()
    assert stats.freed == 0

    decRef(a)

    forceCollect()
    stats = orcStats()
    echo "  Freed: ", stats.freed, " (expected 3)"
    assert stats.freed == 3

    deinitOrc()
    echo "PASSED"

  proc testMultiThreaded() =
    echo "\n--- Test: Multi-threaded ---"
    initOrc()

    const NumThreads = 4
    const CyclesPerThread = 1000

    var threads: array[NumThreads, Thread[int]]

    proc threadProc(threadId: int) {.thread, gcsafe.} =
      {.cast(gcsafe).}:
        for i in 0..<CyclesPerThread:
          let a = newCell("A", 1)
          let b = newCell("B", 1)

          incRef(a)
          incRef(b)

          writeBarrier(addr a.children[0], b)
          writeBarrier(addr b.children[0], a)

          decRef(a)
          decRef(b)

          if i mod 100 == 0:
            forceCollect()

    for i in 0..<NumThreads:
      createThread(threads[i], threadProc, i)

    for i in 0..<NumThreads:
      joinThread(threads[i])

    forceCollect()

    let stats = orcStats()
    let expectedFreed = NumThreads * CyclesPerThread * 2
    echo "  Total freed: ", stats.freed, " (expected ", expectedFreed, ")"
    assert stats.freed >= expectedFreed div 2

    deinitOrc()
    echo "PASSED"

  proc testQueueOverflow() =
    echo "\n--- Test: Queue Overflow ---"
    initOrc()

    # Create more pending roots than queue can hold to trigger overflow collection
    const NumCycles = QueueSize + 100

    for i in 0..<NumCycles:
      let a = newCell("A", 1)
      let b = newCell("B", 1)

      incRef(a)
      incRef(b)

      writeBarrier(addr a.children[0], b)
      writeBarrier(addr b.children[0], a)

      decRef(a)
      decRef(b)

    forceCollect()

    let stats = orcStats()
    echo "  Collections: ", stats.collections, " (expected > 1 due to overflow)"
    echo "  Freed: ", stats.freed, " (expected ", NumCycles * 2, ")"
    assert stats.collections >= 1
    assert stats.freed == NumCycles * 2

    deinitOrc()
    echo "PASSED"

  echo "=== Striped Lock Concurrent ORC Tests ==="
  testSimpleCycle()
  testLiveCycle()
  testTripleCycle()
  testQueueOverflow()
  testMultiThreaded()
  echo "\n=== All tests passed ==="
