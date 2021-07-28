#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Thread support for Nim.
##
## **Note**: This is part of the system module. Do not import it directly.
## To activate thread support you need to compile
## with the `--threads:on`:option: command line switch.
##
## Nim's memory model for threads is quite different from other common
## programming languages (C, Pascal): Each thread has its own
## (garbage collected) heap and sharing of memory is restricted. This helps
## to prevent race conditions and improves efficiency. See `the manual for
## details of this memory model <manual.html#threads>`_.
##
## Examples
## ========
##
## .. code-block:: Nim
##
##  import std/locks
##
##  var
##    thr: array[0..4, Thread[tuple[a,b: int]]]
##    L: Lock
##
##  proc threadFunc(interval: tuple[a,b: int]) {.thread.} =
##    for i in interval.a..interval.b:
##      acquire(L) # lock stdout
##      echo i
##      release(L)
##
##  initLock(L)
##
##  for i in 0..high(thr):
##    createThread(thr[i], threadFunc, (i*10, i*10+5))
##  joinThreads(thr)
##
##  deinitLock(L)

when not declared(ThisIsSystem):
  {.error: "You must not import this module explicitly".}

const
  StackGuardSize = 4096
  ThreadStackMask =
    when defined(genode):
      1024*64*sizeof(int)-1
    else:
      1024*256*sizeof(int)-1
  ThreadStackSize = ThreadStackMask+1 - StackGuardSize

#const globalsSlot = ThreadVarSlot(0)
#sysAssert checkSlot.int == globalsSlot.int

# create for the main thread. Note: do not insert this data into the list
# of all threads; it's not to be stopped etc.
when not defined(useNimRtl):
  #when not defined(createNimRtl): initStackBottom()
  when declared(initGC):
    initGC()
    when not emulatedThreadVars:
      type ThreadType {.pure.} = enum
        None = 0,
        NimThread = 1,
        ForeignThread = 2
      var
        threadType {.rtlThreadVar.}: ThreadType

      threadType = ThreadType.NimThread

# We jump through some hops here to ensure that Nim thread procs can have
# the Nim calling convention. This is needed because thread procs are
# ``stdcall`` on Windows and ``noconv`` on UNIX. Alternative would be to just
# use ``stdcall`` since it is mapped to ``noconv`` on UNIX anyway.

type
  Thread*[TArg] = object
    core: PGcThread
    sys: SysThread
    when TArg is void:
      dataFn: proc () {.nimcall, gcsafe.}
    else:
      dataFn: proc (m: TArg) {.nimcall, gcsafe.}
      data: TArg

proc `=copy`*[TArg](x: var Thread[TArg], y: Thread[TArg]) {.error.}

var
  threadDestructionHandlers {.rtlThreadVar.}: seq[proc () {.closure, gcsafe, raises: [].}]

proc onThreadDestruction*(handler: proc () {.closure, gcsafe, raises: [].}) =
  ## Registers a *thread local* handler that is called at the thread's
  ## destruction.
  ##
  ## A thread is destructed when the `.thread` proc returns
  ## normally or when it raises an exception. Note that unhandled exceptions
  ## in a thread nevertheless cause the whole process to die.
  threadDestructionHandlers.add handler

template afterThreadRuns() =
  for i in countdown(threadDestructionHandlers.len-1, 0):
    threadDestructionHandlers[i]()

when not defined(boehmgc) and not hasSharedHeap and not defined(gogc) and not defined(gcRegions):
  proc deallocOsPages() {.rtl, raises: [].}

proc threadTrouble() {.raises: [], gcsafe.}
  ## defined in system/excpt.nim

when defined(boehmgc):
  type GCStackBaseProc = proc(sb: pointer, t: pointer) {.noconv.}
  proc boehmGC_call_with_stack_base(sbp: GCStackBaseProc, p: pointer)
    {.importc: "GC_call_with_stack_base", boehmGC.}
  proc boehmGC_register_my_thread(sb: pointer)
    {.importc: "GC_register_my_thread", boehmGC.}
  proc boehmGC_unregister_my_thread()
    {.importc: "GC_unregister_my_thread", boehmGC.}

  proc threadProcWrapDispatch[TArg](sb: pointer, thrd: pointer) {.noconv, raises: [].} =
    boehmGC_register_my_thread(sb)
    try:
      let thrd = cast[ptr Thread[TArg]](thrd)
      when TArg is void:
        thrd.dataFn()
      else:
        thrd.dataFn(thrd.data)
    except:
      threadTrouble()
    finally:
      afterThreadRuns()
    boehmGC_unregister_my_thread()
