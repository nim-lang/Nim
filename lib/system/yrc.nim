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
# collection. This means the heap topology is *completely frozen* during
# collection: no `nimAsgnYrc` or seq operation can mutate any pointer field
# while the collector runs. This gives the algorithm below the stable
# subgraph it requires without write barriers.
#
# Consequence for incRef in `nimAsgnYrc`:
#   Because the collector is blocked, the incRef can be a direct atomic
#   increment on the RefHeader (`increment head(src)`) rather than going
#   through the `toInc` stripe queue. The collector will see the updated
#   RC immediately when it next acquires the write lock. Only decrements
#   (`yrcDec`) still use the `toDec` stripe queue so that objects whose RC
#   might reach zero are handled by the collector's cycle-detection logic.
#
# ## The Collection Algorithm
#
# Instead of the classic trial-deletion three-pass dance (markGray / scan /
# collectWhite) which mutates the rc words in place, collection is split
# into three phases that leave the heap untouched until the outcome is
# decided:
#
# 1. Capture: one Tarjan SCC traversal over everything reachable from the
#    candidate roots. Node -> dense index lookup is O(1) without hashing:
#    the spare `rootIdx` header word (unused by YRC otherwise) is stamped
#    with an epoch-tagged discovery index, so stale stamps never need
#    clearing. Everything else lives in side arrays (SoA layout).
#
# 2. Deadness: pure array work on the captured SCC condensation, no heap
#    access. An SCC is garbage iff it has no references beyond its internal
#    ones and no live SCC points to it:
#       external(S) = sum(refcounts of members) - internal edges - edges
#                     from garbage SCCs
#    Tarjan emits SCCs sinks-first, so one linear scan in reverse emission
#    order settles every SCC (sources before their targets).
#
# 3. Commit: only members of dead SCCs are touched. Every slot of a dead
#    member is nil'ed; slots pointing at survivors decrement the survivor's
#    rc for real (edges inside the dead group die with the group). Then the
#    members are destroyed and freed. Because the slots are nil by the time
#    destructors run, destructors cannot re-enter the decRef machinery for
#    the already-processed edges.
#
# This structure visits each edge at most twice (capture + commit of the
# dead subset) instead of up to three times, and — because the outcome is
# decided on captured data and the heap is only written in commit — it is
# the stepping stone towards optimistic, lock-free collection: replace the
# frozen-heap invariant with a SATB write barrier plus commit-time
# validation (rc word unchanged since capture, no barrier hit on a member)
# and the same three phases run concurrently with mutators.
#
# ## Why No Lost Objects
#
# The collector only frees *closed cycles* — subgraphs where every
# reference to every member comes from within the group, with zero external
# references. To mutate the graph a mutator must hold a reference to some
# object (an external ref), which the deadness computation observes in the
# rc word. The two conditions are mutually exclusive; the frozen topology
# makes this argument airtight without any barrier.

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
  template loadRc(c): int = c.rc
  template trialDec(c) = c.rc = c.rc -% rcIncrement
  template trialInc(c) = c.rc = c.rc +% rcIncrement
  template rcClearFlag(c, flag) = c.rc = c.rc and not flag
  template rcSetFlag(c, flag) = c.rc = c.rc or flag

const
  optimizedOrc = false

# ---------------- side structure for capture ----------------

type
  RawSeq[T] = object
    ## growable array of plain scalars, allocation idiom as in CellSeq
    len, cap: int
    d: ptr UncheckedArray[T]

proc resize[T](s: var RawSeq[T]; minCap: int) =
  s.cap = max(minCap, s.cap div 2 +% s.cap)
  let newSize = s.cap *% sizeof(T)
  when compileOption("threads"):
    s.d = cast[ptr UncheckedArray[T]](reallocShared(s.d, cast[Natural](newSize)))
  else:
    s.d = cast[ptr UncheckedArray[T]](realloc(s.d, cast[Natural](newSize)))

proc add[T](s: var RawSeq[T]; v: T) {.inline.} =
  if s.len >= s.cap: resize(s, s.len +% 1)
  s.d[s.len] = v
  s.len = s.len +% 1

proc pop[T](s: var RawSeq[T]): T {.inline.} =
  s.len = s.len -% 1
  result = s.d[s.len]

proc init[T](s: var RawSeq[T]; cap: int = 256) =
  s.len = 0
  s.cap = cap
  when compileOption("threads"):
    s.d = cast[ptr UncheckedArray[T]](allocShared(cast[Natural](s.cap *% sizeof(T))))
  else:
    s.d = cast[ptr UncheckedArray[T]](alloc(cast[Natural](s.cap *% sizeof(T))))

