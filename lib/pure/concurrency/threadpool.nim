#
#
#            Nim's Runtime Library
#        (c) Copyright 2014 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Implements Nim's 'spawn'.

when not compileOption("threads"):
  {.error: "Threadpool requires --threads:on option.".}

import cpuinfo, cpuload, locks

{.push stackTrace:off.}

type
  Semaphore = object
    lock: TLock
    cond: TCond
    counter: int

proc createSemaphore(): Semaphore =
  initCond(result.cond)
  initLock(result.lock)

proc destroySemaphore(sem: var Semaphore) {.inline.} =
  deinitCond(sem.cond)
  deinitLock(sem.lock)

proc await(sem: var Semaphore) =
  acquire(sem.lock)
  while sem.counter <= 0:
    wait(sem.cond, sem.lock)
  dec sem.counter
  release(sem.lock)

proc signal(sem: var Semaphore) =
  acquire(sem.lock)
  inc sem.counter
  release(sem.lock)
  signal(sem.cond)

const CacheLineSize = 32 # true for most archs

type
  Barrier {.compilerProc.} = object
    entered: int
    left: int
    lock: TLock
    cond: TCond
    # sem: Semaphore # condvar takes 3 words at least
    when sizeof(int) < 8:
      cacheAlign: array[CacheLineSize-4*sizeof(int), byte]
    cacheAlign2: array[CacheLineSize-sizeof(int), byte]
    interest: bool ## wether the master is interested in the "all done" event

proc barrierEnter(b: ptr Barrier) {.compilerProc, inline.} =
  # b.entered will only ever be accessed from one thread
  inc b.entered

proc barrierLeave(b: ptr Barrier) {.compilerProc, inline.} =
  atomicInc b.left
  # We may not have seen the final value of b.entered yet,
  # so we need to check for >= instead of ==.
  if b.left >= b.entered:
    acquire b.lock
    if b.left >= b.entered and b.interest:
      signal b.cond
    release b.lock

proc openBarrier(b: ptr Barrier) {.compilerProc, inline.} =
  b.entered = 0
  b.left = 0
  b.interest = false
  initLock b.lock
  initCond b.cond

proc closeBarrier(b: ptr Barrier) {.compilerProc.} =
  if b.left != b.entered:
    acquire b.lock
    b.interest = true
    while b.left != b.entered:
      wait b.cond, b.lock
    release b.lock
  deinitLock b.lock
  deinitCond b.cond


{.pop.}

# ----------------------------------------------------------------------------

type
  foreign* = object ## a region that indicates the pointer comes from a
                    ## foreign thread heap.
  AwaitInfo = object
    sem: Semaphore
    idx: int

  FlowVarBase* = ref FlowVarBaseObj ## untyped base class for 'FlowVar[T]'
  FlowVarBaseObj = object of RootObj
    ready, usesSemaphore, awaited: bool
    sem: Semaphore #\
    # for 'awaitAny' support
    ai: ptr AwaitInfo
    idx: int
    data: pointer  # we incRef and unref it to keep it alive; note this MUST NOT
                   # be RootRef here otherwise the wrong GC keeps track of it!
    owner: pointer # ptr Worker

  FlowVarObj[T] = object of FlowVarBaseObj
    blob: T

  FlowVar*{.compilerProc.}[T] = ref FlowVarObj[T] ## a data flow variable

  FlowVarCleanupPtr = ptr FlowVarCleanupObj
  FlowVarCleanupObj = object
    data: pointer
    next: FlowVarCleanupPtr

  ToFreeQueue = object
    lock: TLock
    list, free: FlowVarCleanupPtr

  WorkerProc = proc (thread, args: pointer) {.nimcall, gcsafe.}
  Worker = object
    f: WorkerProc
    data: pointer
    initialized: bool # whether it has even been initialized
    idle: bool # whether the worker should pause
    idleSem: Semaphore
    q: ToFreeQueue

  TaskObj = object
    next: TaskPtr
    sem: ptr Semaphore
    func: WorkerProc
    data: pointer
  TaskPtr = ptr TaskObj
  TaskQueue = object
    lock: TLock
    cond, sync: TCond
    running: int
    waiting: int
    head, tail: TaskPtr
    free: TaskPtr

const
  MaxThreadPoolSize* = 256 ## maximal size of the thread pool. 256 threads
                           ## should be good enough for anybody ;-)

