#
#
#            Nim's Runtime Library
#        (c) Copyright 2026 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Virtual-thread worker pool.
##
## Included from `std/typedthreads`.
##
## Workers never exit. createThread pops one off the idle stack (or
## pthread_create / CreateThread a new one when the stack is empty), hands
## it a task via a per-worker BinSem, and the worker runs it, pushes itself
## back onto the idle stack, and posts the requesting virtual thread's
## `done` flag. joinThread waits on that flag — `pthread_join` is not used.

{.push stackTrace: off.}

const
  PoolWorkerStackMask = 1024 * 256 * sizeof(int) - 1
  PoolWorkerStackSize* = PoolWorkerStackMask + 1 - 4096
    ## Matches typedthreads' default ThreadStackSize for non-embedded targets.

type
  TaskEntry* = proc (closure: pointer) {.nimcall, gcsafe, raises: [].}
    ## Worker-side entry: static function pointer plus opaque closure.
    ## typedthreads' adapter builds the closure from `TArg`.

  Worker* = object
    osThread: SysThread
    wake: BinSem
    # Per-worker TLS-emulation storage. With virtual threads on this worker
    # all `var x {.threadvar.}` resolve to fields in `gcThread.tls` — so the
    # storage persists across V's on the same worker. This is what makes
    # `var allocator {.threadvar.}: MemRegion` keep its chunks across
    # createThread/joinThread cycles.
    gcThread: GcThread
    # Task slot. Written by `poolDispatch` while the worker is parked on
    # `wake`; read by `workerMain` once it wakes.
    entry: TaskEntry
    closure: pointer
    base: ptr ThreadBase
    next: ptr Worker

# ---------------- idle stack ----------------

var
  poolLock: SysLock
  idleTop: ptr Worker

initSysLock(poolLock)

proc pushIdle(w: ptr Worker) =
  acquireSys(poolLock)
  w.next = idleTop
  idleTop = w
  releaseSys(poolLock)

proc popIdle(): ptr Worker =
  acquireSys(poolLock)
  result = idleTop
  if result != nil:
    idleTop = result.next
    result.next = nil
  releaseSys(poolLock)

# ---------------- worker main ----------------

proc workerMain(arg: pointer) {.nimcall, gcsafe, raises: [].} =
  let w = cast[ptr Worker](arg)

  # One-shot per-worker setup. The stack-bottom mark is a frame in
  # workerMain — every task call frame sits at a higher (deeper) address,
  # so the bottom we register here remains valid for the worker's whole
  # process-lifetime. Emulated-TLS bootstrap (`globalsSlot`) is done
  # earlier, inside the C-callable thunk, since any Nim-convention proc
  # call may touch threadvars in its prologue.
  when not defined(boehmgc) and not defined(gogc) and not defined(gcRegions) and
       not defined(gcDestructors) and not defined(gcHooks):
    # Mirrors `usesDestructors` in system.nim (not exported, so duplicated).
    var stackMark {.volatile.}: pointer
    nimGC_setStackBottom(addr(stackMark))
  when declared(initGC):
    initGC()
  when declared(threadType):
    threadType = ThreadType.NimThread

  while true:
    waitBinSem(w.wake)
    # Snapshot the task slot locally before pushing back to idle, since the
    # slot can be overwritten as soon as another caller pops this worker.
    let entry = w.entry
    let closure = w.closure
    let base = w.base
    try:
      entry(closure)
    except CatchableError:
      discard
    # Per-V destruction handlers fire here and the seq is cleared so V+1
    # starts with a fresh handler list (decision 1).
    when declared(nimThreadDestructionHandlers):
      for i in countdown(nimThreadDestructionHandlers.len-1, 0):
        try: nimThreadDestructionHandlers[i]()
        except CatchableError: discard
      nimThreadDestructionHandlers.setLen 0
    # `pushIdle` BEFORE `postBinSem(done)` so a join-then-redispatch can land
    # on the same worker. Reversing order is correctness-preserving but
    # silently degrades reuse.
    pushIdle(w)
    postBinSem(base.done)

# ---------------- platform-specific spawn ----------------

when defined(windows):
  proc workerThunkWin(arg: pointer): int32 {.stdcall.} =
    # Bind the emulated-TLS slot to this worker's GcThread BEFORE any
    # nimcall proc runs — `workerMain` (and anything it calls) may touch
    # threadvars in its function prologue, which under emulated TLS would
    # deref a nil slot if globalsSlot hadn't been set for this OS thread.
    when declared(globalsSlot):
      let w = cast[ptr Worker](arg)
      threadVarSetValue(globalsSlot, addr(w.gcThread))
    workerMain(arg)
    result = 0'i32

  proc spawnOsWorker(w: ptr Worker) =
    var dummy: int32 = 0'i32
    let h = createThread(nil, PoolWorkerStackSize.int32, workerThunkWin,
                         cast[pointer](w), 0'i32, dummy)
    if h <= 0:
      raise newException(ResourceExhaustedError, "cannot create pool worker")
    w.osThread = h

elif defined(genode):
  # Genode keeps the legacy 1:1 model until its C++-side runtime adapts.
  proc spawnOsWorker(w: ptr Worker) =
    raise newException(ResourceExhaustedError,
                       "virtual-thread pool not implemented for Genode")

else:
  proc workerThunkPosix(arg: pointer): pointer {.noconv.} =
    # Bind the emulated-TLS slot to this worker's GcThread BEFORE any
    # nimcall proc runs — see workerThunkWin for the rationale.
    when declared(globalsSlot):
      let w = cast[ptr Worker](arg)
      threadVarSetValue(globalsSlot, addr(w.gcThread))
    workerMain(arg)
    result = nil

  proc spawnOsWorker(w: ptr Worker) =
    var attr: Pthread_attr
    discard pthread_attr_init(attr)
    discard pthread_attr_setstacksize(attr, PoolWorkerStackSize)
    if pthread_create(w.osThread, attr, workerThunkPosix, cast[pointer](w)) != 0:
      raise newException(ResourceExhaustedError, "cannot create pool worker")
    discard pthread_attr_destroy(attr)

proc spawnWorker(): ptr Worker =
  result = cast[ptr Worker](c_malloc(csize_t sizeof(Worker)))
  zeroMem(result, sizeof(Worker))
  initBinSem(result.wake)
  spawnOsWorker(result)

proc workerOsThread*(w: ptr Worker): SysThread {.inline.} =
  ## Read accessor for `Thread[TArg].sys` plumbing.
  w.osThread

# ---------------- public API ----------------

proc poolDispatch*(base: ptr ThreadBase; entry: TaskEntry; closure: pointer) =
  ## Hand `entry(closure)` to a worker. Demand-grown: pops the idle stack
  ## first, only spawns a fresh OS thread when the stack is empty.
  resetBinSem(base.done)
  var w = popIdle()
  if w == nil:
    w = spawnWorker()
  w.entry = entry
  w.closure = closure
  w.base = base
  base.worker = cast[pointer](w)
  postBinSem(w.wake)

proc poolWaitDone*(base: ptr ThreadBase) =
  ## Block until the most recent `poolDispatch` on `base` completes.
  waitBinSem(base.done)

{.pop.}
