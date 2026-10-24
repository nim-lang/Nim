#
#
#           The Nim Compiler
#        (c) Copyright 2026 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Concurrency primitives for the parallel compiler — stage 0 of
## `doc/parallel_compiler.md`. Nothing in the compiler uses them yet; they are
## the vocabulary the later stages are written in, landed first so that the
## shape (and the platform support) is settled before any of sem moves.
##
## Like `icprof`, this module has **no compiler imports**, so any layer may use
## it — `ast`, which everything depends on, included — without creating a
## cycle. The plan says no external package is needed for this and none is
## used: `std/locks` and `std/atomics` are the whole dependency list.
##
## Everything has a single-threaded fallback for a `--threads:off` build (which
## is what `nimsuggest` and the `koch boot` bootstrap stage still are): the
## locks become no-ops and the atomics plain reads and writes. That is not a
## fiction — without threads there is exactly one worker by construction, so
## the no-op *is* the correct implementation, and it keeps the primitives
## usable from code that has to compile both ways.
##
## What is here and why:
##
## * `atomicIncl`/`atomicExcl` — the compiler's `TSymFlags`/`TTypeFlags` are
##   read-modify-written from several passes (§4.4 of the plan lists `sfUsed`,
##   `sfAddrTaken`, `tfHasAsgn`, `tfCheckedForDestructor`, `tfVarIsPtr`). Two
##   workers doing `incl` on the same word lose one of the updates, which for
##   `sfUsed` is a spurious hint and for `tfHasAsgn` is wrong code.
## * `RwLock` — §3's reader/writer scheme for the module-shared half of
##   `PContext`. Deliberately writer-preferring: writers are rare (the header
##   pass, and the handful of in-body writers of §4.5) and must not starve
##   behind a stream of readers.
## * `Latch` — the per-module countdown of §2.1: a module's `.s.bif`/`.t.bif`
##   are written when its last body finishes.
## * `TaskQueue` — the body-task queue of §2.2. It hands out the SMALLEST key
##   first, because §2.6 rule 1 ("tasks are dispatched and their outputs merged
##   in key order") is what makes the output scheduling-independent and the
##   §2.3 wait rule deadlock-free. A plain FIFO would satisfy neither.

const
  hasThreads* = compileOption("threads")
    ## Whether the primitives below are real. `compiler/nim.cfg` sets
    ## `threads:on`; a caller that must also work without it (nimsuggest) gets
    ## the degenerate single-worker implementations.

when hasThreads:
  import std / [locks, atomics]

# ---------------------------------------------------------------- flag sets --

template flagWord(s: typed): untyped =
  ## The unsigned integer type a `set` of this size is laid out as. Nim packs
  ## a set of at most 64 elements into one machine word, which is what makes a
  ## single fetch-or possible; anything wider would need a lock and none of the
  ## compiler's flag sets are.
  when sizeof(s) == 1: uint8
  elif sizeof(s) == 2: uint16
  elif sizeof(s) == 4: uint32
  elif sizeof(s) == 8: uint64
  else: {.error: "flag set wider than a machine word".}

proc atomicIncl*[T](s: var set[T]; flag: T) {.inline.} =
  ## `s.incl flag`, but as one read-modify-write so a concurrent `atomicIncl`
  ## of a *different* flag in the same word cannot be lost.
  ##
  ## The mask comes from casting the singleton set `{flag}` rather than from
  ## `1 shl ord(flag)`: Nim bases a set at `low(T)`, so the shift would be
  ## wrong for any enum that does not start at zero, and the cast is right by
  ## construction for every one.
  when hasThreads:
    type W = flagWord(s)
    var one {.noinit.}: set[T]
    one = {flag}
    discard cast[ptr Atomic[W]](addr s)[].fetchOr(cast[W](one), moAcquireRelease)
  else:
    s.incl flag

proc atomicExcl*[T](s: var set[T]; flag: T) {.inline.} =
  ## `s.excl flag` as one read-modify-write; see `atomicIncl`.
  when hasThreads:
    type W = flagWord(s)
    var one {.noinit.}: set[T]
    one = {flag}
    discard cast[ptr Atomic[W]](addr s)[].fetchAnd(not cast[W](one), moAcquireRelease)
  else:
    s.excl flag