proc deinit[T](s: var RawSeq[T]) =
  if s.d != nil:
    when compileOption("threads"):
      deallocShared(s.d)
    else:
      dealloc(s.d)
    s.d = nil
  s.len = 0
  s.cap = 0

proc setLenZeroed[T](s: var RawSeq[T]; n: int) =
  if s.cap < n: resize(s, n)
  s.len = n
  zeroMem(s.d, n *% sizeof(T))

proc setLenUninit[T](s: var RawSeq[T]; n: int) =
  if s.cap < n: resize(s, n)
  s.len = n

type
  TarjanFrame = object
    u: int32     # dense index of the cell this frame belongs to
    base: int    # traceStack.len before this cell's trace ran

  CaptureRec = object
    ## per captured cell, position == Tarjan discovery index; one record so
    ## a node costs a single append during the DFS
    cell: Cell
    desc: PNimTypeV2
    rcWord: int               # rc word as captured
    lowlink: int32
    sccOf: int32              # -1 while the cell is on the Tarjan stack

  CaptureBufs = object
    ## side structure of a collection; persistent across collections (only
    ## the collector, under the global write lock, ever touches it) so that
    ## frequent small collections don't pay per-collection allocations
    recs: RawSeq[CaptureRec]
    tstack: RawSeq[int32]
    frames: RawSeq[TarjanFrame]
    edges: RawSeq[int64]      # (u shl 32) or v, dense indices
    sccMemStart: RawSeq[int32]
    sccMembers: RawSeq[int32]
    sumRefs: RawSeq[int]      # per SCC: sum of member reference counts
    internal: RawSeq[int]     # per SCC: number of intra-SCC edges
    deadIn: RawSeq[int]       # per SCC: number of edges from dead SCCs
    sccFlags: RawSeq[uint8]
    crossOff: RawSeq[int32]   # condensation cross edges, bucketed by source
    crossTgt: RawSeq[int32]
    crossCursor: RawSeq[int32]

  GcEnv = object
    traceStack: CellSeq[ptr pointer]
    toFree: CellSeq[Cell]
    nScc: int
    nDeadScc: int
    freed, touched: int
    keepThreshold: bool

var gCap: CaptureBufs

const
  flagDead = 1'u8
  flagForcedLive = 2'u8

proc trace(s: Cell; desc: PNimTypeV2; j: var GcEnv) {.inline.} =
  if desc.traceImpl != nil:
    var p = s +! sizeof(RefHeader)
    cast[TraceProc](desc.traceImpl)(p, addr(j))

# The spare rootIdx header word (unused by YRC's root registration, which
# relies on inRootsFlag) doubles as the capture stamp: it packs an epoch tag
# with the cell's dense discovery index, so node -> index lookup is one load
# and stale stamps from earlier collections never need clearing.
var gCaptureEpoch: int = 1

when sizeof(int) == 8:
  # 31-bit epoch, wraps after 2^31 collections (decades of uptime); on wrap
  # a stale stamp collision is astronomically unlikely but not impossible.
  template bumpEpoch() =
    gCaptureEpoch = (gCaptureEpoch +% 1) and 0x7FFFFFFF
    if gCaptureEpoch == 0: gCaptureEpoch = 1
  template isStamped(c: Cell): bool = (c.rootIdx shr 32) == gCaptureEpoch
  template stamp(c: Cell; idx: int) =
    c.rootIdx = gCaptureEpoch shl 32 or idx
  template denseIdx(c: Cell): int32 = int32(c.rootIdx and 0xFFFFFFFF)
else:
  # no room for an epoch: stamps are cleared at the end of each collection
  template bumpEpoch() = discard
  template isStamped(c: Cell): bool = c.rootIdx != 0
  template stamp(c: Cell; idx: int) = c.rootIdx = idx +% 1
  template denseIdx(c: Cell): int32 = int32(c.rootIdx -% 1)

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
  # we don't need any color handling on incRef because collection runs
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

# ---------------- phase 1: capture ----------------

proc prepareCapture() =
  if gCap.recs.d == nil:
    init gCap.recs
    init gCap.tstack
    init gCap.frames
    init gCap.edges
    init gCap.sccMemStart
    init gCap.sccMembers
    init gCap.sumRefs
    init gCap.internal
    init gCap.deadIn
    init gCap.sccFlags
    init gCap.crossOff
    init gCap.crossTgt
    init gCap.crossCursor
  else:
    gCap.recs.len = 0
    gCap.tstack.len = 0
    gCap.frames.len = 0
    gCap.edges.len = 0
    gCap.sccMemStart.len = 0
    gCap.sccMembers.len = 0
    gCap.sumRefs.len = 0

