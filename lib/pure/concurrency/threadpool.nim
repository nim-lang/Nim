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

const CacheLineSize = 32 # true for most archs

type
  Barrier {.compilerProc.} = object
    entered: int
    cv: CondVar # condvar takes 3 words at least
    when sizeof(int) < 8:
      cacheAlign: array[CacheLineSize-4*sizeof(int), byte] 
    left: int
    cacheAlign2: array[CacheLineSize-sizeof(int), byte]
    interest: bool ## wether the master is interested in the "all done" event

proc barrierEnter(b: ptr Barrier) {.compilerProc, inline.} =
  ## due to the signaling between threads, it is ensured we are the only
  ## one with access to 'entered' so we don't need 'atomicInc' here:
  inc b.entered

proc barrierLeave(b: ptr Barrier) {.compilerProc, inline.} =
  atomicInc b.left
  if b.interest and b.left == b.entered: signal(b.cv)

proc openBarrier(b: ptr Barrier) {.compilerProc, inline.} =
  b.entered = 0
  b.left = 0
  b.interest = false

proc closeBarrier(b: ptr Barrier) {.compilerProc.} =
  if b.left != b.entered:
    b.cv = createCondVar()
    b.interest = true # XXX we really need to ensure no re-orderings are done
                      # by the C compiler here
    while b.left != b.entered: await(b.cv)
    destroyCondVar(b.cv)

{.pop.}

# ----------------------------------------------------------------------------

type
  foreign* = object ## a region that indicates the pointer comes from a
                    ## foreign thread heap.
  AwaitInfo = object
    cv: CondVar
    idx: int

  RawPromise* = ptr RawPromiseObj ## untyped base class for 'Promise[T]'
  RawPromiseObj {.inheritable.} = object # \
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
    next: RawPromise
    align: float64 # a float for proper alignment

  Promise* {.compilerProc.} [T] = ptr object of RawPromiseObj
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
    promiseLock: TLock
    head: RawPromise

proc finished*(prom: RawPromise) =
  ## This MUST be called for every created promise to free its associated
  ## resources. Note that the default reading operation ``^`` is destructive
  ## and calls ``finished``.
  doAssert prom.ai.isNil, "promise is still attached to an 'awaitAny'"
  assert prom.next == nil
  let w = prom.owner
  acquire(w.promiseLock)
  prom.next = w.head
  w.head = prom
  release(w.promiseLock)

proc cleanPromises(w: ptr Worker) =
  var it = w.head
  acquire(w.promiseLock)
  while it != nil:
    let nxt = it.next
    if it.usesCondVar: destroyCondVar(it.cv)
    if it.data != nil: GC_unref(it.data)
    dealloc(it)
    it = nxt
  w.head = nil
  release(w.promiseLock)

proc nimCreatePromise(owner: pointer; blobSize: int): RawPromise {.
                     compilerProc.} =
  result = cast[RawPromise](alloc0(RawPromiseObj.sizeof + blobSize))
  result.owner = cast[ptr Worker](owner)

proc nimPromiseCreateCondVar(prom: RawPromise) {.compilerProc.} =
  prom.cv = createCondVar()
  prom.usesCondVar = true

proc nimPromiseSignal(prom: RawPromise) {.compilerProc.} =
  if prom.ai != nil:
    acquire(prom.ai.cv.L)
    prom.ai.idx = prom.idx
    inc prom.ai.cv.counter
    release(prom.ai.cv.L)
    signal(prom.ai.cv.c)
  if prom.usesCondVar: signal(prom.cv)

proc await*[T](prom: Promise[T]) =
  ## waits until the value for the promise arrives.
  if prom.usesCondVar: await(prom.cv)

proc awaitAndThen*[T](prom: Promise[T]; action: proc (x: T) {.closure.}) =
  ## blocks until the ``prom`` is available and then passes its value
  ## to ``action``. Note that due to Nimrod's parameter passing semantics this
  ## means that ``T`` doesn't need to be copied and so ``awaitAndThen`` can
  ## sometimes be more efficient than ``^``.
  if prom.usesCondVar: await(prom)
  when T is string or T is seq:
    action(cast[T](prom.data))
  elif T is ref:
    {.error: "'awaitAndThen' not available for Promise[ref]".}
  else:
    action(prom.blob)
  finished(prom)

proc `^`*[T](prom: Promise[ref T]): foreign ptr T =
  ## blocks until the value is available and then returns this value. Note
  ## this reading is destructive for reasons of efficiency and convenience.
  ## This calls ``finished(prom)``.
  if prom.usesCondVar: await(prom)
  result = cast[foreign ptr T](prom.data)
  finished(prom)

proc `^`*[T](prom: Promise[T]): T =
  ## blocks until the value is available and then returns this value. Note
  ## this reading is destructive for reasons of efficiency and convenience.
  ## This calls ``finished(prom)``.
  if prom.usesCondVar: await(prom)
  when T is string or T is seq:
    result = cast[T](prom.data)
  else:
    result = prom.blob
  finished(prom)

proc awaitAny*(promises: openArray[RawPromise]): int =
  # awaits any of the given promises. Returns the index of one promise for which
  ## a value arrived. A promise only supports one call to 'awaitAny' at the
  ## same time. That means if you await([a,b]) and await([b,c]) the second
  ## call will only await 'c'. If there is no promise left to be able to wait
  ## on, -1 is returned.
  ## **Note**: This results in non-deterministic behaviour and so should be
  ## avoided.
  var ai: AwaitInfo
  ai.cv = createCondVar()
  var conflicts = 0
  for i in 0 .. promises.high:
    if cas(addr promises[i].ai, nil, addr ai):
      promises[i].idx = i
    else:
      inc conflicts
  if conflicts < promises.len:
    await(ai.cv)
    result = ai.idx
    for i in 0 .. promises.high:
      discard cas(addr promises[i].ai, addr ai, nil)
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
    if w.head != nil: w.cleanPromises
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
  initLock workersData[i].promiseLock
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

proc spawn*(call: expr): expr {.magic: "Spawn".}
  ## always spawns a new task, so that the 'call' is never executed on
  ## the calling thread. 'call' has to be proc call 'p(...)' where 'p'
  ## is gcsafe and has 'void' as the return type.

template spawnX*(call: expr): expr =
  ## spawns a new task if a CPU core is ready, otherwise executes the
  ## call in the calling thread. Usually it is advised to
  ## use 'spawn' in order to not block the producer for an unknown
  ## amount of time. 'call' has to be proc call 'p(...)' where 'p'
  ## is gcsafe and has 'void' as the return type.
  (if preferSpawn(): spawn call else: call)

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