proc atomicIncl*[T](s: var set[T]; flags: set[T]) {.inline.} =
  ## The set-valued `incl`. A `set` already *is* the mask, so this is the same
  ## single fetch-or as the one-flag version, not a loop over it.
  when hasThreads:
    type W = flagWord(s)
    discard cast[ptr Atomic[W]](addr s)[].fetchOr(cast[W](flags), moAcquireRelease)
  else:
    s.incl flags

proc atomicExcl*[T](s: var set[T]; flags: set[T]) {.inline.} =
  ## The set-valued `excl`; see `atomicIncl`.
  when hasThreads:
    type W = flagWord(s)
    discard cast[ptr Atomic[W]](addr s)[].fetchAnd(not cast[W](flags), moAcquireRelease)
  else:
    s.excl flags

proc atomicRead*[T](s: var set[T]): set[T] {.inline.} =
  ## A torn-free read of a flag set that another thread may be `atomicIncl`ing.
  when hasThreads:
    type W = flagWord(s)
    let w = cast[ptr Atomic[W]](addr s)[].load(moAcquire)
    result = cast[set[T]](w)
  else:
    result = s

# ----------------------------------------------------------------- RwLock ----

type
  RwLock* = object
    ## Many readers or one writer. Writer-preferring: once a writer is
    ## waiting, new readers queue behind it.
    ##
    ## There is deliberately no upgrade operation. §3 of the plan requires a
    ## body that must write to drop its read lock, take the write lock and look
    ## again — the shared tables are append-only during the body pass, so
    ## "look again" is a cheap and correct re-validation, whereas an upgrade
    ## would be a second place a wait-for cycle could form.
    when hasThreads:
      L: Lock
      canRead, canWrite: Cond
      readers: int
      waitingWriters: int
      writing: bool

proc initRwLock*(rw: var RwLock) =
  when hasThreads:
    initLock rw.L
    initCond rw.canRead
    initCond rw.canWrite
    rw.readers = 0
    rw.waitingWriters = 0
    rw.writing = false

proc deinitRwLock*(rw: var RwLock) =
  when hasThreads:
    deinitCond rw.canRead
    deinitCond rw.canWrite
    deinitLock rw.L

proc acquireRead*(rw: var RwLock) =
  when hasThreads:
    acquire rw.L
    while rw.writing or rw.waitingWriters > 0:
      wait(rw.canRead, rw.L)
    inc rw.readers
    release rw.L

proc releaseRead*(rw: var RwLock) =
  when hasThreads:
    acquire rw.L
    dec rw.readers
    if rw.readers == 0 and rw.waitingWriters > 0:
      signal rw.canWrite
    release rw.L

proc acquireWrite*(rw: var RwLock) =
  when hasThreads:
    acquire rw.L
    inc rw.waitingWriters
    while rw.writing or rw.readers > 0:
      wait(rw.canWrite, rw.L)
    dec rw.waitingWriters
    rw.writing = true
    release rw.L

proc releaseWrite*(rw: var RwLock) =
  when hasThreads:
    acquire rw.L
    rw.writing = false
    if rw.waitingWriters > 0:
      signal rw.canWrite
    else:
      broadcast rw.canRead
    release rw.L

template withReadLock*(rw: var RwLock; body: untyped) =
  acquireRead rw
  try:
    body
  finally:
    releaseRead rw

template withWriteLock*(rw: var RwLock; body: untyped) =
  acquireWrite rw
  try:
    body
  finally:
    releaseWrite rw

# ------------------------------------------------------------------ Latch ----

type
  Latch* = object
    ## A countdown that one thread waits on and many count down: the
    ## per-module "all bodies finished" signal of §2.1, after which the
    ## module's IC artifacts may be written.
    ##
    ## `arm` is separate from `initLatch` because a module's body count is not
    ## known until its header pass ends, while the latch itself has to exist
    ## from the moment the first task can be enqueued.
    count: int
    when hasThreads:
      L: Lock
      cv: Cond

