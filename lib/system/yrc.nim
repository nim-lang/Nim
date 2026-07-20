#
# YRC: Thread-safe ORC (concurrent cycle collector).
# Same API as orc.nim. Destructors for refs run at collection time, not
# immediately on the last decRef.
# See yrc_proof.lean for a machine-checked (Lean 4) proof of the core
# invariants — garbage stability, validation soundness, capture partition
# disjointness, grace periods, fence mutual exclusion, deadlock freedom —
# and yrc_tarjan_proof.lean for soundness AND completeness of the SCC
# deadness algorithm.
#
# ## Synchronization at a Glance
#
# Ref-field writes (`nimAsgnYrc`, `nimSinkYrc`) are LOCK-FREE: an atomic
# incRef of the new value, an atomic exchange of the slot, a deferred
# decRef of the old value enqueued into a stripe queue. The stripe queues
# have LOCK-FREE PRODUCERS — reserve a slot by fetch-add, then publish it
# (see the Stripe declaration for the inc/dec publication asymmetry); the
# per-stripe consumerLock only serializes drains against each other.
#
# Candidate roots are THREAD-LOCAL (gLocalRoots): draining a thread's
# stripe registers candidates locally, and the thread's own collections
# steal that buffer as their root slice — the common path from
# "suspicious dec" to "freed" never crosses a thread. Exiting threads
# spill their buffer to a global orphan list, adopted by the next
# collection anywhere. A cell sits in at most one buffer, guarded by an
# atomic test-and-set of inRootsFlag; buffered cells are forced live.
#
# Up to MaxPar collections run CONCURRENTLY — with the mutators and with
# each other — each capturing a disjoint partition of the heap by CAS-ing
# a claim tag into the rootIdx header word. gMergeLock covers only the
# tag-slot claim and orphan adoption. All waiting (for a free slot, for a
# solo capture, for a grace period) is a bounded spin, then parking on
# gWaitCond.
#
# Seq mutations that change container structure (add/grow/setLen/shrink)
# announce themselves in the striped gSeqActive counters (seqs_v2.nim); a
# starting collection waits for those to drain (yrcGcFenceEnter) so its
# traversal never sees a torn len/payload pair or a freed payload. This
# fence is the only point where mutators delay a collector.
#
# ## The Write Barrier
#
# A concurrent trial-deletion collector needs a snapshot-at-the-beginning
# (Yuasa) barrier: every reference-set change since the collection started
# must be observable at commit time. YRC gets this FOR FREE from its
# deferred RC machinery:
#
# * Removing an edge enqueues the old value into `toDec` — and because the
#   dec is deferred, the rc word keeps counting the removed reference until
#   the *next* collection's merge: deletions can only make the captured
#   graph look MORE alive, never less.
# * Stack copies enqueue into `toInc` (buffered incs).
# * Direct rc mutations (`nimAsgnYrc`'s incRef, queue drains, overflow
#   incs) are atomic RMWs — globally visible when they retire, which the
#   commit-time rc validation relies on.
#
# So the commit-time validation is:
#   1. Any cell sitting in a `toInc`/`toDec` queue had its reference set
#      changed during capture: its SCC is "dirty" and must not be freed
#      this round (the entries stay queued; the next merge re-registers
#      them as candidate roots).
#   2. Any dead-classified member whose rc word changed since capture saw a
#      direct incRef: a mutator published a new reference to it. Abort.
# Everything else was garbage when the collection started, and garbage is
# stable: nothing can reach it, so nothing can resurrect or mutate it.
# Aborted SCCs cost nothing (capture never writes to the heap) and are
# re-registered for the next round.
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
#    the spare `rootIdx` header word (a full int64 on every target so the
#    concurrent claim and epoch-stamp packing work identically on 32-bit
#    archs) is CAS-claimed with the collection's tag packed with the
#    discovery index; stale tags of retired collections never need
#    clearing. Per-cell data lives in one record array indexed by that
#    discovery index; per-SCC data in one record array indexed by SCC id.
#
# 2. Deadness: pure array work on the captured SCC condensation, no heap
#    access. An SCC is garbage iff it has no references beyond its internal
#    ones and no live SCC points to it:
#       external(S) = sum(refcounts of members) - internal edges - edges
#                     from garbage SCCs
#    Tarjan emits SCCs sinks-first, so one linear scan in reverse emission
#    order settles every SCC (sources before their targets).
#
# 3. Validate & commit: after validation (dirty peek + rc recheck, with
#    demotions propagated to captured cross targets) and a grace period
#    (foreign captures may still hold stale slot snapshots), only members
#    of dead SCCs are touched. Every slot of a dead member is nil'ed;
#    slots pointing at survivors decrement the survivor's rc for real
#    (edges inside the dead group die with the group). Then the members
#    are destroyed and freed — the slots are nil by the time destructors
#    run, so destructors cannot re-enter the decRef machinery for the
#    already-processed edges. When everything captured died and no
#    cross-collection or pruned edge was seen, nil+free fuse into a
#    single pass.
#
# This structure visits each edge at most twice (capture + commit of the
# dead subset) instead of up to three times, and — because the outcome is
# decided on captured data and the heap is only written in commit —
# capture runs OPTIMISTICALLY, concurrent with mutators and with other
# collections, with the validation above as the safety net.
#
# ## Generational Epoch Stamps
#
# Commit re-stamps the cells it PROVED live with the current epoch and
# their survival age (same rootIdx word, in a namespace disjoint from the
# claim tags). Within that epoch, captures treat a stamped DESCENDANT of
# promoted age as an opaque live external and do not descend: long-lived
# structures are traced once per epoch instead of once per collection,
# while die-young data — never promoted — is never deferred. Roots always
# bypass stamps (every death has a dec-witness that gets registered, and
# registered cells are always scanned as roots), and explicit full
# collects advance the epoch first, staying exhaustive. The price is
# floating garbage bounded by ~2 epochs.
#
# ## Why No Lost Objects
#
# The collector only frees *closed cycles* — subgraphs where every
# reference to every member comes from within the group, with zero external
# references. To mutate the graph a mutator must hold a reference to some
# object; every way of obtaining or dropping such a reference leaves a
# trace the commit validation observes: a direct atomic incRef (rc-delta
# check), a buffered inc/dec in the stripe queues (dirty check), or a heap
# edge that capture traversed (classified live). Snapshot-garbage is
# unreachable, leaves no such traces, and is freed on the first attempt.

{.push raises: [].}

include cellseqs_v2

import std/locks

const
  NumStripes = 64
  QueueSize {.intdefine.} = 128   # override with -d:QueueSize=N

  # rc-word flag bits, layout shared with ORC. YRC does no tricolor
  # marking; colorMask survives only for the debug printout.
  maybeCycle = 0b100
  inRootsFlag = 0b1000
  colorMask = 0b011
  logOrc = defined(nimArcIds)

type
  TraceProc = proc (p, env: pointer) {.nimcall, gcsafe, raises: [].}

# The write barrier's incRef normally goes through a lock-free per-stripe
# queue (drained by the collector), matching the deferred decRef. Define
# `nimYrcDirectIncs` to bypass that queue and apply incRefs directly with an
# atomic RMW instead — simpler, but the collector then observes every incRef
# through commit-time rc validation rather than the queue peek.
const useIncQueue = not defined(nimYrcDirectIncs)

# With lock-free ref assignments, rc words are mutated concurrently with the
# collector (direct atomic incRefs), so all collector-side rc accesses must
# be atomic whenever threads exist.
const useAtomicRc = not useIncQueue or hasThreadSupport