var
  state: ThreadpoolState
  currentPoolSize: int
  maxPoolSize = MaxThreadPoolSize
  minPoolSize = 4
  targetPoolSize = minPoolSize
  pending: TaskQueue

proc scheduleTask(func: WorkerProc, data: pointer, sem: ptr Semaphore = nil) = 
  var task: TaskPtr
  acquire pending.lock
  if pending.free == nil:
    task = createShared(TaskObj)
  else:
    task = pending.free
    pending.free = task.next
    task.next = nil
  task.func = func
  task.data = data
  task.sem = sem
  if pending.head == nil:
    pending.head = task
    pending.tail = task
  else:
    # Because spawn blocks, we process those tasks in LIFO order
    if sem != nil:
      task.next = pending.head
      pending.head = task
    else:
      pending.tail.next = task
      pending.tail = task
  signal pending.cond
  release pending.lock

proc waitTask(): TaskObj =
  acquire pending.lock
  inc pending.waiting
  while pending.head == nil or pending.running >= targetPoolSize:
    wait(pending.cond, pending.lock)
  var task = pending.head
  result = task[]
  pending.head = task.next
  if pending.head == nil:
    pending.tail = nil
  task.next = pending.free
  pending.free = task
  inc pending.running
  dec pending.waiting
  release pending.lock

proc finishTask() =
  acquire pending.lock
  dec pending.running
  if pending.running == 0 and pending.waiting == 0:
    # All tasks are done
    signal pending.sync
  elif pending.waiting != 0:
    targetPoolSize = minPoolSize
    if pending.running >= minPoolSize and pending.running < maxPoolSize:
      var counter {.global.} = 0
      if counter < maxPoolSize or (counter and 127) == 0:
        # Account for the fact that running has already been decremented
        case advice(state)
        of doNothing:
          targetPoolSize = pending.running + 1
        of doShutdownThread:
          targetPoolSize = pending.running
        of doCreateThread:
          targetPoolSize = pending.running + 2
    if pending.running < targetPoolSize:
      signal pending.cond
  release pending.lock

proc await*(fv: FlowVarBase) =
  ## waits until the value for the flowVar arrives. Usually it is not necessary
  ## to call this explicitly.
  if fv.usesSemaphore and not fv.awaited:
    fv.awaited = true
    await(fv.sem)
    destroySemaphore(fv.sem)

proc finished(fv: FlowVarBase) =
  doAssert fv.ai.isNil, "flowVar is still attached to an 'awaitAny'"
  # we have to protect against the rare cases where the owner of the flowVar
  # simply disregards the flowVar and yet the "flowVar" has not yet written
  # anything to it:
  await(fv)
  if fv.data.isNil: return
  let owner = cast[ptr Worker](fv.owner)
  let q = addr(owner.q)
  acquire(q.lock)
  var cleanup: FlowVarCleanupPtr
  if q.free == nil:
    cleanup = createShared(FlowVarCleanupObj)
  else:
    cleanup = q.free
    q.free = q.free.next
  cleanup.data = fv.data
  cleanup.next = q.list
  q.list = cleanup
  fv.data = nil
  release(q.lock)

proc cleanFlowVars(w: ptr Worker) =
  let q = addr(w.q)
  acquire(q.lock)
  while q.list != nil:
    var cleanup = q.list
    q.list = cleanup.next
    cleanup.next = q.free
    q.free = cleanup
    GC_unref(cast[RootRef](cleanup.data))
  release(q.lock)

proc fvFinalizer[T](fv: FlowVar[T]) = finished(fv)

proc nimCreateFlowVar[T](): FlowVar[T] {.compilerProc.} =
  new(result, fvFinalizer)

proc nimFlowVarCreateSemaphore(fv: FlowVarBase) {.compilerProc.} =
  fv.sem = createSemaphore()
  fv.usesSemaphore = true

proc nimFlowVarSignal(fv: FlowVarBase) {.compilerProc.} =
  if fv.ai != nil:
    acquire(fv.ai.sem.lock)
    fv.ai.idx = fv.idx
    inc fv.ai.sem.counter
    release(fv.ai.sem.lock)
    signal(fv.ai.sem.cond)
  if fv.usesSemaphore: 
    signal(fv.sem)