proc initLatch*(l: var Latch; count = 0) =
  when hasThreads:
    initLock l.L
    initCond l.cv
  l.count = count

proc deinitLatch*(l: var Latch) =
  when hasThreads:
    deinitCond l.cv
    deinitLock l.L

proc arm*(l: var Latch; n: int) =
  ## Adds `n` to what is outstanding. Called as tasks are enqueued.
  when hasThreads:
    acquire l.L
    inc l.count, n
    release l.L
  else:
    inc l.count, n

proc countDown*(l: var Latch) =
  when hasThreads:
    acquire l.L
    dec l.count
    if l.count <= 0: broadcast l.cv
    release l.L
  else:
    dec l.count

proc wait*(l: var Latch) =
  ## Blocks until the count reaches zero. With one worker the count is already
  ## zero by the time anyone waits — the tasks ran inline — so this is a
  ## no-op, which is exactly the stage-1 behaviour.
  when hasThreads:
    acquire l.L
    while l.count > 0:
      wait(l.cv, l.L)
    release l.L

proc outstanding*(l: Latch): int {.inline.} = l.count

# -------------------------------------------------------------- TaskQueue ----

type
  QueuedTask[T] = object
    key: uint64
    item: T

  TaskQueue*[T] = object
    ## A min-heap on the unit key, not a FIFO: `pop` always yields the
    ## smallest key currently queued (§2.6 rule 1). Keys are unique by
    ## construction (§2.3), so the order is total and a run's dispatch order
    ## is a function of what was enqueued, never of who got there first.
    heap: seq[QueuedTask[T]]
    closed: bool
    when hasThreads:
      L: Lock
      cv: Cond
      idle: int

proc initTaskQueue*[T](q: var TaskQueue[T]) =
  when hasThreads:
    initLock q.L
    initCond q.cv
    q.idle = 0
  q.heap = @[]
  q.closed = false

proc deinitTaskQueue*[T](q: var TaskQueue[T]) =
  when hasThreads:
    deinitCond q.cv
    deinitLock q.L

proc siftUp[T](h: var seq[QueuedTask[T]]; start: int) =
  var i = start
  while i > 0:
    let parent = (i - 1) div 2
    if h[i].key >= h[parent].key: break
    swap h[i], h[parent]
    i = parent

proc siftDown[T](h: var seq[QueuedTask[T]]) =
  var i = 0
  while true:
    let l = 2*i + 1
    if l >= h.len: break
    var m = l
    let r = l + 1
    if r < h.len and h[r].key < h[l].key: m = r
    if h[i].key <= h[m].key: break
    swap h[i], h[m]
    i = m

proc pushImpl[T](q: var TaskQueue[T]; key: uint64; item: sink T) =
  q.heap.add QueuedTask[T](key: key, item: item)
  siftUp(q.heap, q.heap.high)

proc popImpl[T](q: var TaskQueue[T]; dest: var T): bool =
  if q.heap.len == 0: return false
  dest = move q.heap[0].item
  q.heap[0] = move q.heap[q.heap.high]
  q.heap.setLen q.heap.high
  siftDown(q.heap)
  result = true

proc push*[T](q: var TaskQueue[T]; key: uint64; item: sink T) =
  ## Enqueues a unit. `key` is the canonical unit key of §2.3.
  when hasThreads:
    acquire q.L
    pushImpl(q, key, item)
    signal q.cv
    release q.L
  else:
    pushImpl(q, key, item)

proc tryPop*[T](q: var TaskQueue[T]; dest: var T): bool =
  ## Takes the smallest-key task if one is queued; never blocks.
  when hasThreads:
    acquire q.L
    result = popImpl(q, dest)
    release q.L
  else:
    result = popImpl(q, dest)

proc pop*[T](q: var TaskQueue[T]; dest: var T): bool =
  ## Takes the smallest-key task, blocking while the queue is empty and open.
  ## Returns `false` only once the queue is closed and drained, which is how a
  ## worker learns to exit.
  when hasThreads:
    acquire q.L
    while q.heap.len == 0 and not q.closed:
      inc q.idle
      wait(q.cv, q.L)
      dec q.idle
    result = popImpl(q, dest)
    release q.L
  else:
    result = popImpl(q, dest)