when useAtomicRc:
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
  template rcTestSetFlag(c, flag): bool =
    ## Atomically set `flag`; evaluates to true iff THIS call set it (it
    ## was clear). Candidate registration must win this race so that a
    ## cell sits in at most one candidate buffer.
    block:
      var expected = atomicLoadN(addr c.rc, ATOMIC_RELAXED)
      var won = false
      while (expected and flag) == 0:
        if atomicCompareExchangeN(addr c.rc, addr expected, expected or flag,
                                   true, ATOMIC_ACQ_REL, ATOMIC_RELAXED):
          won = true
          break
      won
else:
  template color(c): untyped = c.rc and colorMask
  template loadRc(c): int = c.rc
  template trialDec(c) = c.rc = c.rc -% rcIncrement
  template trialInc(c) = c.rc = c.rc +% rcIncrement
  template rcClearFlag(c, flag) = c.rc = c.rc and not flag
  template rcTestSetFlag(c, flag): bool =
    block:
      let won = (c.rc and flag) == 0
      if won: c.rc = c.rc or flag
      won

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
  TraceEntry = object
    ## (slot, value) snapshot taken at trace time. The value is read exactly
    ## once: `nimTraceRefDyn` derives the type descriptor from it, so using
    ## the snapshot everywhere guarantees descriptor and value always match
    ## even when a mutator concurrently overwrites the slot.
    slot: ptr pointer
    val: pointer

  TarjanFrame = object
    u: int32     # dense index of the cell this frame belongs to
    base: int    # traceStack.len before this cell's trace ran

  CaptureRec = object
    ## per captured cell, position == Tarjan discovery index; one record so
    ## a node costs a single append during the DFS. Kept at 32 bytes: this
    ## is the hottest array in the capture DFS, so cold data that is read at
    ## most once per survivor (e.g. the survival age) stays in a side array.
    cell: Cell
    desc: PNimTypeV2
    rcWord: int               # rc word as captured
    lowlink: int32
    sccOf: int32              # -1 while the cell is on the Tarjan stack

  SccRec = object
    ## per SCC of the condensation; the deadness pass reads all of these
    ## fields together, so one record per SCC beats parallel arrays. The
    ## array carries a sentinel record at [nScc]: memStart/crossOff are
    ## prefix offsets, an SCC's slice is [s]..<[s+1].
    sumRefs: int              # sum of member reference counts
    internal: int             # number of intra-SCC edges
    deadIn: int               # number of edges from dead SCCs
    memStart: int32           # offset into sccMembers
    crossOff: int32           # offset into crossTgt (cross edges by source)
    crossCursor: int32
    flags: uint8

  CaptureBufs = object
    ## side structure of a collection; per collector thread (gCap is a
    ## threadvar) and persistent across collections, so that frequent
    ## small collections don't pay per-collection allocations
    recs: RawSeq[CaptureRec]
    tstack: RawSeq[int32]
    frames: RawSeq[TarjanFrame]
    edges: RawSeq[int64]      # (u shl 32) or v, dense indices
    sccs: RawSeq[SccRec]
    sccMembers: RawSeq[int32]
    crossTgt: RawSeq[int32]
    crossPend: CellSeq[Cell]  # edge targets owned by other active collections
    prunedSrc: RawSeq[int32]  # dense indices of cells with pruned out-edges
    ages: RawSeq[int32]       # per captured cell: captures survived so far

  GcEnv = object
    traceStack: CellSeq[TraceEntry]
    toFree: CellSeq[Cell]
    nScc: int
    nDeadScc: int
    nAborted: int
    freed, touched: int
    keepThreshold: bool

var gCap {.threadvar.}: CaptureBufs

const
  flagDead = 1'u8
  flagForcedLive = 2'u8
  flagDirty = 4'u8   # a member's reference set changed during capture
  flagPruned = 8'u8  # an out-edge was pruned via an epoch stamp: a "live"
                     # verdict may lean on stale stamps, keep it examinable

proc trace(s: Cell; desc: PNimTypeV2; j: var GcEnv) {.inline.} =
  if desc.traceImpl != nil:
    var p = s +! sizeof(RefHeader)
    cast[TraceProc](desc.traceImpl)(p, addr(j))

# The spare rootIdx header word (unused by YRC's root registration, which
# relies on inRootsFlag) doubles as the capture claim: it packs the owning
# collection's tag with the cell's dense discovery index. Up to MaxPar
# collections run CONCURRENTLY, each capturing a disjoint partition of the
# heap: the first collection to CAS its tag into a cell owns it; everyone
# else treats the cell as an opaque survivor. Stale tags (from retired
# collections) never need clearing, they are simply reclaimable.
#
# The word does double duty a second time: commit re-stamps proven-live
# cells with the current EPOCH (high-word namespace disjoint from tags, so
# the claim protocol is unchanged). Within the same epoch a capture treats
# a stamped DESCENDANT as an opaque live external and does not descend —
# long-lived live structures are traced once per epoch instead of once per
# collection. Roots always bypass the stamp: every death has a dec-witness
# that gets registered, and registered cells are always scanned as roots.
const
  MaxPar {.intdefine.} = 8        # max concurrent collections
  ParSlots = MaxPar

var
  gMergeLock: Lock                       # protects the tag slots + orphaned roots
  gActiveTags: array[ParSlots, int64]    # 0 = free slot
  gSlotPhase: array[ParSlots, int]       # 0 idle, 1 capturing, 2 committing
  gSoloCapture: int                      # a solo collection is in its capture phase
  gTagCounter: int64
  gMyTag {.threadvar.}: int64
  gMySlot {.threadvar.}: int
  gAmSolo {.threadvar.}: bool
  gEpoch: int                            # advanced every YrcEpochLen collections
  gCollectionCounter: int
  gMyEpochStamp {.threadvar.}: int64     # this collection's epoch, as a stamp word
  gWaitLock: Lock                        # pairs gWaitCond's wait/broadcast; leaf
  gWaitCond: Cond                        # signaled on capture-end and collection-finish

const
  SpinBeforePark = 4000
  YrcEpochLen {.intdefine.} = 64  # collections per epoch; bounds how long a
                                  # stale "proven live" stamp defers rescans.
                                  # Short epochs resonate badly with the
                                  # adaptive threshold: pruned collections
                                  # are cheap, so collections speed up — and
                                  # with them the epoch clock, forcing full
                                  # re-traces MORE often than no stamps at
                                  # all. (A work-based clock would fix this
                                  # properly.)
  YrcPromoteAge {.intdefine.} = 3 # captures a cell must survive before its
                                  # stamp prunes. Die-young data must never
                                  # be deferred: torcbench-style lists are
                                  # traced ~2x per lifetime (the second trace
                                  # is usually the last), so promoting at 2
                                  # doubles worker maxMem via death floats;
                                  # at 3 the floats vanish while long-lived
                                  # webs (traced >> 3x) keep the full win
  epochBase = 0x40000000          # stamp namespace: tags stay below this
  epochMask = 0x3FFFFFFF

# stamp layout: high word = epochBase|epoch, low word = survival age
template epochStamp(e: int): int64 = int64(epochBase or (e and epochMask)) shl 32
template stampAge(w: int64): int = int(w and 0xFFFFFFFF)
template isEpochStamp(w: int64): bool = (w shr 32) >= epochBase

