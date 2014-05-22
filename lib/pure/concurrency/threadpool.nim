#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2014 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Implements Nimrod's 'spawn'.

import cpuinfo, cpuload, locks

{.push stackTrace:off.}

type
  CondVar = object
    c: TCond
    L: TLock
    counter: int

proc createCondVar(): CondVar =
  initCond(result.c)
  initLock(result.L)

proc destroyCondVar(cv: var CondVar) {.inline.} =
  deinitCond(cv.c)
  deinitLock(cv.L)

proc await(cv: var CondVar) =
  acquire(cv.L)
  while cv.counter <= 0:
    wait(cv.c, cv.L)
  dec cv.counter
  release(cv.L)

proc signal(cv: var CondVar) =
  acquire(cv.L)
  inc cv.counter
  release(cv.L)
  signal(cv.c)

type
  Barrier* {.compilerProc.} = object
    counter: int
    cv: CondVar

proc barrierEnter*(b: ptr Barrier) {.compilerProc.} =
  atomicInc b.counter

proc barrierLeave*(b: ptr Barrier) {.compilerProc.} =
  atomicDec b.counter
  if b.counter <= 0: signal(b.cv)

proc openBarrier*(b: ptr Barrier) {.compilerProc.} =
  b.counter = 0
  b.cv = createCondVar()

proc closeBarrier*(b: ptr Barrier) {.compilerProc.} =
  await(b.cv)
  destroyCondVar(b.cv)

{.pop.}

# ----------------------------------------------------------------------------

type
  AwaitInfo = object
    cv: CondVar
    idx: int

  RawFuture* = ptr RawFutureObj ## untyped base class for 'Future[T]'
  RawFutureObj {.inheritable.} = object # \
    # we allocate this with the thread local allocator; this
    # is possible since we already need to do the GC_unref
    # on the owning thread
    ready, usesCondVar: bool
    cv: CondVar #\
    # for 'awaitAny' support
    ai: ptr AwaitInfo
    idx: int
    data: PObject  # we incRef and unref it to keep it alive
    owner: ptr Worker
    next: RawFuture
    align: float64 # a float for proper alignment

  Future* {.compilerProc.} [T] = ptr object of RawFutureObj
    blob: T  ## the underlying value, if available. Note that usually
             ## you should not access this field directly! However it can
             ## sometimes be more efficient than getting the value via ``^``.

  WorkerProc = proc (thread, args: pointer) {.nimcall, gcsafe.}
  Worker = object
    taskArrived: CondVar
    taskStarted: CondVar #\
    # task data:
    f: WorkerProc
    data: pointer
    ready: bool # put it here for correct alignment!
    initialized: bool # whether it has even been initialized
    shutdown: bool # the pool requests to shut down this worker thread
    futureLock: TLock
    head: RawFuture

proc finished*(fut: RawFuture) =
  ## This MUST be called for every created future to free its associated
  ## resources. Note that the default reading operation ``^`` is destructive
  ## and calls ``finished``.
  doAssert fut.ai.isNil, "future is still attached to an 'awaitAny'"
  assert fut.next == nil
  let w = fut.owner
  acquire(w.futureLock)
  fut.next = w.head
  w.head = fut
  release(w.futureLock)

proc cleanFutures(w: ptr Worker) =
  var it = w.head
  acquire(w.futureLock)
  while it != nil:
    let nxt = it.next
    if it.usesCondVar: destroyCondVar(it.cv)
    if it.data != nil: GC_unref(it.data)
    dealloc(it)
    it = nxt
  w.head = nil
  release(w.futureLock)

proc nimCreateFuture(owner: pointer; blobSize: int): RawFuture {.
                     compilerProc.} =
  result = cast[RawFuture](alloc0(RawFutureObj.sizeof + blobSize))
  result.owner = cast[ptr Worker](owner)

proc nimFutureCreateCondVar(fut: RawFuture) {.compilerProc.} =
  fut.cv = createCondVar()
  fut.usesCondVar = true

proc nimFutureSignal(fut: RawFuture) {.compilerProc.} =
  assert fut.usesCondVar
  signal(fut.cv)

proc await*[T](fut: Future[T]) =
  ## waits until the value for the future arrives.
  if fut.usesCondVar: await(fut.cv)

proc `^`*[T](fut: Future[T]): T =
  ## blocks until the value is available and then returns this value. Note
  ## this reading is destructive for reasons of efficiency and convenience.
  ## This calls ``finished(fut)``.
  await(fut)
  when T is string or T is seq or T is ref:
    result = cast[T](fut.data)
  else:
    result = fut.payload
  finished(fut)

proc notify*(fut: RawFuture) {.compilerproc.} =
  if fut.ai != nil:
    acquire(fut.ai.cv.L)
    fut.ai.idx = fut.idx
    inc fut.ai.cv.counter
    release(fut.ai.cv.L)
    signal(fut.ai.cv.c)
  if fut.usesCondVar: signal(fut.cv)

proc awaitAny*(futures: openArray[RawFuture]): int =
  # awaits any of the given futures. Returns the index of one future for which
  ## a value arrived. A future only supports one call to 'awaitAny' at the
  ## same time. That means if you await([a,b]) and await([b,c]) the second
  ## call will only await 'c'. If there is no future left to be able to wait
  ## on, -1 is returned.
  var ai: AwaitInfo
  ai.cv = createCondVar()
  var conflicts = 0
  for i in 0 .. futures.high:
    if cas(addr futures[i].ai, nil, addr ai):
      futures[i].idx = i
    else:
      inc conflicts
  if conflicts < futures.len:
    await(ai.cv)
    result = ai.idx
    for i in 0 .. futures.high:
      discard cas(addr futures[i].ai, addr ai, nil)
  else:
    result = -1
  destroyCondVar(ai.cv)

