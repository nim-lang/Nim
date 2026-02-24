#
# YRC: Thread-safe ORC (concurrent cycle collector).
# Same API as orc.nim but with the global mutator/collector RWLock for safety.
# Destructors for refs run at collection time, not immediately on last decRef.
# See yrc_proof.lean for a Lean 4 proof of safety and deadlock freedom.
#
# ## Locking Protocol
#
# ALL topology-changing operations — heap-field writes (`nimAsgnYrc`,
# `nimSinkYrc`) and seq mutations that resize internal buffers — hold the
# global mutator read lock (`gYrcGlobalLock` via `acquireMutatorLock`).
# Multiple mutators may hold this read lock simultaneously.
#
# The cycle collector acquires the exclusive write lock for the entire
# mark/scan/collect phase. This means the heap topology is *completely
# frozen* during collection: no `nimAsgnYrc` or seq operation can mutate
# any pointer field while the three passes run. This gives the Bacon
# algorithm the stable subgraph it requires without full write barriers.
#
# Consequence for incRef in `nimAsgnYrc`:
#   Because the collector is blocked, the incRef can be a direct atomic
#   increment on the RefHeader (`increment head(src)`) rather than going
#   through the `toInc` stripe queue. The collector will see the updated
#   RC immediately when it next acquires the write lock. Only decrements
#   (`yrcDec`) still use the `toDec` stripe queue so that objects whose RC
#   might reach zero are handled by the collector's cycle-detection logic.
#
# ## Why No Write Barrier Is Needed
#
# The classic concurrent-GC hazard is the "lost object" problem: during
# collection the mutator executes `A.field = B` where A is already scanned
# (black), B is reachable only through an unscanned (gray) object C, and then
# C's reference to B is removed. The collector never discovers B and frees it
# while A still points to it. Traditional concurrent collectors need write
# barriers to prevent this.
#
# This problem structurally cannot arise in YRC for two reasons:
#
# 1. The mutator lock freezes the topology during all three passes, so no
#    concurrent field write can race with markGray/scan/collectWhite.
#
# 2. Even without the lock, the cycle collector only frees *closed cycles* —
#    subgraphs where every reference to every member comes from within the
#    group, with zero external references. To execute `A.field = B` the
#    mutator must hold a reference to A (external ref), which `scan` would
#    rescue. The two conditions are mutually exclusive.
#
# In practice reason (1) makes reason (2) a belt-and-suspenders safety
# argument rather than the primary mechanism.

{.push raises: [].}

include cellseqs_v2

import std/locks

const
  NumStripes = 64
  QueueSize = 128
  RootsThreshold = 10

  colBlack = 0b000
  colGray = 0b001
  colWhite = 0b010
  maybeCycle = 0b100
  inRootsFlag = 0b1000
  colorMask = 0b011
  logOrc = defined(nimArcIds)

type
  TraceProc = proc (p, env: pointer) {.nimcall, gcsafe, raises: [].}
  DisposeProc = proc (p: pointer) {.nimcall, gcsafe, raises: [].}

when defined(nimYrcAtomicIncs):
  template color(c): untyped = atomicLoadN(addr c.rc, ATOMIC_ACQUIRE) and colorMask
  template setColor(c, col) =
    block:
      var expected = atomicLoadN(addr c.rc, ATOMIC_RELAXED)
      while true:
        let desired = (expected and not colorMask) or col
        if atomicCompareExchangeN(addr c.rc, addr expected, desired, true,
                                   ATOMIC_ACQ_REL, ATOMIC_RELAXED):
          break
  template loadRc(c): int = atomicLoadN(addr c.rc, ATOMIC_ACQUIRE)
  template trialDec(c) =
    discard atomicFetchAdd(addr c.rc, -rcIncrement, ATOMIC_ACQ_REL)
  template trialInc(c) =
    discard atomicFetchAdd(addr c.rc, rcIncrement, ATOMIC_ACQ_REL)
  template rcClearFlag(c, flag) =
    block:
      var expected = atomicLoadN(addr c.rc, ATOMIC_RELAXED)
      while true:
        let desired = expected and not flag
        if atomicCompareExchangeN(addr c.rc, addr expected, desired, true,
                                   ATOMIC_ACQ_REL, ATOMIC_RELAXED):
          break
  template rcSetFlag(c, flag) =
    block:
      var expected = atomicLoadN(addr c.rc, ATOMIC_RELAXED)
      while true:
        let desired = expected or flag
        if atomicCompareExchangeN(addr c.rc, addr expected, desired, true,
                                   ATOMIC_ACQ_REL, ATOMIC_RELAXED):
          break