template parkUntil(cond: untyped) =
  ## Bounded spin (collections transition in microseconds when the system is
  ## healthy), then block on gWaitCond. `cond` must only read atomics, and
  ## every write that can make it true is followed by collectorEvent().
  var spins {.inject.} = 0
  while not (cond):
    inc spins
    if spins >= SpinBeforePark:
      acquire gWaitLock
      while not (cond):
        wait(gWaitCond, gWaitLock)
      release gWaitLock
      break

proc collectorEvent() {.inline.} =
  ## Wake every parked collector after a slot/phase/solo transition. The
  ## broadcast happens under gWaitLock so that a waiter that saw the old
  ## state is already inside wait() by the time we broadcast.
  acquire gWaitLock
  broadcast gWaitCond
  release gWaitLock

proc anySlotFree(): bool {.inline.} =
  result = false
  for sl in 0 ..< ParSlots:
    if atomicLoadN(addr gActiveTags[sl], ATOMIC_ACQUIRE) == 0:
      return true

template isStamped(c: Cell): bool =
  # "stamped" means: claimed by THIS collection. A relaxed load suffices:
  # only this thread ever stores gMyTag, and any stale read of a foreign
  # value routes into claimCell which re-validates with acquire + CAS.
  (atomicLoadN(addr c.rootIdx, ATOMIC_RELAXED) shr 32) == gMyTag
template denseIdx(c: Cell): int32 =
  int32(atomicLoadN(addr c.rootIdx, ATOMIC_RELAXED) and 0xFFFFFFFF)

proc isActiveTag(t: int64): bool {.inline.} =
  result = false
  if t != 0:
    for s in 0 ..< ParSlots:
      if atomicLoadN(addr gActiveTags[s], ATOMIC_ACQUIRE) == t:
        return true

type
  Stripe = object
    consumerLock: Lock
      ## consumers (drains) exclude each other; producers and the
      ## validation peek are lock-free
    toIncLen: int     # reservation counters; may exceed QueueSize under
    toDecLen: int     # overflow — reservations past QueueSize never write
    toInc: array[QueueSize, Cell]
      ## produced lock-free: reserve via fetch-add, publish the cell with
      ## an atomic EXCHANGE (non-nil = ready; globals start zeroed and the
      ## consumer nils consumed slots). The publish must be an RMW, not a
      ## release store: a queued inc means the rc word UNDER-counts a live
      ## reference, so the validation peek must reliably observe every
      ## entry of a completed barrier — an RMW is globally ordered when it
      ## retires, a release store could still sit in a store buffer.
    toDec: array[QueueSize, (Cell, PNimTypeV2)]
      ## produced lock-free: reserve via fetch-add, store the cell, then
      ## publish by storing the desc with release order (desc != nil =
      ## ready). A plain release suffices here: a pending dec leaves the
      ## target's rc with an unexplained surplus that forces it live even
      ## if a peek misses the entry.

type
  PreventThreadFromCollectProc* = proc(): bool {.nimcall, gcsafe, raises: [].}
    ## Callback run before this thread runs the cycle collector.
    ## Return `true` to allow collection, `false` to skip (e.g. real-time thread).
    ## Invoked lock-free before this thread would start a collection;
    ## must not call back into YRC.

var
  roots: CellSeq[Cell]  # ORPHANED candidates only: spilled by exiting
                        # threads, adopted by the next collection on any
                        # thread. Guarded by gMergeLock.
  gLocalRoots {.threadvar.}: CellSeq[Cell]
    ## This thread's candidate roots. Only the owning thread touches it:
    ## draining this thread's stripe queue registers candidates here, and
    ## this thread's collections steal it as their slice — no lock, and
    ## collections keep the cache locality of thread-local data.
  stripes: array[NumStripes, Stripe]
  rootsThreshold: int = 128   # shared adaptive heuristic; races are benign
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
  when useIncQueue:
    # LOCK-FREE producer: reserve, then publish with an atomic exchange
    # (see the Stripe declaration for why an RMW and not a release store)
    let idx = getStripeIdx()
    let slot = atomicFetchAdd(addr stripes[idx].toIncLen, 1, ATOMIC_ACQ_REL)
    if slot < QueueSize:
      discard atomicExchangeN(addr stripes[idx].toInc[slot], h, ATOMIC_ACQ_REL)
    else:
      # queue full: apply the inc directly — it is atomic, so a running
      # collection observes it through the commit-time rc validation.
      # Buffering resumes once the next drain resets the queue.
      trialInc(h)
  else:
    discard atomicFetchAdd(addr h.rc, rcIncrement, ATOMIC_ACQ_REL)

when defined(nimOrcStats):
  var
    gStatRegFresh: int    # registrations of never-captured cells
    gStatRegRepeat: int   # re-registrations of cells that already survived a capture
    gStatRegCross: int    # registrations of cells claimed by a foreign ACTIVE collection
    gStatRegSelf: int     # re-registrations by the collection that holds the cell (demotions)
    gStatCapTotal: int    # cells claimed into captures (traced by the Tarjan DFS)
    gStatCapRepeat: int   # ...that had already been captured (and survived) before
    gStatCapPruned: int   # edges pruned via a current-epoch stamp

  template bumpStat(x: untyped) =
    discard atomicAddFetch(addr x, 1, ATOMIC_RELAXED)

proc registerLocal(c: Cell; desc: PNimTypeV2) {.inline.} =
  ## Register a candidate in THIS thread's buffer. The atomic test-and-set
  ## keeps the invariant that a cell sits in at most one candidate buffer:
  ## whoever wins the flag owns the registration. Buffered cells are forced
  ## live by every collection (deadness checks the flag), so no buffer
  ## entry can ever dangle.
  if rcTestSetFlag(c, inRootsFlag):
    when defined(nimOrcStats):
      let st = atomicLoadN(addr c.rootIdx, ATOMIC_RELAXED)
      if st == 0: bumpStat gStatRegFresh
      elif gMyTag != 0 and (st shr 32) == gMyTag: bumpStat gStatRegSelf
      elif isActiveTag(st shr 32): bumpStat gStatRegCross
      else: bumpStat gStatRegRepeat
    if gLocalRoots.d == nil: init(gLocalRoots)
    add(gLocalRoots, c, desc)

