## Concurrent ORC Algorithm - Hybrid Implementation
##
## Design:
## - Atomic RC for fast incRef/decRef (no locks on common path)
## - Lock-free pending roots log with overflow fallback
## - Global lock for write barrier + collection
## - Side table for cycle collection

import std/[locks, tables, hashes, atomics]

const
  PendingLogSize = 1024 * 1024  # 1M entries before overflow
  RootsThreshold = 10

type
  Color = enum
    colBlack = 0
    colGray = 1
    colWhite = 2

  Cell* = ptr CellObj
  CellObj* = object
    rc*: Atomic[int]      # atomic RC - always accurate
    rootIdx*: int         # index in roots buffer (0 = not in roots)
    typeName*: string     # for debugging
    children*: seq[Cell]  # child reference fields
    freed*: bool          # for debugging

  SideEntry = object
    rc: int
    color: Color

  OrcState = object
    globalLock: Lock

    # Lock-free pending roots log
    pendingLog: ptr UncheckedArray[Atomic[Cell]]
    logTail: Atomic[int]

    # Overflow buffer (locked)
    overflowLock: Lock
    overflowRoots: seq[Cell]

    # Global state (accessed under globalLock)
    roots: seq[Cell]
    sideTable: Table[Cell, SideEntry]

    # Stats
    totalCollections: int
    totalFreed: int

var gOrc: OrcState

# -----------------------------------------------------------------------------
# Initialization
# -----------------------------------------------------------------------------

proc initOrc*() =
  initLock(gOrc.globalLock)
  initLock(gOrc.overflowLock)

  # Allocate lock-free pending log
  gOrc.pendingLog = cast[ptr UncheckedArray[Atomic[Cell]]](
    alloc0(PendingLogSize * sizeof(Atomic[Cell]))
  )
  gOrc.logTail.store(0)

  gOrc.overflowRoots = @[]
  gOrc.roots = @[]
  gOrc.sideTable = initTable[Cell, SideEntry]()
  gOrc.totalCollections = 0
  gOrc.totalFreed = 0

proc deinitOrc*() =
  dealloc(gOrc.pendingLog)
  deinitLock(gOrc.globalLock)
  deinitLock(gOrc.overflowLock)

# -----------------------------------------------------------------------------
# Lock-free pending roots
# -----------------------------------------------------------------------------

proc addPendingRoot(c: Cell) {.inline.} =
  ## Add to lock-free log, fallback to overflow buffer if full
  let idx = gOrc.logTail.fetchAdd(1)
  if idx < PendingLogSize:
    gOrc.pendingLog[idx].store(c)
  else:
    # Overflow - use locked buffer
    withLock gOrc.overflowLock:
      gOrc.overflowRoots.add(c)

# -----------------------------------------------------------------------------
# Cell allocation
# -----------------------------------------------------------------------------

proc newCell*(typeName: string, numChildren: int): Cell =
  result = cast[Cell](alloc0(sizeof(CellObj)))
  result.rc.store(0)
  result.rootIdx = 0
  result.typeName = typeName
  result.children = newSeq[Cell](numChildren)
  result.freed = false

proc freeCell(c: Cell) =
  assert not c.freed, "double free detected: " & c.typeName
  c.freed = true
  dealloc(c)

# -----------------------------------------------------------------------------
# RC operations - atomic, no locks
# -----------------------------------------------------------------------------

proc incRef*(c: Cell) {.inline.} =
  if c == nil: return
  assert not c.freed, "incRef on freed cell: " & c.typeName
  discard c.rc.fetchAdd(1)

proc decRef*(c: Cell) {.inline.} =
  ## Atomic decrement. If RC > 0 after, add to pending roots for cycle detection.
  if c == nil: return
  assert not c.freed, "decRef on freed cell: " & c.typeName
  let oldRc = c.rc.fetchSub(1)
  if oldRc > 1:
    # Still has refs, but might be part of garbage cycle
    addPendingRoot(c)
  elif oldRc == 1:
    # RC is now 0 - might be garbage or part of garbage cycle
    addPendingRoot(c)

# -----------------------------------------------------------------------------
# Roots management
# -----------------------------------------------------------------------------

proc registerRoot(c: Cell) =
  if c.rootIdx == 0:
    gOrc.roots.add(c)
    c.rootIdx = gOrc.roots.len

proc unregisterRoot(c: Cell) =
  if c.rootIdx > 0:
    let idx = c.rootIdx - 1
    let last = gOrc.roots.len - 1
    if idx != last:
      gOrc.roots[idx] = gOrc.roots[last]
      gOrc.roots[idx].rootIdx = idx + 1
    gOrc.roots.setLen(last)
    c.rootIdx = 0

# -----------------------------------------------------------------------------
# Merge pending roots (called under global lock)
# -----------------------------------------------------------------------------