else:
  template color(c): untyped = c.rc and colorMask
  template setColor(c, col) =
    when col == colBlack:
      c.rc = c.rc and not colorMask
    else:
      c.rc = c.rc and not colorMask or col
  template loadRc(c): int = c.rc
  template trialDec(c) = c.rc = c.rc -% rcIncrement
  template trialInc(c) = c.rc = c.rc +% rcIncrement
  template rcClearFlag(c, flag) = c.rc = c.rc and not flag
  template rcSetFlag(c, flag) = c.rc = c.rc or flag

const
  optimizedOrc = false
  useJumpStack = false

type
  GcEnv = object
    traceStack: CellSeq[ptr pointer]
    when useJumpStack:
      jumpStack: CellSeq[ptr pointer]
    toFree: CellSeq[Cell]
    freed, touched, edges, rcSum: int
    keepThreshold: bool

proc trace(s: Cell; desc: PNimTypeV2; j: var GcEnv) {.inline.} =
  if desc.traceImpl != nil:
    var p = s +! sizeof(RefHeader)
    cast[TraceProc](desc.traceImpl)(p, addr(j))

type
  Stripe = object
    when not defined(yrcAtomics):
      lockInc: Lock
    toIncLen: int
    toInc: array[QueueSize, Cell]
    lockDec: Lock
    toDecLen: int
    toDec: array[QueueSize, (Cell, PNimTypeV2)]

type
  PreventThreadFromCollectProc* = proc(): bool {.nimcall, gcsafe, raises: [].}
    ## Callback run before this thread runs the cycle collector.
    ## Return `true` to allow collection, `false` to skip (e.g. real-time thread).
    ## Invoked while holding the global lock; must not call back into YRC.

var
  roots: CellSeq[Cell]  # merged roots, used under global lock
  stripes: array[NumStripes, Stripe]
  rootsThreshold: int = 128
  defaultThreshold = when defined(nimFixedOrc): 10_000 else: 128
  gPreventThreadFromCollectProc: PreventThreadFromCollectProc = nil

proc GC_setPreventThreadFromCollectProc*(cb: PreventThreadFromCollectProc) =
  ##[ Can be used to customize the cycle collector for a thread. For example,
  to ensure that a hard realtime thread cannot run the cycle collector use:

  ```nim
  var hardRealTimeThread: int
  GC_setPreventThreadFromCollectProc(proc(): bool {.nimcall.} = hardRealTimeThread == getThreadId())
  ```

  To ensure that a hard realtime thread cannot by involved in any cycle collector activity use:

  ```nim
  GC_setPreventThreadFromCollectProc(proc(): bool {.nimcall.} =
    if hardRealTimeThread == getThreadId():
      writeStackTrace()
      echo "Realtime thread involved in unpredictable cycle collector activity!"
    result = false
  )
  ```
  ]##
  gPreventThreadFromCollectProc = cb

proc GC_getPreventThreadFromCollectProc*(): PreventThreadFromCollectProc =
  ## Returns the current "prevent thread from collecting proc".
  ## Typically `nil` if not set.
  result = gPreventThreadFromCollectProc

proc mayRunCycleCollect(): bool {.inline.} =
  if gPreventThreadFromCollectProc == nil: true
  else: not gPreventThreadFromCollectProc()

proc getStripeIdx(): int {.inline.} =
  getThreadId() and (NumStripes - 1)