proc close*[T](q: var TaskQueue[T]) =
  ## No more tasks will be pushed; wakes every worker so the ones with nothing
  ## left to do can exit.
  when hasThreads:
    acquire q.L
    q.closed = true
    broadcast q.cv
    release q.L
  else:
    q.closed = true

proc len*[T](q: var TaskQueue[T]): int =
  when hasThreads:
    acquire q.L
    result = q.heap.len
    release q.L
  else:
    result = q.heap.len

# ----------------------------------------------------------- the sem lock --

when defined(nimParallelSem) and hasThreads:
  import std/[rlocks, sysatomics]

  var
    parallelSemActive*: bool
      ## set while a module's body pass runs on several threads; outside of it
      ## `withSemLock` costs nothing
    semLock: RLock
    semLockDepth {.threadvar.}: int
      ## how often THIS thread holds `semLock`, for `releaseSemLockFully`

  initRLock(semLock)

  when defined(nimSemLockStats):
    # `-d:nimSemLockStats`: per call site of `withSemLock`, how often the lock
    # was taken from the outside, how often a thread had to wait for it, and
    # the time spent waiting and holding it; `semLockReport` prints them
    import std/[monotimes, tables, algorithm, strutils, exitprocs]
    type SiteStats = object
      taken, contended: int
      waitNs, holdNs: int64
    var
      statsLock: Lock
      siteStats: Table[string, SiteStats]
    initLock(statsLock)

    proc nowNs*(): int64 = getMonoTime().ticks

    proc recordSite*(site: string; contended: bool; waitNs, holdNs: int64) =
      {.cast(gcsafe).}:
        locks.acquire statsLock
        let st = addr siteStats.mgetOrPut(site, SiteStats())
        inc st.taken
        if contended: inc st.contended
        st.waitNs += waitNs
        st.holdNs += holdNs
        locks.release statsLock

    proc semLockReport*() =
      {.cast(gcsafe).}:
        var rows: seq[(string, SiteStats)] = @[]
        for k, v in siteStats: rows.add (k, v)
        rows.sort(proc (a, b: (string, SiteStats)): int = cmp(b[1].waitNs + b[1].holdNs, a[1].waitNs + a[1].holdNs))
        echo "sem lock: site, taken, contended, wait ms, hold ms"
        for r in rows[0 ..< min(rows.len, 30)]:
          echo "  ", r[0], " ", r[1].taken, " ", r[1].contended, " ",
            formatFloat(r[1].waitNs.float / 1e6, ffDecimal, 1), " ",
            formatFloat(r[1].holdNs.float / 1e6, ffDecimal, 1)

    addExitProc(semLockReport)

  template withSemLock*(body: untyped) =
    ## Prototype of the parallel body pass (doc/parallel_compiler.md §3): ONE
    ## recursive lock around every operation on state the threads share --
    ## identifiers, the instance and hook caches, the VM, messages. Coarse on
    ## purpose: a single lock cannot deadlock on lock order, and the numbers
    ## will show which parts to split off first.
    if parallelSemActive:
      when defined(nimSemLockStats):
        let outermost = semLockDepth == 0
        let t0 = nowNs()
        let contended = not rlocks.tryAcquire(semLock)
        if contended: rlocks.acquire(semLock)
        let t1 = nowNs()
      else:
        rlocks.acquire(semLock)
      inc semLockDepth
      try:
        body
      finally:
        dec semLockDepth
        when defined(nimSemLockStats):
          if outermost:
            const site = instantiationInfo(-1)
            recordSite(site.filename & ":" & $site.line, contended,
                       t1 - t0, nowNs() - t1)
        rlocks.release(semLock)
    else:
      body

  type SpinRw* = object
    ## readers/writer spin lock for read-mostly tables whose critical sections
    ## are a lookup: `state` is the number of readers, -1 while written
    state: int

  proc acquireRead*(rw: var SpinRw) {.inline.} =
    while true:
      let s = atomicLoadN(addr rw.state, ATOMIC_RELAXED)
      if s >= 0 and atomicCompareExchangeN(addr rw.state, unsafeAddr s, s + 1,
                                           false, ATOMIC_ACQUIRE, ATOMIC_RELAXED):
        break
      cpuRelax()

  proc releaseRead*(rw: var SpinRw) {.inline.} =
    discard atomicFetchSub(addr rw.state, 1, ATOMIC_RELEASE)

  proc acquireWrite*(rw: var SpinRw) {.inline.} =
    var zero = 0
    while not atomicCompareExchangeN(addr rw.state, addr zero, -1,
                                     false, ATOMIC_ACQUIRE, ATOMIC_RELAXED):
      zero = 0
      cpuRelax()

  proc releaseWrite*(rw: var SpinRw) {.inline.} =
    atomicStoreN(addr rw.state, 0, ATOMIC_RELEASE)

  var attachedOpsRw: SpinRw
    ## `ModuleGraph.attachedOps`: looked up without the sem lock

  template withOpsRead*(body: untyped) =
    ## a lookup in `ModuleGraph.attachedOps`
    if parallelSemActive:
      acquireRead(attachedOpsRw)
      try: body
      finally: releaseRead(attachedOpsRw)
    else:
      body

  template withOpsWrite*(body: untyped) =
    ## a change of `ModuleGraph.attachedOps`
    if parallelSemActive:
      acquireWrite(attachedOpsRw)
      try: body
      finally: releaseWrite(attachedOpsRw)
    else:
      body

  type SemLockGuard* = object
    ## `let semGuard = lockSem()`: the sem lock until the end of the scope,
    ## without indenting the scope (the routines that are one critical
    ## section from their first statement to their last)
    held: bool
    when defined(nimSemLockStats):
      site: string
      contended: bool
      t0, t1: int64

  proc `=destroy`*(g: SemLockGuard) =
    if g.held:
      {.cast(gcsafe).}:
        dec semLockDepth
        when defined(nimSemLockStats):
          if semLockDepth == 0:
            recordSite(g.site, g.contended, g.t1 - g.t0, nowNs() - g.t1)
        rlocks.release(semLock)

  proc `=copy`*(a: var SemLockGuard; b: SemLockGuard) {.error.}

  template lockSem*(): SemLockGuard =
    var g = SemLockGuard()
    if parallelSemActive:
      when defined(nimSemLockStats):
        const site = instantiationInfo(-1)
        g.site = site.filename & ":" & $site.line
        g.t0 = nowNs()
        g.contended = not rlocks.tryAcquire(semLock)
        if g.contended: rlocks.acquire(semLock)
        g.t1 = nowNs()
      else:
        rlocks.acquire(semLock)
      inc semLockDepth
      g.held = true
    g

  template withoutSemLock*(body: untyped) =
    ## `body` without the sem lock, if this thread holds it exactly once --
    ## nested inside another critical section it stays held, that one may
    ## rely on it
    if parallelSemActive and semLockDepth == 1:
      dec semLockDepth
      rlocks.release(semLock)
      try:
        body
      finally:
        rlocks.acquire(semLock)
        inc semLockDepth
    else:
      body

  proc releaseSemLockFully*(): int =
    ## before waiting for another thread: give the lock up entirely, or the
    ## thread waited for may block on it. Returns the depth to restore.
    result = semLockDepth
    for i in 0 ..< result: rlocks.release(semLock)
    semLockDepth = 0

  proc reacquireSemLock*(depth: int) =
    for i in 0 ..< depth: rlocks.acquire(semLock)
    semLockDepth = depth
else:
  template withSemLock*(body: untyped) = body
  template withoutSemLock*(body: untyped) = body
  template withOpsRead*(body: untyped) = body
  template withOpsWrite*(body: untyped) = body
  type SemLockGuard* = object
  template lockSem*(): SemLockGuard = SemLockGuard()
when not (defined(nimParallelSem) and hasThreads and defined(nimSemLockStats)):
  proc semLockReport*() = discard