else:
  proc threadProcWrapDispatch[TArg](thrd: ptr Thread[TArg]) {.raises: [].} =
    try:
      when TArg is void:
        thrd.dataFn()
      else:
        when defined(nimV2):
          thrd.dataFn(thrd.data)
        else:
          var x: TArg
          deepCopy(x, thrd.data)
          thrd.dataFn(x)
    except:
      threadTrouble()
    finally:
      afterThreadRuns()

proc threadProcWrapStackFrame[TArg](thrd: ptr Thread[TArg]) {.raises: [].} =
  when defined(boehmgc):
    boehmGC_call_with_stack_base(threadProcWrapDispatch[TArg], thrd)
  elif not defined(nogc) and not defined(gogc) and not defined(gcRegions) and not usesDestructors:
    var p {.volatile.}: pointer
    # init the GC for refc/markandsweep
    nimGC_setStackBottom(addr(p))
    initGC()
    when declared(threadType):
      threadType = ThreadType.NimThread
    threadProcWrapDispatch[TArg](thrd)
    when declared(deallocOsPages): deallocOsPages()
  else:
    threadProcWrapDispatch(thrd)

template threadProcWrapperBody(closure: untyped): untyped =
  var thrd = cast[ptr Thread[TArg]](closure)
  var core = thrd.core
  when declared(globalsSlot): threadVarSetValue(globalsSlot, thrd.core)
  threadProcWrapStackFrame(thrd)
  # Since an unhandled exception terminates the whole process (!), there is
  # no need for a ``try finally`` here, nor would it be correct: The current
  # exception is tried to be re-raised by the code-gen after the ``finally``!
  # However this is doomed to fail, because we already unmapped every heap
  # page!

  # mark as not running anymore:
  thrd.core = nil
  thrd.dataFn = nil
  deallocShared(cast[pointer](core))

{.push stack_trace:off.}
when defined(windows):
  proc threadProcWrapper[TArg](closure: pointer): int32 {.stdcall.} =
    threadProcWrapperBody(closure)
    # implicitly return 0
elif defined(genode):
   proc threadProcWrapper[TArg](closure: pointer) {.noconv.} =
    threadProcWrapperBody(closure)
else:
  proc threadProcWrapper[TArg](closure: pointer): pointer {.noconv.} =
    threadProcWrapperBody(closure)
{.pop.}

proc running*[TArg](t: Thread[TArg]): bool {.inline.} =
  ## Returns true if `t` is running.
  result = t.dataFn != nil

proc handle*[TArg](t: Thread[TArg]): SysThread {.inline.} =
  ## Returns the thread handle of `t`.
  result = t.sys