proc nimIncRefCyclic(p: pointer; cyclic: bool) {.compilerRtl, inl.} =
  let h = head(p)
  when optimizedOrc:
    if cyclic: h.rc = h.rc or maybeCycle
  when defined(nimYrcAtomicIncs):
    discard atomicFetchAdd(addr h.rc, rcIncrement, ATOMIC_ACQ_REL)
  elif defined(yrcAtomics):
    let s = getStripeIdx()
    let slot = atomicFetchAdd(addr stripes[s].toIncLen, 1, ATOMIC_ACQ_REL)
    if slot < QueueSize:
      atomicStoreN(addr stripes[s].toInc[slot], h, ATOMIC_RELEASE)
    else:
      yrcCollectorLock:
        h.rc = h.rc +% rcIncrement
        for i in 0..<NumStripes:
          let len = atomicExchangeN(addr stripes[i].toIncLen, 0, ATOMIC_ACQUIRE)
          for j in 0..<min(len, QueueSize):
            let x = atomicLoadN(addr stripes[i].toInc[j], ATOMIC_ACQUIRE)
            x.rc = x.rc +% rcIncrement
  else:
    let idx = getStripeIdx()
    while true:
      var overflow = false
      withLock stripes[idx].lockInc:
        if stripes[idx].toIncLen < QueueSize:
          stripes[idx].toInc[stripes[idx].toIncLen] = h
          stripes[idx].toIncLen += 1
        else:
          overflow = true
      if overflow:
        yrcCollectorLock:
          for i in 0..<NumStripes:
            withLock stripes[i].lockInc:
              for j in 0..<stripes[i].toIncLen:
                let x = stripes[i].toInc[j]
                x.rc = x.rc +% rcIncrement
              stripes[i].toIncLen = 0
      else:
        break

proc mergePendingRoots() =
  # Merge buffered RC operations. Note: Unlike truly concurrent collectors,
  # we don't need to set color to black on incRef because collection runs
  # under the global lock, so no concurrent mutations happen during collection.
  for i in 0..<NumStripes:
    when not defined(nimYrcAtomicIncs):
      # Inc buffers only exist when increfs are buffered (not atomic)
      when defined(yrcAtomics):
        let incLen = atomicExchangeN(addr stripes[i].toIncLen, 0, ATOMIC_ACQUIRE)
        for j in 0..<min(incLen, QueueSize):
          let x = atomicLoadN(addr stripes[i].toInc[j], ATOMIC_ACQUIRE)
          x.rc = x.rc +% rcIncrement
      else:
        withLock stripes[i].lockInc:
          for j in 0..<stripes[i].toIncLen:
            let x = stripes[i].toInc[j]
            x.rc = x.rc +% rcIncrement
          stripes[i].toIncLen = 0
    withLock stripes[i].lockDec:
      for j in 0..<stripes[i].toDecLen:
        let (c, desc) = stripes[i].toDec[j]
        trialDec(c)
        if (loadRc(c) and inRootsFlag) == 0:
          rcSetFlag(c, inRootsFlag)
          if roots.d == nil: init(roots)
          add(roots, c, desc)
      stripes[i].toDecLen = 0

proc collectCycles()

when logOrc or orcLeakDetector:
  proc writeCell(msg: cstring; s: Cell; desc: PNimTypeV2) =
    when orcLeakDetector:
      cfprintf(cstderr, "%s %s file: %s:%ld; color: %ld; thread: %ld\n",
        msg, if desc != nil: desc.name else: cstring"(nil)", s.filename, s.line, s.color, getThreadId())
    else:
      # Guard nil desc/desc.name. Use cell pointer as id to avoid uninitialized s.refId (roots may have refId unset)
      let name = if desc != nil and desc.name != nil: desc.name else: cstring"(null)"
      cfprintf(cstderr, "%s %s %p isroot: %s; RC: %ld; color: %ld; thread: %ld\n",
        msg, name, s, (if (s.rc and inRootsFlag) != 0: "yes" else: "no"), s.rc shr rcShift, s.color, getThreadId())

proc free(s: Cell; desc: PNimTypeV2) {.inline.} =
  when traceCollector:
    cprintf("[From ] %p rc %ld color %ld\n", s, loadRc(s) shr rcShift, s.color)
  if (loadRc(s) and inRootsFlag) == 0:
    let p = s +! sizeof(RefHeader)
    when logOrc: writeCell("free", s, desc)
    if desc.destructor != nil:
      cast[DestructorProc](desc.destructor)(p)
    nimRawDispose(p, desc.align)

