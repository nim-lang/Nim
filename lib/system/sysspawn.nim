#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Implements Nim's 'spawn'.

when not declared(NimString):
  {.error: "You must not import this module explicitly".}

{.push stackTrace:off.}

# We declare our own condition variables here to get rid of the dummy lock
# on Windows:

type
  CondVar = object
    c: SysCond
    stupidLock: SysLock
    counter: int

proc createCondVar(): CondVar =
  initSysCond(result.c)
  initSysLock(result.stupidLock)
  #acquireSys(result.stupidLock)

proc destroyCondVar(c: var CondVar) {.inline.} =
  deinitSysCond(c.c)

proc await(cv: var CondVar) =
  acquireSys(cv.stupidLock)
  while cv.counter <= 0:
    waitSysCond(cv.c, cv.stupidLock)
  dec cv.counter
  releaseSys(cv.stupidLock)

proc signal(cv: var CondVar) =
  acquireSys(cv.stupidLock)
  inc cv.counter
  releaseSys(cv.stupidLock)
  signalSysCond(cv.c)

type
  FastCondVar = object
    event, slowPath: bool
    slow: CondVar

proc createFastCondVar(): FastCondVar =
  initSysCond(result.slow.c)
  initSysLock(result.slow.stupidLock)
    #acquireSys(result.slow.stupidLock)
  result.event = false
  result.slowPath = false

proc await(cv: var FastCondVar) =
  #for i in 0 .. 50:
  #  if cas(addr cv.event, true, false):
  #    # this is a HIT: Triggers > 95% in my tests.
  #    return
  #  cpuRelax()
  #cv.slowPath = true
  # XXX For some reason this crashes some test programs
  await(cv.slow)
  cv.event = false

proc signal(cv: var FastCondVar) =
  cv.event = true
  #if cas(addr cv.slowPath, true, false):
  signal(cv.slow)

type
  Barrier* {.compilerproc.} = object
    counter: int
    cv: CondVar

proc barrierEnter*(b: ptr Barrier) {.compilerproc.} =
  atomicInc b.counter

proc barrierLeave*(b: ptr Barrier) {.compilerproc.} =
  atomicDec b.counter
  if b.counter <= 0: signal(b.cv)

proc openBarrier*(b: ptr Barrier) {.compilerproc.} =
  b.counter = 0
  b.cv = createCondVar()

proc closeBarrier*(b: ptr Barrier) {.compilerproc.} =
  await(b.cv)
  destroyCondVar(b.cv)

{.pop.}

# ----------------------------------------------------------------------------

type
  WorkerProc = proc (thread, args: pointer) {.nimcall, gcsafe.}
  Worker = object
    taskArrived: CondVar
    taskStarted: FastCondVar #\
    # task data:
    f: WorkerProc
    data: pointer
    ready: bool # put it here for correct alignment!

proc nimArgsPassingDone(p: pointer) {.compilerproc.} =
  let w = cast[ptr Worker](p)
  signal(w.taskStarted)

var gSomeReady = createFastCondVar()

proc slave(w: ptr Worker) {.thread.} =
  while true:
    w.ready = true # If we instead signal "workerReady" we need the scheduler
                   # to notice this. The scheduler could then optimize the
                   # layout of the worker threads (e.g. keep the list sorted)
                   # so that no search for a "ready" thread is necessary.
                   # This might be implemented later, but is more tricky than
                   # it looks because 'spawn' itself can run concurrently.
    signal(gSomeReady)
    await(w.taskArrived)
    assert(not w.ready)
    # shield against spurious wakeups:
    if w.data != nil:
      w.f(w, w.data)
      w.data = nil

const NumThreads = 4

var
  workers: array[NumThreads, Thread[ptr Worker]]
  workersData: array[NumThreads, Worker]

proc setup() =
  for i in 0 ..< NumThreads:
    workersData[i].taskArrived = createCondVar()
    workersData[i].taskStarted = createFastCondVar()
    createThread(workers[i], slave, addr(workersData[i]))

proc preferSpawn*(): bool =
  ## Use this proc to determine quickly if a 'spawn' or a direct call is
  ## preferable. If it returns 'true' a 'spawn' may make sense. In general
  ## it is not necessary to call this directly; use 'spawnX' instead.
  result = gSomeReady.event

proc spawn*(call: typed) {.magic: "Spawn".}
  ## always spawns a new task, so that the 'call' is never executed on
  ## the calling thread. 'call' has to be proc call 'p(...)' where 'p'
  ## is gcsafe and has 'void' as the return type.

template spawnX*(call: typed) =
  ## spawns a new task if a CPU core is ready, otherwise executes the
  ## call in the calling thread. Usually it is advised to
  ## use 'spawn' in order to not block the producer for an unknown
  ## amount of time. 'call' has to be proc call 'p(...)' where 'p'
  ## is gcsafe and has 'void' as the return type.
  if preferSpawn(): spawn call
  else: call

proc nimSpawn(fn: WorkerProc; data: pointer) {.compilerproc.} =
  # implementation of 'spawn' that is used by the code generator.
  while true:
    for i in 0.. high(workers):
      let w = addr(workersData[i])
      if cas(addr w.ready, true, false):
        w.data = data
        w.f = fn
        signal(w.taskArrived)
        await(w.taskStarted)
        return
    await(gSomeReady)

proc sync*() =
  ## a simple barrier to wait for all spawn'ed tasks. If you need more elaborate
  ## waiting, you have to use an explicit barrier.
  while true:
    var allReady = true
    for i in 0 .. high(workers):
      if not allReady: break
      allReady = allReady and workersData[i].ready
    if allReady: break
    await(gSomeReady)

setup()