when hostOS == "windows":
  const MAXIMUM_WAIT_OBJECTS = 64

  proc joinThread*[TArg](t: Thread[TArg]) {.inline.} =
    ## Waits for the thread `t` to finish.
    discard waitForSingleObject(t.sys, -1'i32)

  proc joinThreads*[TArg](t: varargs[Thread[TArg]]) =
    ## Waits for every thread in `t` to finish.
    var a: array[MAXIMUM_WAIT_OBJECTS, SysThread]
    var k = 0
    while k < len(t):
      var count = min(len(t) - k, MAXIMUM_WAIT_OBJECTS)
      for i in 0..(count - 1): a[i] = t[i + k].sys
      discard waitForMultipleObjects(int32(count),
                                     cast[ptr SysThread](addr(a)), 1, -1)
      inc(k, MAXIMUM_WAIT_OBJECTS)

elif defined(genode):
  proc joinThread*[TArg](t: Thread[TArg]) {.importcpp.}
    ## Waits for the thread `t` to finish.

  proc joinThreads*[TArg](t: varargs[Thread[TArg]]) =
    ## Waits for every thread in `t` to finish.
    for i in 0..t.high: joinThread(t[i])

else:
  proc joinThread*[TArg](t: Thread[TArg]) {.inline.} =
    ## Waits for the thread `t` to finish.
    discard pthread_join(t.sys, nil)

  proc joinThreads*[TArg](t: varargs[Thread[TArg]]) =
    ## Waits for every thread in `t` to finish.
    for i in 0..t.high: joinThread(t[i])

when false:
  # XXX a thread should really release its heap here somehow:
  proc destroyThread*[TArg](t: var Thread[TArg]) =
    ## Forces the thread `t` to terminate. This is potentially dangerous if
    ## you don't have full control over `t` and its acquired resources.
    when hostOS == "windows":
      discard TerminateThread(t.sys, 1'i32)
    else:
      discard pthread_cancel(t.sys)
    when declared(registerThread): unregisterThread(addr(t))
    t.dataFn = nil
    ## if thread `t` already exited, `t.core` will be `null`.
    if not isNil(t.core):
      deallocShared(t.core)
      t.core = nil

when hostOS == "windows":
  proc createThread*[TArg](t: var Thread[TArg],
                           tp: proc (arg: TArg) {.thread, nimcall.},
                           param: TArg) =
    ## Creates a new thread `t` and starts its execution.
    ##
    ## Entry point is the proc `tp`.
    ## `param` is passed to `tp`. `TArg` can be `void` if you
    ## don't need to pass any data to the thread.
    t.core = cast[PGcThread](allocShared0(sizeof(GcThread)))

    when TArg isnot void: t.data = param
    t.dataFn = tp
    when hasSharedHeap: t.core.stackSize = ThreadStackSize
    var dummyThreadId: int32
    t.sys = createThread(nil, ThreadStackSize, threadProcWrapper[TArg],
                         addr(t), 0'i32, dummyThreadId)
    if t.sys <= 0:
      raise newException(ResourceExhaustedError, "cannot create thread")

  proc pinToCpu*[Arg](t: var Thread[Arg]; cpu: Natural) =
    ## Pins a thread to a `CPU`:idx:.
    ##
    ## In other words sets a thread's `affinity`:idx:.
    ## If you don't know what this means, you shouldn't use this proc.
    setThreadAffinityMask(t.sys, uint(1 shl cpu))

elif defined(genode):
  var affinityOffset: cuint = 1
    ## CPU affinity offset for next thread, safe to roll-over.

  proc createThread*[TArg](t: var Thread[TArg],
                           tp: proc (arg: TArg) {.thread, nimcall.},
                           param: TArg) =
    t.core = cast[PGcThread](allocShared0(sizeof(GcThread)))

    when TArg isnot void: t.data = param
    t.dataFn = tp
    when hasSharedHeap: t.stackSize = ThreadStackSize
    t.sys.initThread(
      runtimeEnv,
      ThreadStackSize.culonglong,
      threadProcWrapper[TArg], addr(t), affinityOffset)
    inc affinityOffset

  proc pinToCpu*[Arg](t: var Thread[Arg]; cpu: Natural) =
    {.hint: "cannot change Genode thread CPU affinity after initialization".}
    discard

else:
  proc createThread*[TArg](t: var Thread[TArg],
                           tp: proc (arg: TArg) {.thread, nimcall.},
                           param: TArg) =
    ## Creates a new thread `t` and starts its execution.
    ##
    ## Entry point is the proc `tp`. `param` is passed to `tp`.
    ## `TArg` can be `void` if you
    ## don't need to pass any data to the thread.
    t.core = cast[PGcThread](allocShared0(sizeof(GcThread)))

    when TArg isnot void: t.data = param
    t.dataFn = tp
    when hasSharedHeap: t.core.stackSize = ThreadStackSize
    var a {.noinit.}: Pthread_attr
    doAssert pthread_attr_init(a) == 0
    let setstacksizeResult = pthread_attr_setstacksize(a, ThreadStackSize)
    when not defined(ios):
      # This fails on iOS
      doAssert(setstacksizeResult == 0)
    if pthread_create(t.sys, a, threadProcWrapper[TArg], addr(t)) != 0:
      raise newException(ResourceExhaustedError, "cannot create thread")
    doAssert pthread_attr_destroy(a) == 0

  proc pinToCpu*[Arg](t: var Thread[Arg]; cpu: Natural) =
    ## Pins a thread to a `CPU`:idx:.
    ##
    ## In other words sets a thread's `affinity`:idx:.
    ## If you don't know what this means, you shouldn't use this proc.
    when not defined(macosx):
      var s {.noinit.}: CpuSet
      cpusetZero(s)
      cpusetIncl(cpu.cint, s)
      setAffinity(t.sys, csize_t(sizeof(s)), s)

proc createThread*(t: var Thread[void], tp: proc () {.thread, nimcall.}) =
  createThread[void](t, tp)

# we need to cache current threadId to not perform syscall all the time
var threadId {.threadvar.}: int

when defined(windows):
  proc getThreadId*(): int =
    ## Gets the ID of the currently running thread.
    if threadId == 0:
      threadId = int(getCurrentThreadId())
    result = threadId

elif defined(linux):
  proc syscall(arg: clong): clong {.varargs, importc: "syscall", header: "<unistd.h>".}
  when defined(amd64):
    const NR_gettid = clong(186)
  else:
    var NR_gettid {.importc: "__NR_gettid", header: "<sys/syscall.h>".}: clong

  proc getThreadId*(): int =
    ## Gets the ID of the currently running thread.
    if threadId == 0:
      threadId = int(syscall(NR_gettid))
    result = threadId

elif defined(dragonfly):
  proc lwp_gettid(): int32 {.importc, header: "unistd.h".}

  proc getThreadId*(): int =
    ## Gets the ID of the currently running thread.
    if threadId == 0:
      threadId = int(lwp_gettid())
    result = threadId

elif defined(openbsd):
  proc getthrid(): int32 {.importc: "getthrid", header: "<unistd.h>".}

  proc getThreadId*(): int =
    ## get the ID of the currently running thread.
    if threadId == 0:
      threadId = int(getthrid())
    result = threadId

elif defined(netbsd):
  proc lwp_self(): int32 {.importc: "_lwp_self", header: "<lwp.h>".}

  proc getThreadId*(): int =
    ## Gets the ID of the currently running thread.
    if threadId == 0:
      threadId = int(lwp_self())
    result = threadId

elif defined(freebsd):
  proc syscall(arg: cint, arg0: ptr cint): cint {.varargs, importc: "syscall", header: "<unistd.h>".}
  var SYS_thr_self {.importc:"SYS_thr_self", header:"<sys/syscall.h>".}: cint

  proc getThreadId*(): int =
    ## Gets the ID of the currently running thread.
    var tid = 0.cint
    if threadId == 0:
      discard syscall(SYS_thr_self, addr tid)
      threadId = tid
    result = threadId

elif defined(macosx):
  proc syscall(arg: cint): cint {.varargs, importc: "syscall", header: "<unistd.h>".}
  var SYS_thread_selfid {.importc:"SYS_thread_selfid", header:"<sys/syscall.h>".}: cint

  proc getThreadId*(): int =
    ## Gets the ID of the currently running thread.
    if threadId == 0:
      threadId = int(syscall(SYS_thread_selfid))
    result = threadId

elif defined(solaris):
  type thread_t {.importc: "thread_t", header: "<thread.h>".} = distinct int
  proc thr_self(): thread_t {.importc, header: "<thread.h>".}

  proc getThreadId*(): int =
    ## Gets the ID of the currently running thread.
    if threadId == 0:
      threadId = int(thr_self())
    result = threadId

elif defined(haiku):
  type thr_id {.importc: "thread_id", header: "<OS.h>".} = distinct int32
  proc find_thread(name: cstring): thr_id {.importc, header: "<OS.h>".}

  proc getThreadId*(): int =
    ## Gets the ID of the currently running thread.
    if threadId == 0:
      threadId = int(find_thread(nil))
    result = threadId