template orcAssert(cond, msg) =
  when logOrc:
    if not cond:
      cfprintf(cstderr, "[Bug!] %s\n", msg)
      rawQuit 1

proc nimTraceRef(q: pointer; desc: PNimTypeV2; env: pointer) {.compilerRtl, inl.} =
  let p = cast[ptr pointer](q)
  if p[] != nil:
    var j = cast[ptr GcEnv](env)
    j.traceStack.add(p, desc)

proc nimTraceRefDyn(q: pointer; env: pointer) {.compilerRtl, inl.} =
  let p = cast[ptr pointer](q)
  if p[] != nil:
    var j = cast[ptr GcEnv](env)
    j.traceStack.add(p, cast[ptr PNimTypeV2](p[])[])

proc scanBlack(s: Cell; desc: PNimTypeV2; j: var GcEnv) =
  s.setColor colBlack
  let until = j.traceStack.len
  trace(s, desc, j)
  when logOrc: writeCell("root still alive", s, desc)
  while j.traceStack.len > until:
    let (entry, desc) = j.traceStack.pop()
    let t = head entry[]
    trialInc(t)
    if t.color != colBlack:
      t.setColor colBlack
      trace(t, desc, j)
      when logOrc: writeCell("child still alive", t, desc)

proc markGray(s: Cell; desc: PNimTypeV2; j: var GcEnv) =
  if s.color != colGray:
    s.setColor colGray
    j.touched = j.touched +% 1
    j.rcSum = j.rcSum +% (loadRc(s) shr rcShift) +% 1
    orcAssert(j.traceStack.len == 0, "markGray: trace stack not empty")
    trace(s, desc, j)
    while j.traceStack.len > 0:
      let (entry, desc) = j.traceStack.pop()
      let t = head entry[]
      trialDec(t)
      j.edges = j.edges +% 1
      if t.color != colGray:
        t.setColor colGray
        j.touched = j.touched +% 1
        j.rcSum = j.rcSum +% (loadRc(t) shr rcShift) +% 2
        trace(t, desc, j)

proc scan(s: Cell; desc: PNimTypeV2; j: var GcEnv) =
  if s.color == colGray:
    if (loadRc(s) shr rcShift) >= 0:
      scanBlack(s, desc, j)
    else:
      orcAssert(j.traceStack.len == 0, "scan: trace stack not empty")
      s.setColor(colWhite)
      trace(s, desc, j)
      while j.traceStack.len > 0:
        let (entry, desc) = j.traceStack.pop()
        let t = head entry[]
        if t.color == colGray:
          if (loadRc(t) shr rcShift) >= 0:
            scanBlack(t, desc, j)
          else:
            t.setColor(colWhite)
            trace(t, desc, j)

proc collectColor(s: Cell; desc: PNimTypeV2; col: int; j: var GcEnv) =
  if s.color == col and (loadRc(s) and inRootsFlag) == 0:
    orcAssert(j.traceStack.len == 0, "collectWhite: trace stack not empty")
    s.setColor(colBlack)
    j.toFree.add(s, desc)
    trace(s, desc, j)
    while j.traceStack.len > 0:
      let (entry, desc) = j.traceStack.pop()
      let t = head entry[]
      entry[] = nil
      if t.color == col and (loadRc(t) and inRootsFlag) == 0:
        j.toFree.add(t, desc)
        t.setColor(colBlack)
        trace(t, desc, j)