proc mergePendingRoots() =
  # Process lock-free log
  let count = min(gOrc.logTail.load(), PendingLogSize)
  for i in 0..<count:
    let c = gOrc.pendingLog[i].load()
    if c != nil and not c.freed:
      let rc = c.rc.load()
      if rc > 0:
        registerRoot(c)
      # If rc == 0, object will be freed when we process cycles

  # Reset log
  gOrc.logTail.store(0)

  # Process overflow buffer
  withLock gOrc.overflowLock:
    for c in gOrc.overflowRoots:
      if not c.freed:
        let rc = c.rc.load()
        if rc > 0:
          registerRoot(c)
    gOrc.overflowRoots.setLen(0)

# -----------------------------------------------------------------------------
# Side table operations
# -----------------------------------------------------------------------------

proc getSideEntry(c: Cell): ptr SideEntry =
  if c notin gOrc.sideTable:
    gOrc.sideTable[c] = SideEntry(rc: c.rc.load(), color: colBlack)
  addr gOrc.sideTable[c]

proc clearSideTable() =
  gOrc.sideTable.clear()

# -----------------------------------------------------------------------------
# Bacon's algorithm (using side table)
# -----------------------------------------------------------------------------

proc markGray(c: Cell) =
  let entry = getSideEntry(c)
  if entry.color != colGray:
    entry.color = colGray
    for child in c.children:
      if child != nil and not child.freed:
        let childEntry = getSideEntry(child)
        childEntry.rc -= 1
        markGray(child)

proc scanBlack(c: Cell) =
  let entry = getSideEntry(c)
  entry.color = colBlack
  for child in c.children:
    if child != nil and not child.freed:
      let childEntry = getSideEntry(child)
      childEntry.rc += 1
      if childEntry.color != colBlack:
        scanBlack(child)

proc scan(c: Cell) =
  let entry = getSideEntry(c)
  if entry.color == colGray:
    if entry.rc > 0:
      scanBlack(c)
    else:
      entry.color = colWhite
      for child in c.children:
        if child != nil and not child.freed:
          scan(child)

proc collectWhite(c: Cell, toFree: var seq[Cell]) =
  let entry = getSideEntry(c)
  if entry.color == colWhite and c.rootIdx == 0:
    entry.color = colBlack
    for child in c.children:
      if child != nil and not child.freed:
        collectWhite(child, toFree)
    toFree.add(c)

proc collectCycles() =
  if gOrc.roots.len == 0:
    return

  clearSideTable()

  # Phase 1: Mark gray (trial deletion)
  for c in gOrc.roots:
    if not c.freed:
      markGray(c)

  # Phase 2: Scan
  for c in gOrc.roots:
    if not c.freed:
      scan(c)

  # Phase 3: Collect white
  var toFree: seq[Cell] = @[]
  for c in gOrc.roots:
    c.rootIdx = 0
    if not c.freed:
      collectWhite(c, toFree)

  gOrc.roots.setLen(0)

  # Phase 4: Free garbage
  for c in toFree:
    for i in 0..<c.children.len:
      c.children[i] = nil
    freeCell(c)
    gOrc.totalFreed += 1

  gOrc.totalCollections += 1
  clearSideTable()

# -----------------------------------------------------------------------------
# Collection trigger
# -----------------------------------------------------------------------------

proc maybeCollect*() =
  withLock gOrc.globalLock:
    mergePendingRoots()
    if gOrc.roots.len >= RootsThreshold:
      collectCycles()

proc forceCollect*() =
  withLock gOrc.globalLock:
    mergePendingRoots()
    collectCycles()

# -----------------------------------------------------------------------------
# Write barrier
# -----------------------------------------------------------------------------

proc writeBarrier*(dest: ptr Cell, newVal: Cell) =
  ## Write barrier for heap field assignments
  withLock gOrc.globalLock:
    let oldVal = dest[]
    dest[] = newVal

    if newVal != nil:
      discard newVal.rc.fetchAdd(1)

    if oldVal != nil and not oldVal.freed:
      let oldRc = oldVal.rc.fetchSub(1)
      if oldRc >= 1:
        # Add to roots directly since we have the lock
        registerRoot(oldVal)

# -----------------------------------------------------------------------------
# Stats
# -----------------------------------------------------------------------------

proc orcStats*(): tuple[collections: int, freed: int, roots: int] =
  withLock gOrc.globalLock:
    result = (gOrc.totalCollections, gOrc.totalFreed, gOrc.roots.len)

proc dumpState*() =
  withLock gOrc.globalLock:
    echo "=== ORC State ==="
    echo "Collections: ", gOrc.totalCollections
    echo "Total freed: ", gOrc.totalFreed
    echo "Current roots: ", gOrc.roots.len
    echo "Pending log tail: ", gOrc.logTail.load()

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

    echo "Cycle with external ref:"
    forceCollect()
    var stats = orcStats()
    echo "  Freed: ", stats.freed, " (expected 0)"
    assert stats.freed == 0

    writeBarrier(addr x.children[0], nil)

    echo "After breaking external ref:"
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
    const CyclesPerThread = 100

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

          if i mod 10 == 0:
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

  echo "=== Hybrid Concurrent ORC Tests ==="
  testSimpleCycle()
  testLiveCycle()
  testTripleCycle()
  testMultiThreaded()
  echo "\n=== All tests passed ==="
