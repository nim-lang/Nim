#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2014 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Implements Nimrod's `spawn <manual.html#spawn>`_.

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
  # due to the signaling between threads, it is ensured we are the only
  # one with access to 'entered' so we don't need 'atomicInc' here:
  inc b.entered
  # also we need no 'fence' instructions here as soon 'nimArgsPassingDone'
  # will be called which already will perform a fence for us.

proc barrierLeave(b: ptr Barrier) {.compilerProc, inline.} =
  atomicInc b.left
  when not defined(x86): fence()
  if b.interest and b.left == b.entered: signal(b.cv)

proc openBarrier(b: ptr Barrier) {.compilerProc, inline.} =
  b.entered = 0
  b.left = 0
  b.interest = false

proc closeBarrier(b: ptr Barrier) {.compilerProc.} =
  fence()
  if b.left != b.entered:
    b.cv = createCondVar()
    fence()
    b.interest = true
    fence()
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

  FlowVarBase* = ref FlowVarBaseObj ## untyped base class for 'FlowVar[T]'
  FlowVarBaseObj = object of TObject
    ready, usesCondVar: bool
    cv: CondVar #\
    # for 'awaitAny' support
    ai: ptr AwaitInfo
    idx: int
    data: pointer  # we incRef and unref it to keep it alive
    owner: pointer # ptr Worker

  FlowVarObj[T] = object of FlowVarBaseObj
    blob: T

  FlowVar*{.compilerProc.}[T] = ref FlowVarObj[T] ## a data flow variable

  ToFreeQueue = object
    len: int
    lock: TLock
    empty: TCond
    data: array[512, pointer]

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
    q: ToFreeQueue

proc await*(fv: FlowVarBase) =
  ## waits until the value for the flowVar arrives. Usually it is not necessary
  ## to call this explicitly.
  if fv.usesCondVar:
    fv.usesCondVar = false
    await(fv.cv)
    destroyCondVar(fv.cv)

proc finished(fv: FlowVarBase) =
  doAssert fv.ai.isNil, "flowVar is still attached to an 'awaitAny'"
  # we have to protect against the rare cases where the owner of the flowVar
  # simply disregards the flowVar and yet the "flowVarr" has not yet written
  # anything to it:
  await(fv)
  if fv.data.isNil: return
  let owner = cast[ptr Worker](fv.owner)
  let q = addr(owner.q)
  var waited = false
  while true:
    acquire(q.lock)
    if q.len < q.data.len:
      q.data[q.len] = fv.data
      inc q.len
      release(q.lock)
      break
    else:
      # the queue is exhausted! We block until it has been cleaned:
      release(q.lock)
      wait(q.empty, q.lock)
      waited = true
  fv.data = nil
  # wakeup other potentially waiting threads:
  if waited: signal(q.empty)

proc cleanFlowVars(w: ptr Worker) =
  let q = addr(w.q)
  acquire(q.lock)
  for i in 0 .. <q.len:
    GC_unref(cast[PObject](q.data[i]))
  q.len = 0
  release(q.lock)
  signal(q.empty)

proc fvFinalizer[T](fv: FlowVar[T]) = finished(fv)

proc nimCreateFlowVar[T](): FlowVar[T] {.compilerProc.} =
  new(result, fvFinalizer)

proc nimFlowVarCreateCondVar(fv: FlowVarBase) {.compilerProc.} =
  fv.cv = createCondVar()
  fv.usesCondVar = true

proc nimFlowVarSignal(fv: FlowVarBase) {.compilerProc.} =
  if fv.ai != nil:
    acquire(fv.ai.cv.L)
    fv.ai.idx = fv.idx
    inc fv.ai.cv.counter
    release(fv.ai.cv.L)
    signal(fv.ai.cv.c)
  if fv.usesCondVar: signal(fv.cv)

proc awaitAndThen*[T](fv: FlowVar[T]; action: proc (x: T) {.closure.}) =
  ## blocks until the ``fv`` is available and then passes its value
  ## to ``action``. Note that due to Nimrod's parameter passing semantics this
  ## means that ``T`` doesn't need to be copied and so ``awaitAndThen`` can
  ## sometimes be more efficient than ``^``.
  await(fv)
  when T is string or T is seq:
    action(cast[T](fv.data))
  elif T is ref:
    {.error: "'awaitAndThen' not available for FlowVar[ref]".}
  else:
    action(fv.blob)
  finished(fv)

proc `^`*[T](fv: FlowVar[ref T]): foreign ptr T =
  ## blocks until the value is available and then returns this value.
  await(fv)
  result = cast[foreign ptr T](fv.data)

proc `^`*[T](fv: FlowVar[T]): T =
  ## blocks until the value is available and then returns this value.
  await(fv)
  when T is string or T is seq:
    result = cast[T](fv.data)
  else:
    result = fv.blob

proc awaitAny*(flowVars: openArray[FlowVarBase]): int =
  ## awaits any of the given flowVars. Returns the index of one flowVar for
  ## which a value arrived. A flowVar only supports one call to 'awaitAny' at
  ## the same time. That means if you await([a,b]) and await([b,c]) the second
  ## call will only await 'c'. If there is no flowVar left to be able to wait
  ## on, -1 is returned.
  ## **Note**: This results in non-deterministic behaviour and so should be
  ## avoided.
  var ai: AwaitInfo
  ai.cv = createCondVar()
  var conflicts = 0
  for i in 0 .. flowVars.high:
    if cas(addr flowVars[i].ai, nil, addr ai):
      flowVars[i].idx = i
    else:
      inc conflicts
  if conflicts < flowVars.len:
    await(ai.cv)
    result = ai.idx
    for i in 0 .. flowVars.high:
      discard cas(addr flowVars[i].ai, addr ai, nil)
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
    if w.q.len != 0: w.cleanFlowVars
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
  workersData[i].initialized = true
  initCond(workersData[i].q.empty)
  initLock(workersData[i].q.lock)
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
  ## is gcsafe and has a return type that is either 'void' or compatible
  ## with ``FlowVar[T]``.

template spawnX*(call: expr): expr =
  ## spawns a new task if a CPU core is ready, otherwise executes the
  ## call in the calling thread. Usually it is advised to
  ## use 'spawn' in order to not block the producer for an unknown
  ## amount of time. 'call' has to be proc call 'p(...)' where 'p'
  ## is gcsafe and has a return type that is either 'void' or compatible
  ## with ``FlowVar[T]``.
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