proc awaitAndThen*[T](fv: FlowVar[T]; action: proc (x: T) {.closure.}) =
  ## blocks until the ``fv`` is available and then passes its value
  ## to ``action``. Note that due to Nim's parameter passing semantics this
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
    # XXX closures? deepCopy?
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
  ai.sem = createSemaphore()
  var conflicts = 0
  for i in 0 .. flowVars.high:
    if cas(addr flowVars[i].ai, nil, addr ai):
      flowVars[i].idx = i
    else:
      inc conflicts
  if conflicts < flowVars.len:
    await(ai.sem)
    result = ai.idx
    for i in 0 .. flowVars.high:
      discard cas(addr flowVars[i].ai, addr ai, nil)
  else:
    result = -1
  destroySemaphore(ai.sem)

var notifyCallerSem {.threadvar.}: ptr Semaphore

proc nimArgsPassingDone(p: pointer) {.compilerProc.} =
  if notifyCallerSem != nil:
    signal notifyCallerSem[]

proc slave(w: ptr Worker) {.thread.} =
  while true:
    let task = waitTask()
    notifyCallerSem = task.sem
    task.func(w, task.data)
    finishTask()
    # Dirty read, we're going to properly check the value
    # in cleanFlowVars.
    if w.q.list != nil: w.cleanFlowVars
    # Dirty read again, we may miss a shutdown request the
    # first time around, but we should get it the next time.
    # Better than to introduce overhead each time for a
    # rare occurrence.
    if w.idle:
      acquire w.idleSem.lock
      while w.idle:
        wait w.idleSem.cond, w.idleSem.lock
      release w.idleSem.lock

var
  workers: array[MaxThreadPoolSize, TThread[ptr Worker]]
  workersData: array[MaxThreadPoolSize, Worker]

proc setMinPoolSize*(size: range[1..MaxThreadPoolSize]) =
  ## sets the minimal thread pool size. The default value of this is 4.
  minPoolSize = size
  targetPoolSize = size

proc activateThread(i: int) {.noinline.} =
  workersData[i].initialized = true
  workersData[i].idle = false
  workersData[i].idleSem = createSemaphore()
  initLock(workersData[i].q.lock)
  createThread(workers[i], slave, addr(workersData[i]))

proc setMaxPoolSize*(size: range[1..MaxThreadPoolSize]) =
  ## sets the minimal thread pool size. The default value of this
  ## is ``MaxThreadPoolSize``.
  maxPoolSize = size
  if currentPoolSize > maxPoolSize:
    for i in maxPoolSize..currentPoolSize-1:
      let w = addr(workersData[i])
      acquire w.idleSem.lock
      w.idle = true
      release w.idleSem.lock
  elif currentPoolSize < maxPoolSize:
    for i in currentPoolSize+1..maxPoolSize:
      let w = addr(workersData[i])
      if w.initialized:
        acquire w.idleSem.lock
        w.idle = false
        signal w.idleSem.cond
        release w.idleSem.lock
      else:
        activateThread(i)

proc setup() =
  initLock pending.lock
  initCond pending.cond
  initCond pending.sync
  currentPoolSize = min(countProcessors(), MaxThreadPoolSize)
  for i in 0.. <currentPoolSize: activateThread(i)

proc preferSpawn*(): bool =
  ## Use this proc to determine quickly if a 'spawn' or a direct call is
  ## preferable. If it returns 'true' a 'spawn' may make sense. In general
  ## it is not necessary to call this directly; use 'spawnX' instead.
  acquire pending.lock
  result = pending.running < currentPoolSize
  release pending.lock

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
  taskStarted {.threadvar.}: Semaphore
  taskStartedSemInit {.threadvar.}: bool

proc nimSpawn(fn: WorkerProc; data: pointer) {.compilerProc.} =
  # implementation of 'spawn' that is used by the code generator.
  if not taskStartedSemInit:
    taskStarted = createSemaphore()
    taskStartedSemInit = true
  scheduleTask(fn, data, addr(taskStarted))
  await(taskStarted)

proc sync*() =
  ## a simple barrier to wait for all spawn'ed tasks. If you need more elaborate
  ## waiting, you have to use an explicit barrier.
  acquire pending.lock
  while pending.running != 0 and pending.head != nil:
    wait(pending.sync, pending.lock)
  release pending.lock

setup()