proc collectCyclesBacon(j: var GcEnv; lowMark: int) =
  # YRC defers all destruction to collection time - process ALL roots through Bacon's algorithm
  # This is different from ORC which handles immediate garbage (rc == 0) directly
  if lockState == Collecting:
    return
  lockState = Collecting
  let last = roots.len -% 1
  when logOrc:
    for i in countdown(last, lowMark):
      writeCell("root", roots.d[i][0], roots.d[i][1])

  # Process all roots through markGray (Bacon's algorithm)
  for i in countdown(last, lowMark):
    markGray(roots.d[i][0], roots.d[i][1], j)

  var colToCollect = colWhite
  if j.rcSum == j.edges:
    # Short-cut: we know everything is garbage
    colToCollect = colGray
    j.keepThreshold = true
  else:
    # Normal scan phase
    for i in countdown(last, lowMark):
      scan(roots.d[i][0], roots.d[i][1], j)

  # Collect phase: free all garbage objects
  init j.toFree
  for i in 0 ..< roots.len:
    let s = roots.d[i][0]
    rcClearFlag(s, inRootsFlag)
    collectColor(s, roots.d[i][1], colToCollect, j)

  # Clear roots before freeing to prevent nested collectCycles() from accessing freed cells
  roots.len = 0

  # Free all collected objects
  # Destructors must not call nimDecRefIsLastCyclicStatic (add to toDec) during this phase
  for i in 0 ..< j.toFree.len:
    let s = j.toFree.d[i][0]
    when orcLeakDetector:
      writeCell("CYCLIC OBJECT FREED", s, j.toFree.d[i][1])
    free(s, j.toFree.d[i][1])
  j.freed = j.freed +% j.toFree.len
  deinit j.toFree

when defined(nimOrcStats):
  var freedCyclicObjects {.threadvar.}: int

proc collectCycles() =
  when logOrc:
    cfprintf(cstderr, "[collectCycles] begin\n")
  yrcCollectorLock:
    mergePendingRoots()
    if roots.len >= rootsThreshold and mayRunCycleCollect():
      let nRoots = roots.len
      var j: GcEnv
      init j.traceStack
      collectCyclesBacon(j, 0)
      if roots.len == 0 and roots.d != nil:
        deinit roots
      when not defined(nimStressOrc):
        if j.keepThreshold:
          discard
        elif j.freed *% 2 >= j.touched:
          when not defined(nimFixedOrc):
            rootsThreshold = max(rootsThreshold div 3 *% 2, 16)
          else:
            rootsThreshold = 0
        elif rootsThreshold < high(int) div 4:
          rootsThreshold = (if rootsThreshold <= 0: defaultThreshold else: rootsThreshold)
          rootsThreshold = rootsThreshold div 2 +% rootsThreshold
          # Cost-aware: if this run was expensive (large graph), raise threshold more so we don't run again too soon
          if j.touched > nRoots *% 4:
            rootsThreshold = rootsThreshold div 2 +% rootsThreshold
          rootsThreshold = min(rootsThreshold, defaultThreshold *% 16)
          rootsThreshold = min(rootsThreshold, nRoots *% 2)
      when logOrc:
        cfprintf(cstderr, "[collectCycles] end; freed %ld new threshold %ld\n", j.freed, rootsThreshold)
      when defined(nimOrcStats):
        inc freedCyclicObjects, j.freed
      deinit j.traceStack

when defined(nimOrcStats):
  type
    OrcStats* = object
      freedCyclicObjects*: int
  proc GC_orcStats*(): OrcStats =
    result = OrcStats(freedCyclicObjects: freedCyclicObjects)

proc GC_runOrc* =
  yrcCollectorLock:
    mergePendingRoots()
    if roots.len > 0 and mayRunCycleCollect():
      var j: GcEnv
      init j.traceStack
      collectCyclesBacon(j, 0)
      deinit j.traceStack
      roots.len = 0
  when logOrc: orcAssert roots.len == 0, "roots not empty!"

proc GC_enableOrc*() =
  when not defined(nimStressOrc):
    rootsThreshold = 0

proc GC_disableOrc*() =
  when not defined(nimStressOrc):
    rootsThreshold = high(int)

proc GC_prepareOrc*(): int {.inline.} =
  yrcCollectorLock:
    mergePendingRoots()
    result = roots.len

proc GC_partialCollect*(limit: int) =
  yrcCollectorLock:
    mergePendingRoots()
    if roots.len > limit and mayRunCycleCollect():
      var j: GcEnv
      init j.traceStack
      collectCyclesBacon(j, limit)
      deinit j.traceStack
      roots.len = limit