proc pushCell(c: Cell; desc: PNimTypeV2): int32 {.inline.} =
  result = int32(gCap.recs.len)
  stamp(c, gCap.recs.len)
  gCap.recs.add CaptureRec(cell: c, desc: desc, rcWord: loadRc(c),
                           lowlink: result, sccOf: -1'i32)
  gCap.tstack.add result

proc capture(s: Cell; desc: PNimTypeV2; j: var GcEnv) =
  ## Iterative Tarjan SCC over everything reachable from `s`. A frame's
  ## pending out-edges are the traceStack entries above frame.base; a child
  ## pushes and drains its own segment above ours, so when the child's frame
  ## pops, the stack is back at our segment and we resume popping our edges.
  if isStamped(s): return
  orcAssert(j.traceStack.len == 0, "capture: trace stack not empty")
  let root = pushCell(s, desc)
  trace(s, desc, j)
  gCap.frames.add TarjanFrame(u: root, base: 0)
  while gCap.frames.len > 0:
    let u = gCap.frames.d[gCap.frames.len -% 1].u
    let base = gCap.frames.d[gCap.frames.len -% 1].base
    if j.traceStack.len > base:
      let (slot, tdesc) = j.traceStack.pop()
      let t = head(slot[])
      if isStamped(t):
        let v = denseIdx(t)
        gCap.edges.add (int64(u) shl 32) or int64(v)
        if gCap.recs.d[v].sccOf < 0 and v < gCap.recs.d[u].lowlink:
          gCap.recs.d[u].lowlink = v
      else:
        let childBase = j.traceStack.len
        let v = pushCell(t, tdesc)
        gCap.edges.add (int64(u) shl 32) or int64(v)
        trace(t, tdesc, j)
        gCap.frames.add TarjanFrame(u: v, base: childBase)
    else:
      gCap.frames.len = gCap.frames.len -% 1
      if gCap.frames.len > 0:
        let pu = gCap.frames.d[gCap.frames.len -% 1].u
        if gCap.recs.d[u].lowlink < gCap.recs.d[pu].lowlink:
          gCap.recs.d[pu].lowlink = gCap.recs.d[u].lowlink
      if gCap.recs.d[u].lowlink == u:
        # u is the root of an SCC: pop the members off the Tarjan stack
        gCap.sccMemStart.add int32(gCap.sccMembers.len)
        var sum = 0
        while true:
          let w = gCap.tstack.pop()
          gCap.recs.d[w].sccOf = int32(j.nScc)
          gCap.sccMembers.add w
          sum = sum +% (gCap.recs.d[w].rcWord shr rcShift) +% 1
          if w == u: break
        gCap.sumRefs.add sum
        inc j.nScc

# ---------------- phase 2: deadness, side arrays only ----------------

proc computeDeadness(j: var GcEnv) =
  let nScc = j.nScc
  setLenZeroed gCap.internal, nScc
  setLenZeroed gCap.deadIn, nScc
  setLenZeroed gCap.sccFlags, nScc
  setLenZeroed gCap.crossOff, nScc + 1
  setLenUninit gCap.crossCursor, nScc
  # classify captured edges: internal to an SCC vs condensation cross edges
  var nCross = 0
  for i in 0 ..< gCap.edges.len:
    let e = gCap.edges.d[i]
    let su = gCap.recs.d[int32(e shr 32)].sccOf
    let sv = gCap.recs.d[int32(e and 0xFFFFFFFF'i64)].sccOf
    if su == sv:
      inc gCap.internal.d[su]
    else:
      inc gCap.crossOff.d[su]
      inc nCross
  var total = 0'i32
  for s in 0 ..< nScc:
    let c = gCap.crossOff.d[s]
    gCap.crossOff.d[s] = total
    gCap.crossCursor.d[s] = total
    total = total +% c
  gCap.crossOff.d[nScc] = total
  setLenUninit gCap.crossTgt, nCross
  for i in 0 ..< gCap.edges.len:
    let e = gCap.edges.d[i]
    let su = gCap.recs.d[int32(e shr 32)].sccOf
    let sv = gCap.recs.d[int32(e and 0xFFFFFFFF'i64)].sccOf
    if su != sv:
      gCap.crossTgt.d[gCap.crossCursor.d[su]] = sv
      inc gCap.crossCursor.d[su]
  # cells that stay registered as roots (partial collection) count as
  # externally referenced: the roots buffer itself points at them
  for mi in 0 ..< gCap.sccMembers.len:
    let m = gCap.sccMembers.d[mi]
    if (loadRc(gCap.recs.d[m].cell) and inRootsFlag) != 0:
      let s = gCap.recs.d[m].sccOf
      gCap.sccFlags.d[s] = gCap.sccFlags.d[s] or flagForcedLive
  # deadness over the condensation. Tarjan emits sinks first, so higher SCC
  # ids are sources and every cross edge goes from a higher id to a lower
  # one: one reverse scan settles everything.
  for s in countdown(nScc - 1, 0):
    let ext = gCap.sumRefs.d[s] -% gCap.internal.d[s] -% gCap.deadIn.d[s]
    when logOrc:
      cfprintf(cstderr, "[scc %ld] members %ld sumRefs %ld internal %ld deadIn %ld ext %ld forced %ld\n",
        s, gCap.sccMemStart.d[s+1] - gCap.sccMemStart.d[s], gCap.sumRefs.d[s],
        gCap.internal.d[s], gCap.deadIn.d[s], ext, int(gCap.sccFlags.d[s]))
    if (gCap.sccFlags.d[s] and flagForcedLive) == 0 and ext == 0:
      gCap.sccFlags.d[s] = gCap.sccFlags.d[s] or flagDead
      inc j.nDeadScc
      for k in gCap.crossOff.d[s] ..< gCap.crossOff.d[s+1]:
        inc gCap.deadIn.d[gCap.crossTgt.d[k]]
    else:
      # a live SCC keeps everything it points to alive
      for k in gCap.crossOff.d[s] ..< gCap.crossOff.d[s+1]:
        let t = gCap.crossTgt.d[k]
        gCap.sccFlags.d[t] = gCap.sccFlags.d[t] or flagForcedLive

# ---------------- phase 3: commit ----------------

proc commitDead(j: var GcEnv) =
  init j.toFree
  template deadCell(t: Cell): bool =
    isStamped(t) and (gCap.sccFlags.d[gCap.recs.d[denseIdx(t)].sccOf] and flagDead) != 0
  let allDead = j.nDeadScc == j.nScc
  for s in 0 ..< j.nScc:
    if (gCap.sccFlags.d[s] and flagDead) != 0:
      for mi in gCap.sccMemStart.d[s] ..< gCap.sccMemStart.d[s+1]:
        let m = gCap.sccMembers.d[mi]
        let cell = gCap.recs.d[m].cell
        let desc = gCap.recs.d[m].desc
        j.toFree.add(cell, desc)
        # nil every slot so the destructor cannot dec these edges again;
        # references to survivors are decremented for real, references into
        # the dead group die with the group (already accounted by deadIn)
        orcAssert(j.traceStack.len == 0, "commitDead: trace stack not empty")
        trace(cell, desc, j)
        if allDead:
          # everything captured dies: no survivor can occur, just nil
          while j.traceStack.len > 0:
            let (slot, _) = j.traceStack.pop()
            slot[] = nil
        else:
          while j.traceStack.len > 0:
            let (slot, _) = j.traceStack.pop()
            let t = head(slot[])
            slot[] = nil
            if not deadCell(t):
              trialDec(t)
  when sizeof(int) != 8:
    # no epoch in the stamp: clear them while all cells are still alive
    for i in 0 ..< gCap.recs.len:
      gCap.recs.d[i].cell.rootIdx = 0
  for i in 0 ..< j.toFree.len:
    when orcLeakDetector:
      writeCell("CYCLIC OBJECT FREED", j.toFree.d[i][0], j.toFree.d[i][1])
    free(j.toFree.d[i][0], j.toFree.d[i][1])
  j.freed = j.toFree.len
  deinit j.toFree

proc collectCyclesImpl(j: var GcEnv; lowMark: int) =
  # All destruction is deferred to collection time: plain rc==0 garbage in
  # the roots buffer forms singleton SCCs with external count 0 and is freed
  # by the same machinery as the cycles.
  if lockState == Collecting:
    return
  lockState = Collecting
  let last = roots.len -% 1
  when logOrc:
    for i in countdown(last, lowMark):
      writeCell("root", roots.d[i][0], roots.d[i][1])

  bumpEpoch()
  init j.traceStack
  prepareCapture()
  j.nScc = 0

  for i in countdown(last, lowMark):
    capture(roots.d[i][0], roots.d[i][1], j)
  gCap.sccMemStart.add int32(gCap.sccMembers.len)   # sentinel
  j.touched = gCap.recs.len

  # Unregister the processed roots before computing deadness: only cells that
  # STAY registered (below lowMark, partial collection) count as externally
  # referenced by the roots buffer. Doing this before freeing anything also
  # ensures a nested collectCycles() (triggered from a destructor) cannot
  # access freed cells.
  for i in lowMark ..< roots.len:
    rcClearFlag(roots.d[i][0], inRootsFlag)
  roots.len = lowMark

  computeDeadness(j)
  commitDead(j)
  j.keepThreshold = j.freed == j.touched and j.touched > 0

  deinit j.traceStack

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
      collectCyclesImpl(j, 0)
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
      collectCyclesImpl(j, 0)
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
      collectCyclesImpl(j, limit)

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