proc drainStripe(i: int) =
  ## Apply the pending RC operations of one stripe queue; freshly
  ## dead-looking cells become THIS thread's candidates. rc mutations are
  ## atomic, so no global lock is needed: a running collection observes
  ## them through its commit-time validation (rc recheck / dirty peek).
  ## The consumerLock excludes other drains; producers run free. Each
  ## queue is consumed the same way: process published entries, wait out
  ## the (two-instruction) publication window of in-flight reservers,
  ## then close the batch with a CAS — a plain reset could orphan a slot
  ## a producer is publishing into. Reservations past QueueSize never
  ## wrote anything, so an overflowed counter is hard-reset.
  withLock stripes[i].consumerLock:
    when useIncQueue:
      # apply pending incs FIRST: an inc entry means the rc word
      # under-counts, so its cell must be raised before decs can free
      var consumedInc = 0
      while true:
        let reserved = atomicLoadN(addr stripes[i].toIncLen, ATOMIC_ACQUIRE)
        let n = min(reserved, QueueSize)
        for j in consumedInc ..< n:
          var c = atomicLoadN(addr stripes[i].toInc[j], ATOMIC_ACQUIRE)
          while c == nil:
            c = atomicLoadN(addr stripes[i].toInc[j], ATOMIC_ACQUIRE)
          trialInc(c)
          atomicStoreN(addr stripes[i].toInc[j], cast[Cell](nil),
                       ATOMIC_RELAXED)
        consumedInc = n
        if reserved >= QueueSize:
          discard atomicExchangeN(addr stripes[i].toIncLen, 0, ATOMIC_ACQ_REL)
          break
        else:
          var cur = reserved
          if atomicCompareExchangeN(addr stripes[i].toIncLen, addr cur, 0,
                                     false, ATOMIC_ACQ_REL, ATOMIC_RELAXED):
            break
    var consumed = 0
    while true:
      let reserved = atomicLoadN(addr stripes[i].toDecLen, ATOMIC_ACQUIRE)
      let n = min(reserved, QueueSize)
      for j in consumed ..< n:
        var desc = atomicLoadN(addr stripes[i].toDec[j][1], ATOMIC_ACQUIRE)
        while desc == nil:
          desc = atomicLoadN(addr stripes[i].toDec[j][1], ATOMIC_ACQUIRE)
        let c = stripes[i].toDec[j][0]
        trialDec(c)
        registerLocal(c, desc)
        atomicStoreN(addr stripes[i].toDec[j][1], cast[PNimTypeV2](nil),
                     ATOMIC_RELAXED)
      consumed = n
      if reserved >= QueueSize:
        discard atomicExchangeN(addr stripes[i].toDecLen, 0, ATOMIC_ACQ_REL)
        break
      else:
        var cur = reserved
        if atomicCompareExchangeN(addr stripes[i].toDecLen, addr cur, 0, false,
                                   ATOMIC_ACQ_REL, ATOMIC_RELAXED):
          break
        # new reservations arrived during processing: consume them too

proc drainAllStripes() =
  ## Full-collect path: apply every pending RC operation; every resulting
  ## candidate is adopted by the calling thread.
  for i in 0..<NumStripes:
    drainStripe(i)

proc adoptOrphans() =
  ## Adopt candidates spilled by exited threads. The cells stay flagged;
  ## they merely change buffers, so the one-buffer invariant holds.
  if roots.len > 0:               # racy peek; exact under the lock
    acquire gMergeLock
    if gLocalRoots.d == nil: init(gLocalRoots)
    for i in 0 ..< roots.len:
      add(gLocalRoots, roots.d[i][0], roots.d[i][1])
    roots.len = 0
    release gMergeLock

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
  # read the slot exactly once: mutators may exchange it concurrently.
  # Aligned pointer loads do not tear on supported targets.
  let v = p[]
  if v != nil:
    var j = cast[ptr GcEnv](env)
    j.traceStack.add(TraceEntry(slot: p, val: v), desc)

proc nimTraceRefDyn(q: pointer; env: pointer) {.compilerRtl, inl.} =
  let p = cast[ptr pointer](q)
  let v = p[]
  if v != nil:
    var j = cast[ptr GcEnv](env)
    j.traceStack.add(TraceEntry(slot: p, val: v), cast[ptr PNimTypeV2](v)[])

# ---------------- phase 1: capture ----------------

proc prepareCapture() =
  if gCap.recs.d == nil:
    init gCap.recs
    init gCap.tstack
    init gCap.frames
    init gCap.edges
    init gCap.sccs
    init gCap.sccMembers
    init gCap.crossTgt
    init gCap.crossPend
    init gCap.prunedSrc
    init gCap.ages
  else:
    gCap.recs.len = 0
    gCap.tstack.len = 0
    gCap.frames.len = 0
    gCap.edges.len = 0
    gCap.sccs.len = 0
    gCap.sccMembers.len = 0
    gCap.crossPend.len = 0
    gCap.prunedSrc.len = 0
    gCap.ages.len = 0