proc nimArgsPassingDone(p: pointer) {.compilerProc.} =
  let w = cast[ptr Worker](p)
  signal(w.taskStarted)

const
  MaxThreadPoolSize* = 256 ## maximal size of the thread pool. 256 threads
                           ## should be good enough for anybody ;-)

var
  currentPoolSize: int
  maxPoolSize = MaxThreadPoolSize
  minPoolSize = 4
  gSomeReady = createCondVar()
  readyWorker: ptr Worker

proc slave(w: ptr Worker) {.thread.} =
  while true:
    w.ready = true
    readyWorker = w
    signal(gSomeReady)
    await(w.taskArrived)
    assert(not w.ready)
    w.f(w, w.data)
    if w.head != nil: w.cleanFutures
    if w.shutdown:
      w.shutdown = false
      atomicDec currentPoolSize

proc setMinPoolSize*(size: range[1..MaxThreadPoolSize]) =
  ## sets the minimal thread pool size. The default value of this is 4.
  minPoolSize = size

proc setMaxPoolSize*(size: range[1..MaxThreadPoolSize]) =
  ## sets the minimal thread pool size. The default value of this
  ## is ``MaxThreadPoolSize``.
  maxPoolSize = size

var
  workers: array[MaxThreadPoolSize, TThread[ptr Worker]]
  workersData: array[MaxThreadPoolSize, Worker]

proc activateThread(i: int) {.noinline.} =
  workersData[i].taskArrived = createCondVar()
  workersData[i].taskStarted = createCondVar()
  initLock workersData[i].futureLock
  workersData[i].initialized = true
  createThread(workers[i], slave, addr(workersData[i]))

proc setup() =
  currentPoolSize = min(countProcessors(), MaxThreadPoolSize)
  readyWorker = addr(workersData[0])
  for i in 0.. <currentPoolSize: activateThread(i)

proc preferSpawn*(): bool =
  ## Use this proc to determine quickly if a 'spawn' or a direct call is
  ## preferable. If it returns 'true' a 'spawn' may make sense. In general
  ## it is not necessary to call this directly; use 'spawnX' instead.
  result = gSomeReady.counter > 0

proc spawn*(call: stmt) {.magic: "Spawn".}
  ## always spawns a new task, so that the 'call' is never executed on
  ## the calling thread. 'call' has to be proc call 'p(...)' where 'p'
  ## is gcsafe and has 'void' as the return type.

template spawnX*(call: stmt) =
  ## spawns a new task if a CPU core is ready, otherwise executes the
  ## call in the calling thread. Usually it is advised to
  ## use 'spawn' in order to not block the producer for an unknown
  ## amount of time. 'call' has to be proc call 'p(...)' where 'p'
  ## is gcsafe and has 'void' as the return type.
  if preferSpawn(): spawn call
  else: call

proc parallel*(body: stmt) {.magic: "Parallel".}
  ## a parallel section can be used to execute a block in parallel. ``body``
  ## has to be in a DSL that is a particular subset of the language. Please
  ## refer to the manual for further information.

var
  state: ThreadPoolState
  stateLock: TLock

initLock stateLock

proc selectWorker(w: ptr Worker; fn: WorkerProc; data: pointer): bool =
  if cas(addr w.ready, true, false):
    w.data = data
    w.f = fn
    signal(w.taskArrived)
    await(w.taskStarted)
    result = true

proc nimSpawn(fn: WorkerProc; data: pointer) {.compilerProc.} =
  # implementation of 'spawn' that is used by the code generator.
  while true:
    if selectWorker(readyWorker, fn, data): return
    for i in 0.. <currentPoolSize:
      if selectWorker(addr(workersData[i]), fn, data): return
    # determine what to do, but keep in mind this is expensive too:
    # state.calls < maxPoolSize: warmup phase
    # (state.calls and 127) == 0: periodic check
    if state.calls < maxPoolSize or (state.calls and 127) == 0:
      # ensure the call to 'advice' is atomic:
      if tryAcquire(stateLock):
        case advice(state)
        of doNothing: discard
        of doCreateThread:
          if currentPoolSize < maxPoolSize:
            if not workersData[currentPoolSize].initialized:
              activateThread(currentPoolSize)
            let w = addr(workersData[currentPoolSize])
            atomicInc currentPoolSize
            if selectWorker(w, fn, data):
              release(stateLock)
              return
            # else we didn't succeed but some other thread, so do nothing.
        of doShutdownThread:
          if currentPoolSize > minPoolSize:
            let w = addr(workersData[currentPoolSize-1])
            w.shutdown = true
          # we don't free anything here. Too dangerous.
        release(stateLock)
      # else the acquire failed, but this means some
      # other thread succeeded, so we don't need to do anything here.
    await(gSomeReady)

proc sync*() =
  ## a simple barrier to wait for all spawn'ed tasks. If you need more elaborate
  ## waiting, you have to use an explicit barrier.
  while true:
    var allReady = true
    for i in 0 .. <currentPoolSize:
      if not allReady: break
      allReady = allReady and workersData[i].ready
    if allReady: break
    await(gSomeReady)

setup()