proc GC_fullCollect* =
  GC_runOrc()

proc GC_enableMarkAndSweep*() = GC_enableOrc()
proc GC_disableMarkAndSweep*() = GC_disableOrc()

const acyclicFlag = 1

when optimizedOrc:
  template markedAsCyclic(s: Cell; desc: PNimTypeV2): bool =
    (desc.flags and acyclicFlag) == 0 and (s.rc and maybeCycle) != 0
else:
  template markedAsCyclic(s: Cell; desc: PNimTypeV2): bool =
    (desc.flags and acyclicFlag) == 0

proc nimDecRefIsLastCyclicDyn(p: pointer): bool {.compilerRtl, inl.} =
  result = false
  if p != nil:
    let cell = head(p)
    let desc = cast[ptr PNimTypeV2](p)[]
    let idx = getStripeIdx()
    while true:
      var overflow = false
      withLock stripes[idx].lockDec:
        if stripes[idx].toDecLen < QueueSize:
          stripes[idx].toDec[stripes[idx].toDecLen] = (cell, desc)
          stripes[idx].toDecLen += 1
        else:
          overflow = true
      if overflow:
        collectCycles()
      else:
        break

proc nimDecRefIsLastDyn(p: pointer): bool {.compilerRtl, inl.} =
  nimDecRefIsLastCyclicDyn(p)

proc nimDecRefIsLastCyclicStatic(p: pointer; desc: PNimTypeV2): bool {.compilerRtl, inl.} =
  result = false
  if p != nil:
    let cell = head(p)
    let idx = getStripeIdx()
    while true:
      var overflow = false
      withLock stripes[idx].lockDec:
        if stripes[idx].toDecLen < QueueSize:
          stripes[idx].toDec[stripes[idx].toDecLen] = (cell, desc)
          stripes[idx].toDecLen += 1
        else:
          overflow = true
      if overflow:
        collectCycles()
      else:
        break

proc unsureAsgnRef(dest: ptr pointer, src: pointer) {.inline.} =
  dest[] = src
  if src != nil: nimIncRefCyclic(src, true)

proc yrcDec(tmp: pointer; desc: PNimTypeV2) {.inline.} =
  if desc != nil:
    discard nimDecRefIsLastCyclicStatic(tmp, desc)
  else:
    discard nimDecRefIsLastCyclicDyn(tmp)

proc nimAsgnYrc(dest: ptr pointer; src: pointer; desc: PNimTypeV2) {.compilerRtl.} =
  ## YRC write barrier for ref copy assignment.
  ## Holds the mutator read lock for the entire operation so the collector
  ## cannot run between the incRef and decRef, closing the stale-decRef
  ## bug. Direct atomic incRef replaces the toInc stripe queue: the
  ## collector is blocked, so the RC update is immediately visible and correct.
  acquireMutatorLock()
  if src != nil: increment head(src)   # direct atomic: no toInc queue needed
  let tmp = dest[]
  dest[] = src
  if tmp != nil: yrcDec(tmp, desc)     # still deferred via toDec for cycle detection
  releaseMutatorLock()

proc nimSinkYrc(dest: ptr pointer; src: pointer; desc: PNimTypeV2) {.compilerRtl.} =
  ## YRC write barrier for ref sink (move). No incRef on source.
  acquireMutatorLock()
  let tmp = dest[]
  dest[] = src
  if tmp != nil: yrcDec(tmp, desc)
  releaseMutatorLock()

proc nimMarkCyclic(p: pointer) {.compilerRtl, inl.} =
  when optimizedOrc:
    if p != nil:
      let h = head(p)
      h.rc = h.rc or maybeCycle

# Initialize locks at module load.
# RwLock stripes live in seqs_v2 (gYrcLocks); NumLockStripes is exported from there.
for i in 0..<NumLockStripes:
  initRwLock(gYrcLocks[i].lock)
for i in 0..<NumStripes:
  when not defined(yrcAtomics) and not defined(nimYrcAtomicIncs):
    initLock(stripes[i].lockInc)
  initLock(stripes[i].lockDec)

{.pop.}