# rc is captured without the flag bits: the collector itself toggles
# inRootsFlag between capture and commit, which must not look like a
# mutation to the commit-time rc validation.
proc claimCell(c: Cell; desc: PNimTypeV2; cap: ptr CaptureBufs;
               pruneLive: bool): int32 =
  ## Dense index if this collection owns `c` (claiming and registering it
  ## if it was unclaimed), -1 if another ACTIVE collection owns it, or
  ## -2 if `pruneLive` and the cell was proven live in the current epoch
  ## (treat as an opaque live external, don't descend).
  if gAmSolo:
    # no other collection is (or can start) capturing: plain stores.
    # This recovers the sequential capture speed of the single-collector
    # design whenever collections do not actually overlap.
    let old = c.rootIdx
    if (old shr 32) == gMyTag:
      return int32(old and 0xFFFFFFFF)
    if pruneLive and (old shr 32) == (gMyEpochStamp shr 32) and
        stampAge(old) >= YrcPromoteAge:
      return -2
    let idx = cap.recs.len
    c.rootIdx = (gMyTag shl 32) or int64(idx)
    when defined(nimOrcStats):
      bumpStat gStatCapTotal
      if old != 0: bumpStat gStatCapRepeat
    cap.recs.add CaptureRec(cell: c, desc: desc,
                             rcWord: loadRc(c) and not rcMask,
                             lowlink: int32(idx), sccOf: -1'i32)
    cap.ages.add int32(if isEpochStamp(old): min(stampAge(old), 1000) else: 0)
    cap.tstack.add int32(idx)
    return int32(idx)
  while true:
    var old = atomicLoadN(addr c.rootIdx, ATOMIC_ACQUIRE)
    if (old shr 32) == gMyTag:
      return int32(old and 0xFFFFFFFF)
    if pruneLive and (old shr 32) == (gMyEpochStamp shr 32) and
        stampAge(old) >= YrcPromoteAge:
      return -2
    if isActiveTag(old shr 32):
      return -1
    let idx = cap.recs.len
    if atomicCompareExchangeN(addr c.rootIdx, addr old,
                               (gMyTag shl 32) or int64(idx), false,
                               ATOMIC_ACQ_REL, ATOMIC_RELAXED):
      when defined(nimOrcStats):
        bumpStat gStatCapTotal
        if old != 0: bumpStat gStatCapRepeat
      cap.recs.add CaptureRec(cell: c, desc: desc,
                               rcWord: loadRc(c) and not rcMask,
                               lowlink: int32(idx), sccOf: -1'i32)
      cap.ages.add int32(if isEpochStamp(old): min(stampAge(old), 1000) else: 0)
      cap.tstack.add int32(idx)
      return int32(idx)

proc capture(s: Cell; desc: PNimTypeV2; j: var GcEnv; cap: ptr CaptureBufs) =
  ## Iterative Tarjan SCC over everything reachable from `s`. A frame's
  ## pending out-edges are the traceStack entries above frame.base; a child
  ## pushes and drains its own segment above ours, so when the child's frame
  ## pops, the stack is back at our segment and we resume popping our edges.
  if isStamped(s): return
  orcAssert(j.traceStack.len == 0, "capture: trace stack not empty")
  # roots never prune: a dec-witnessed suspicion overrides any epoch stamp
  let root = claimCell(s, desc, cap, pruneLive = false)
  if root < 0:
    return   # another active collection owns this candidate; it handles it
  trace(s, desc, j)
  cap.frames.add TarjanFrame(u: root, base: 0)
  while cap.frames.len > 0:
    let u = cap.frames.d[cap.frames.len -% 1].u
    let base = cap.frames.d[cap.frames.len -% 1].base
    if j.traceStack.len > base:
      let (entry, tdesc) = j.traceStack.pop()
      let t = head(entry.val)
      if isStamped(t):
        let v = denseIdx(t)
        cap.edges.add (int64(u) shl 32) or int64(v)
        if cap.recs.d[v].sccOf < 0 and v < cap.recs.d[u].lowlink:
          cap.recs.d[u].lowlink = v
      else:
        let childBase = j.traceStack.len
        let v = claimCell(t, tdesc, cap, pruneLive = true)
        if v == -1:
          # cross-collection edge: the owner sees our reference in the rc
          # word and classifies the target live; we re-register it as a
          # candidate before our commit so it is re-examined later
          cap.crossPend.add(t, tdesc)
        elif v == -2:
          # target proven live this epoch: opaque live external, no descent.
          # Taint u's SCC — its own "live" verdict may lean on the stamp.
          cap.prunedSrc.add u
          when defined(nimOrcStats):
            bumpStat gStatCapPruned
        else:
          cap.edges.add (int64(u) shl 32) or int64(v)
          trace(t, tdesc, j)
          cap.frames.add TarjanFrame(u: v, base: childBase)
    else:
      cap.frames.len = cap.frames.len -% 1
      if cap.frames.len > 0:
        let pu = cap.frames.d[cap.frames.len -% 1].u
        if cap.recs.d[u].lowlink < cap.recs.d[pu].lowlink:
          cap.recs.d[pu].lowlink = cap.recs.d[u].lowlink
      if cap.recs.d[u].lowlink == u:
        # u is the root of an SCC: pop the members off the Tarjan stack
        let memStart = int32(cap.sccMembers.len)
        var sum = 0
        while true:
          let w = cap.tstack.pop()
          cap.recs.d[w].sccOf = int32(j.nScc)
          cap.sccMembers.add w
          sum = sum +% (cap.recs.d[w].rcWord shr rcShift) +% 1
          if w == u: break
        cap.sccs.add SccRec(sumRefs: sum, memStart: memStart)
        inc j.nScc

# ---------------- phase 2: deadness, side arrays only ----------------

proc computeDeadness(j: var GcEnv; cap: ptr CaptureBufs) =
  let nScc = j.nScc
  # append the sentinel record ([nScc]); capture left internal/deadIn/flags
  # zero-initialized and memStart valid. crossOff is filled below as a prefix
  # sum, so the sentinel closes the last SCC's member and cross-edge slices.
  cap.sccs.add SccRec(memStart: int32(cap.sccMembers.len))
  # classify captured edges: internal to an SCC vs condensation cross edges
  var nCross = 0
  for i in 0 ..< cap.edges.len:
    let e = cap.edges.d[i]
    let su = cap.recs.d[int32(e shr 32)].sccOf
    let sv = cap.recs.d[int32(e and 0xFFFFFFFF'i64)].sccOf
    if su == sv:
      inc cap.sccs.d[su].internal
    else:
      inc cap.sccs.d[su].crossOff
      inc nCross
  var total = 0'i32
  for s in 0 ..< nScc:
    let c = cap.sccs.d[s].crossOff
    cap.sccs.d[s].crossOff = total
    cap.sccs.d[s].crossCursor = total
    total = total +% c
  cap.sccs.d[nScc].crossOff = total
  setLenUninit cap.crossTgt, nCross
  for i in 0 ..< cap.edges.len:
    let e = cap.edges.d[i]
    let su = cap.recs.d[int32(e shr 32)].sccOf
    let sv = cap.recs.d[int32(e and 0xFFFFFFFF'i64)].sccOf
    if su != sv:
      cap.crossTgt.d[cap.sccs.d[su].crossCursor] = sv
      inc cap.sccs.d[su].crossCursor
  # pruned out-edges taint the source SCC: pruning cannot cause a false
  # "dead" (an untraced target only ever ADDS unexplained external refs),
  # but a "live" verdict may lean on a stamp that went stale within the
  # epoch, so validate re-registers surviving pruned SCCs
  for i in 0 ..< cap.prunedSrc.len:
    let s = cap.recs.d[cap.prunedSrc.d[i]].sccOf
    cap.sccs.d[s].flags = cap.sccs.d[s].flags or flagPruned
  # cells that stay registered as roots (partial collection) count as
  # externally referenced: the roots buffer itself points at them
  for mi in 0 ..< cap.sccMembers.len:
    let m = cap.sccMembers.d[mi]
    if (loadRc(cap.recs.d[m].cell) and inRootsFlag) != 0:
      let s = cap.recs.d[m].sccOf
      cap.sccs.d[s].flags = cap.sccs.d[s].flags or flagForcedLive
  # deadness over the condensation. Tarjan emits sinks first, so higher SCC
  # ids are sources and every cross edge goes from a higher id to a lower
  # one: one reverse scan settles everything.
  for s in countdown(nScc - 1, 0):
    let ext = cap.sccs.d[s].sumRefs -% cap.sccs.d[s].internal -% cap.sccs.d[s].deadIn
    when logOrc:
      cfprintf(cstderr, "[scc %ld] members %ld sumRefs %ld internal %ld deadIn %ld ext %ld forced %ld\n",
        s, cap.sccs.d[s+1].memStart - cap.sccs.d[s].memStart, cap.sccs.d[s].sumRefs,
        cap.sccs.d[s].internal, cap.sccs.d[s].deadIn, ext, int(cap.sccs.d[s].flags))
    if (cap.sccs.d[s].flags and flagForcedLive) == 0 and ext == 0:
      cap.sccs.d[s].flags = cap.sccs.d[s].flags or flagDead
      inc j.nDeadScc
      for k in cap.sccs.d[s].crossOff ..< cap.sccs.d[s+1].crossOff:
        inc cap.sccs.d[cap.crossTgt.d[k]].deadIn
    else:
      # a live SCC keeps everything it points to alive
      for k in cap.sccs.d[s].crossOff ..< cap.sccs.d[s+1].crossOff:
        let t = cap.crossTgt.d[k]
        cap.sccs.d[t].flags = cap.sccs.d[t].flags or flagForcedLive

# ---------------- phase 3: validate & commit ----------------

proc markDirtyFromQueues(j: var GcEnv; cap: ptr CaptureBufs) =
  ## The SATB half of the design: any cell with an inc or dec enqueued since
  ## the last drain had its reference set changed during capture. Peek
  ## (don't drain!) the stripe queues and taint the affected SCCs; the
  ## entries stay queued and the next merge re-registers them as candidates.
  template taint(cp: Cell) =
    let c = cp
    if isStamped(c):
      let s = cap.recs.d[denseIdx(c)].sccOf
      cap.sccs.d[s].flags = cap.sccs.d[s].flags or flagDirty
  for i in 0..<NumStripes:
    when useIncQueue:
      # lock-free peek. This one is LOAD-BEARING (an inc entry means the
      # rc word under-counts a live reference), which is why the producer
      # publishes with an RMW: every completed barrier's entry is globally
      # visible here. A nil slot is a barrier mid-publication — at most one
      # per thread, and the chain of custody for how that thread OBTAINED
      # the reference is older, completed and therefore observable.
      let incLen = min(atomicLoadN(addr stripes[i].toIncLen, ATOMIC_ACQUIRE),
                       QueueSize)
      for k in 0..<incLen:
        let c = atomicLoadN(addr stripes[i].toInc[k], ATOMIC_ACQUIRE)
        if c != nil: taint c
    # lock-free peek: skip slots whose publish has not landed yet. Sound:
    # a pending deferred dec leaves the target's rc counting a ref whose
    # edge the capture no longer traverses — an unexplained +1 that forces
    # the target live no matter what (deletions only make the captured
    # graph look MORE alive). The taint here is belt and braces.
    let decLen = min(atomicLoadN(addr stripes[i].toDecLen, ATOMIC_ACQUIRE),
                     QueueSize)
    for k in 0..<decLen:
      if atomicLoadN(addr stripes[i].toDec[k][1], ATOMIC_ACQUIRE) != nil:
        taint stripes[i].toDec[k][0]

proc demoteTouchedDead(j: var GcEnv; cap: ptr CaptureBufs) =
  ## One descending demotion pass. Descending ids = the deadness scan's
  ## order (sources before sinks): a demotion must propagate to the SCC's
  ## dead cross targets, whose deadIn had explained the edges away only
  ## under the assumption that this SCC dies with them. The demoted SCC
  ## survives with its slots intact, so any target left dead would be
  ## freed under a surviving reference. Targets have lower ids, so
  ## tainting them here demotes them (transitively) later in this loop.
  for s in countdown(j.nScc - 1, 0):
    if (cap.sccs.d[s].flags and flagDead) != 0:
      var ok = (cap.sccs.d[s].flags and flagDirty) == 0
      if ok:
        for mi in cap.sccs.d[s].memStart ..< cap.sccs.d[s+1].memStart:
          let m = cap.sccMembers.d[mi]
          if (loadRc(cap.recs.d[m].cell) and not rcMask) != cap.recs.d[m].rcWord:
            ok = false
            break
      if not ok:
        cap.sccs.d[s].flags = cap.sccs.d[s].flags and not flagDead
        inc j.nAborted
        for k in cap.sccs.d[s].crossOff ..< cap.sccs.d[s+1].crossOff:
          let t = cap.crossTgt.d[k]
          if (cap.sccs.d[t].flags and flagDead) != 0:
            cap.sccs.d[t].flags = cap.sccs.d[t].flags or flagDirty
        let m = cap.sccMembers.d[cap.sccs.d[s].memStart]
        registerLocal(cap.recs.d[m].cell, cap.recs.d[m].desc)
    elif (cap.sccs.d[s].flags and flagPruned) != 0:
      # survives, but its liveness may rest on a stale epoch stamp: keep
      # one member registered so the verdict is retried (fully re-examined
      # once the epoch advances)
      let m = cap.sccMembers.d[cap.sccs.d[s].memStart]
      registerLocal(cap.recs.d[m].cell, cap.recs.d[m].desc)

proc validateDead(j: var GcEnv; cap: ptr CaptureBufs) =
  ## Demote every dead SCC that a mutator touched during capture: dirty via
  ## the queues, or a direct incRef visible as a changed rc word. Demoted
  ## SCCs become ordinary survivors (so committed neighbors decrement into
  ## them correctly) and one member is re-registered as a candidate root so
  ## the SCC is re-examined by the next collection.
  ##
  ## ONE peek before the rc rechecks suffices; there is no peek→commit
  ## TOCTOU. To enqueue an op on X a mutator must HOLD X, and its chain of
  ## custody regresses to evidence this validation already checks: a ref
  ## counted at capture (X was never classified dead), a direct incRef
  ## since capture (rc-word recheck, which runs AFTER the peek), or a
  ## buffered stack inc — still queued (this peek saw it) or drained
  ## (rc word changed before the recheck). New entries after the peek
  ## carry no new information about X's deadness. See "Why No Lost
  ## Objects" above and yrc_proof.lean §3–§4.
  markDirtyFromQueues(j, cap)
  demoteTouchedDead(j, cap)

proc commitDead(j: var GcEnv; cap: ptr CaptureBufs) =
  validateDead(j, cap)
  # publish cross-collection edge targets as candidate roots BEFORE any of
  # our commit decs could make them collectible: they are owner-live this
  # round, and the registration keeps them examinable in a later round
  for i in 0 ..< cap.crossPend.len:
    registerLocal(cap.crossPend.d[i][0], cap.crossPend.d[i][1])
  template deadCell(t: Cell): bool =
    isStamped(t) and (cap.sccs.d[cap.recs.d[denseIdx(t)].sccOf].flags and flagDead) != 0
  template graceWait() =
    # Grace period: another collection still in its CAPTURE phase may hold
    # stale (slot, value) snapshots referencing our dead cells; disposing
    # them now could hand reused memory to its traversal. Captures are
    # bounded and never wait on us. New captures cannot reach our dead
    # cells: they are unreachable, and our tag stays active until after
    # the frees.
    for s in 0 ..< ParSlots:
      if s != gMySlot:
        let tg = atomicLoadN(addr gActiveTags[s], ATOMIC_ACQUIRE)
        if tg != 0:
          parkUntil(atomicLoadN(addr gActiveTags[s], ATOMIC_ACQUIRE) != tg or
                    atomicLoadN(addr gSlotPhase[s], ATOMIC_ACQUIRE) != 1)
  # A dead cell's reference to another active collection's cell must still
  # be decremented (the target survives this round), so the all-dead fast
  # path additionally requires that no cross-collection edge was seen.
  # pruned edges also disable the fused path: its nil-without-dec would
  # leak rc on the stamped targets (and skip their re-registration)
  let allDead = j.nDeadScc == j.nScc and j.nAborted == 0 and
                cap.crossPend.len == 0 and cap.prunedSrc.len == 0
  if allDead:
    # Everything captured dies and no slot can point outside the dead set:
    # nil the slots and free in ONE pass over the cells — they went cold
    # since capture, a second sweep would miss cache all over again.
    # Freeing cell A before nil-ing a later cell B's slot that points at A
    # is fine: nobody reads B's slots in between (mutators cannot reach the
    # closed dead set, foreign captures never traverse our tagged cells,
    # and the grace wait has retired stale snapshots before the first free).
    graceWait()
    for m in 0 ..< cap.recs.len:
      let cell = cap.recs.d[m].cell
      let desc = cap.recs.d[m].desc
      orcAssert(j.traceStack.len == 0, "commitDead: trace stack not empty")
      trace(cell, desc, j)
      while j.traceStack.len > 0:
        let (entry, _) = j.traceStack.pop()
        entry.slot[] = nil
      when orcLeakDetector:
        writeCell("CYCLIC OBJECT FREED", cell, desc)
      free(cell, desc)
    j.freed = cap.recs.len
  else:
    init j.toFree
    for s in 0 ..< j.nScc:
      if (cap.sccs.d[s].flags and flagDead) != 0:
        for mi in cap.sccs.d[s].memStart ..< cap.sccs.d[s+1].memStart:
          let m = cap.sccMembers.d[mi]
          let cell = cap.recs.d[m].cell
          let desc = cap.recs.d[m].desc
          j.toFree.add(cell, desc)
          # nil every slot so the destructor cannot dec these edges again;
          # references to survivors are decremented for real, references into
          # the dead group die with the group (already accounted by deadIn).
          # The dead cells must all outlive this pass: deadCell reads the
          # TARGET's header, so no fusing with the free loop here.
          orcAssert(j.traceStack.len == 0, "commitDead: trace stack not empty")
          trace(cell, desc, j)
          while j.traceStack.len > 0:
            let (entry, tdesc) = j.traceStack.pop()
            let t = head(entry.val)
            entry.slot[] = nil
            if not deadCell(t):
              trialDec(t)
              # a stamped target was not analyzed by THIS collection, so
              # this dec may be the death blow: keep the cell examinable
              if isEpochStamp(atomicLoadN(addr t.rootIdx, ATOMIC_RELAXED)):
                registerLocal(t, tdesc)
    # epoch-stamp what this collection PROVED live, carrying the cell's
    # survival age: only cells that keep surviving get promoted to ages
    # where captures prune them, so die-young data is never deferred.
    # Demoted (dirty) and pruned SCCs stay unproven — leave their stale
    # tags claimable. Our tag is still active, so no foreign claim can
    # race these stores.
    for s in 0 ..< j.nScc:
      if (cap.sccs.d[s].flags and (flagDead or flagDirty or flagPruned)) == 0:
        for mi in cap.sccs.d[s].memStart ..< cap.sccs.d[s+1].memStart:
          let m = cap.sccMembers.d[mi]
          atomicStoreN(addr cap.recs.d[m].cell.rootIdx,
                       gMyEpochStamp or int64(cap.ages.d[m] +% 1),
                       ATOMIC_RELAXED)
    graceWait()
    for i in 0 ..< j.toFree.len:
      when orcLeakDetector:
        writeCell("CYCLIC OBJECT FREED", j.toFree.d[i][0], j.toFree.d[i][1])
      free(j.toFree.d[i][0], j.toFree.d[i][1])
    j.freed = j.toFree.len
    deinit j.toFree

proc startCollection(minRoots, keepBelow: int; slice: var CellSeq[Cell];
                     wait: bool; drainAll = false): bool =
  ## Drain pending RC operations (own stripe; all stripes for a full
  ## collect) and try to become a collector over THIS THREAD's candidates:
  ## claim a tag slot — the only step still under gMergeLock — and steal
  ## the thread-local buffer as this collection's slice, lock-free. When
  ## there is enough work but all ParSlots collections are running, `wait`
  ## decides between parking until a slot frees (backpressure for
  ## overflowing mutators) and giving up. Either way the drain happened,
  ## so the caller's overflowing queue has room again.
  result = false
  if drainAll: drainAllStripes()
  else: drainStripe(getStripeIdx())
  adoptOrphans()
  while gLocalRoots.len >= minRoots and gLocalRoots.len > keepBelow and
      mayRunCycleCollect():
    acquire gMergeLock
    var slot = -1
    for sl in 0 ..< ParSlots:
      if atomicLoadN(addr gActiveTags[sl], ATOMIC_RELAXED) == 0:
        slot = sl
        break
    if slot < 0:
      release gMergeLock
      if not wait: break
      # backpressure: all ParSlots collections are running; park until one
      # finishes (finishCollection broadcasts) instead of burning a core
      parkUntil(anySlotFree())
      drainStripe(getStripeIdx())   # the world moved while we waited
      adoptOrphans()
    else:
      gTagCounter = (gTagCounter +% 1) and int64(epochBase - 1)  # tags below the stamp namespace
      if gTagCounter == 0: gTagCounter = 1
      gMyTag = gTagCounter
      gMySlot = slot
      gMyEpochStamp = epochStamp(atomicLoadN(addr gEpoch, ATOMIC_RELAXED))
      var othersActive = false
      for sl in 0 ..< ParSlots:
        if sl != slot and atomicLoadN(addr gActiveTags[sl], ATOMIC_RELAXED) != 0:
          othersActive = true
      gAmSolo = not othersActive
      if gAmSolo:
        atomicStoreN(addr gSoloCapture, 1, ATOMIC_RELEASE)
      atomicStoreN(addr gSlotPhase[slot], 1, ATOMIC_RELEASE)
      atomicStoreN(addr gActiveTags[slot], gMyTag, ATOMIC_SEQ_CST)
      release gMergeLock
      # our buffer, our slice: no lock needed
      if keepBelow == 0:
        slice = gLocalRoots     # steal the whole buffer
        init(gLocalRoots)
      else:
        init(slice, max(gLocalRoots.len - keepBelow, 8))
        for i in keepBelow ..< gLocalRoots.len:
          slice.add(gLocalRoots.d[i][0], gLocalRoots.d[i][1])
        gLocalRoots.len = keepBelow
      result = true
      break

proc finishCollection() =
  if atomicAddFetch(addr gCollectionCounter, 1, ATOMIC_RELAXED) mod YrcEpochLen == 0:
    discard atomicAddFetch(addr gEpoch, 1, ATOMIC_RELAXED)
  atomicStoreN(addr gActiveTags[gMySlot], 0, ATOMIC_SEQ_CST)
  atomicStoreN(addr gSlotPhase[gMySlot], 0, ATOMIC_RELEASE)
  gMyTag = 0
  gAmSolo = false
  collectorEvent()   # wake backpressure and grace waiters

proc collectCyclesImpl(j: var GcEnv; slice: var CellSeq[Cell]) =
  # All destruction is deferred to collection time: plain rc==0 garbage in
  # the roots buffer forms singleton SCCs with external count 0 and is freed
  # by the same machinery as the cycles.
  let last = slice.len -% 1
  when logOrc:
    for i in countdown(last, 0):
      writeCell("root", slice.d[i][0], slice.d[i][1])

  init j.traceStack
  prepareCapture()
  let cap = addr gCap   # hoist the TLS lookup out of the hot loops
  j.nScc = 0

  for i in countdown(last, 0):
    capture(slice.d[i][0], slice.d[i][1], j, cap)
  j.touched = cap.recs.len
  atomicStoreN(addr gSlotPhase[gMySlot], 2, ATOMIC_RELEASE)  # capture done
  if gAmSolo:
    atomicStoreN(addr gSoloCapture, 0, ATOMIC_RELEASE)
  collectorEvent()   # wake solo-gate and grace waiters

  # Unregister the processed candidates before computing deadness: only
  # cells that STAY registered count as externally referenced by the roots
  # buffer. Doing this before freeing anything also ensures a nested
  # collectCycles() (triggered from a destructor) cannot access freed cells.
  for i in 0 ..< slice.len:
    rcClearFlag(slice.d[i][0], inRootsFlag)

  computeDeadness(j, cap)
  commitDead(j, cap)
  j.keepThreshold = j.freed == j.touched and j.touched > 0

  deinit j.traceStack

proc runCollection(j: var GcEnv; slice: var CellSeq[Cell]) =
  ## Runs one collection over the stolen slice, concurrently with mutators
  ## AND with up to ParSlots-1 other collections over disjoint partitions.
  yrcGcFenceEnter()      # freeze seq structure mutations, not ref writes
  if not gAmSolo:
    # a solo collection claims with plain stores; nobody else may claim
    # cells until its capture phase is over
    parkUntil(atomicLoadN(addr gSoloCapture, ATOMIC_ACQUIRE) == 0)
  let prev = lockState
  lockState = Collecting
  collectCyclesImpl(j, slice)
  lockState = prev
  yrcGcFenceExit()
  finishCollection()
  deinit slice

when defined(nimOrcStats):
  var freedCyclicObjects {.threadvar.}: int

proc collectCycles() =
  when logOrc:
    cfprintf(cstderr, "[collectCycles] begin\n")
  if lockState == Collecting or lockState == HasMutatorLock:
    # Cannot start a nested collection:
    #   Collecting — destructor-driven decs during free can fill the
    #     stripe; re-entering would corrupt collector state. Returning
    #     without draining used to livelock the enqueue spin.
    #   HasMutatorLock — becoming a collector would fence-wait on our
    #     own gSeqActive counter (self-deadlock).
    # Just make room in the overflowing queue; a later dec outside this
    # context triggers the actual collection.
    drainStripe(getStripeIdx())
    return
  var slice: CellSeq[Cell]
  if startCollection(rootsThreshold, 0, slice, wait = true):
    let nRoots = slice.len
    var j: GcEnv
    runCollection(j, slice)
    block:
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
      regFresh*, regRepeat*, regCross*, regSelf*: int
      capTotal*, capRepeat*, capPruned*: int
  proc GC_orcStats*(): OrcStats =
    # freedCyclicObjects is per-thread; the registration/capture counters
    # are process-global (instrumentation for the epoch-stamp decision)
    result = OrcStats(freedCyclicObjects: freedCyclicObjects,
      regFresh: atomicLoadN(addr gStatRegFresh, ATOMIC_RELAXED),
      regRepeat: atomicLoadN(addr gStatRegRepeat, ATOMIC_RELAXED),
      regCross: atomicLoadN(addr gStatRegCross, ATOMIC_RELAXED),
      regSelf: atomicLoadN(addr gStatRegSelf, ATOMIC_RELAXED),
      capTotal: atomicLoadN(addr gStatCapTotal, ATOMIC_RELAXED),
      capRepeat: atomicLoadN(addr gStatCapRepeat, ATOMIC_RELAXED),
      capPruned: atomicLoadN(addr gStatCapPruned, ATOMIC_RELAXED))

proc GC_runOrc* =
  if lockState == Collecting: return
  # an explicit collect must be exhaustive: age out every liveness stamp
  # so nothing is pruned
  discard atomicAddFetch(addr gEpoch, 1, ATOMIC_RELAXED)
  var slice: CellSeq[Cell]
  if startCollection(1, 0, slice, wait = true, drainAll = true):
    var j: GcEnv
    runCollection(j, slice)
  # note: aborted SCCs and cross-collection targets legitimately leave
  # re-registered roots behind; other RUNNING threads' local candidates
  # are theirs to collect (exiting threads spill to the orphan buffer)

proc GC_enableOrc*() =
  when not defined(nimStressOrc):
    rootsThreshold = 0

proc GC_disableOrc*() =
  when not defined(nimStressOrc):
    rootsThreshold = high(int)

proc GC_prepareOrc*(): int {.inline.} =
  drainAllStripes()
  adoptOrphans()
  result = gLocalRoots.len

proc GC_partialCollect*(limit: int) =
  if lockState == Collecting: return
  var slice: CellSeq[Cell]
  if startCollection(limit + 1, limit, slice, wait = true):
    var j: GcEnv
    runCollection(j, slice)

proc GC_fullCollect* =
  GC_runOrc()

proc nimYrcThreadTeardown() =
  ## Called when a thread exits (threadimpl): drain our stripe so nothing
  ## of ours is stranded in a queue no other thread hashes to, then spill
  ## our candidate buffer to the global orphan buffer, where the next
  ## collection on any thread adopts it.
  drainStripe(getStripeIdx())
  if gLocalRoots.len > 0:
    acquire gMergeLock
    if roots.d == nil: init(roots)
    for i in 0 ..< gLocalRoots.len:
      add(roots, gLocalRoots.d[i][0], gLocalRoots.d[i][1])
    release gMergeLock
  if gLocalRoots.d != nil:
    deinit(gLocalRoots)
    gLocalRoots.d = nil
    gLocalRoots.len = 0

proc GC_enableMarkAndSweep*() = GC_enableOrc()
proc GC_disableMarkAndSweep*() = GC_disableOrc()

const acyclicFlag = 1

when optimizedOrc:
  template markedAsCyclic(s: Cell; desc: PNimTypeV2): bool =
    (desc.flags and acyclicFlag) == 0 and (s.rc and maybeCycle) != 0
else:
  template markedAsCyclic(s: Cell; desc: PNimTypeV2): bool =
    (desc.flags and acyclicFlag) == 0

proc enqueueDec(cell: Cell; desc: PNimTypeV2) {.inline.} =
  ## LOCK-FREE producer for the deferred-dec queue: reserve a slot with a
  ## fetch-add, store the cell, then publish by storing the desc (release;
  ## desc != nil is the ready marker consumers wait for/skip). A reservation
  ## past QueueSize never writes anything — the reserver makes room by
  ## draining (collectCycles always at least drains our own stripe, even
  ## when nested in a collection or a seq critical section) and retries
  ## with a fresh reservation.
  let idx = getStripeIdx()
  while true:
    let slot = atomicFetchAdd(addr stripes[idx].toDecLen, 1, ATOMIC_ACQ_REL)
    if slot < QueueSize:
      stripes[idx].toDec[slot][0] = cell
      atomicStoreN(addr stripes[idx].toDec[slot][1], desc, ATOMIC_RELEASE)
      break
    collectCycles()

proc nimDecRefIsLastCyclicDyn(p: pointer): bool {.compilerRtl, inl.} =
  result = false
  if p != nil:
    enqueueDec(head(p), cast[ptr PNimTypeV2](p)[])

proc nimDecRefIsLastDyn(p: pointer): bool {.compilerRtl, inl.} =
  nimDecRefIsLastCyclicDyn(p)

proc nimDecRefIsLastCyclicStatic(p: pointer; desc: PNimTypeV2): bool {.compilerRtl, inl.} =
  result = false
  if p != nil:
    enqueueDec(head(p), desc)

proc unsureAsgnRef(dest: ptr pointer, src: pointer) {.inline.} =
  dest[] = src
  if src != nil: nimIncRefCyclic(src, true)

proc yrcDec(tmp: pointer; desc: PNimTypeV2) {.inline.} =
  if desc != nil:
    discard nimDecRefIsLastCyclicStatic(tmp, desc)
  else:
    discard nimDecRefIsLastCyclicDyn(tmp)

proc nimAsgnYrc(dest: ptr pointer; src: pointer; desc: PNimTypeV2) {.compilerRtl.} =
  ## YRC write barrier for ref copy assignment. LOCK-FREE: the deferred dec
  ## of the old value doubles as the snapshot-at-the-beginning log (the
  ## collector peeks the toDec queues at commit time), and the direct atomic
  ## incRef of the new value is exactly the rc mutation the collector's
  ## commit-time rc validation observes.
  if src != nil: increment head(src)
  when hasThreadSupport:
    let tmp = atomicExchangeN(dest, src, ATOMIC_ACQ_REL)
  else:
    let tmp = dest[]
    dest[] = src
  if tmp != nil: yrcDec(tmp, desc)

proc nimSinkYrc(dest: ptr pointer; src: pointer; desc: PNimTypeV2) {.compilerRtl.} =
  ## YRC write barrier for ref sink (move). No incRef on source.
  when hasThreadSupport:
    let tmp = atomicExchangeN(dest, src, ATOMIC_ACQ_REL)
  else:
    let tmp = dest[]
    dest[] = src
  if tmp != nil: yrcDec(tmp, desc)

proc nimMarkCyclic(p: pointer) {.compilerRtl, inl.} =
  when optimizedOrc:
    if p != nil:
      let h = head(p)
      h.rc = h.rc or maybeCycle

# Initialize locks at module load.
initLock(gMergeLock)
initLock(gWaitLock)
initCond(gWaitCond)
for i in 0..<NumStripes:
  initLock(stripes[i].consumerLock)

{.pop.}
