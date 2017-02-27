#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Thread support for Nim. **Note**: This is part of the system module.
## Do not import it directly. To activate thread support you need to compile
## with the ``--threads:on`` command line switch.
##
## Nim's memory model for threads is quite different from other common
## programming languages (C, Pascal): Each thread has its own
## (garbage collected) heap and sharing of memory is restricted. This helps
## to prevent race conditions and improves efficiency. See `the manual for
## details of this memory model <manual.html#threads>`_.
##
## Example:
##
## .. code-block:: Nim
##
##  import locks
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

when not declared(NimString):
  {.error: "You must not import this module explicitly".}

const
  maxRegisters = 256 # don't think there is an arch with more registers
  useStackMaskHack = false ## use the stack mask hack for better performance
  StackGuardSize = 4096
  ThreadStackMask = 1024*256*sizeof(int)-1
  ThreadStackSize = ThreadStackMask+1 - StackGuardSize

when defined(windows):
  type
    SysThread* = Handle
    WinThreadProc = proc (x: pointer): int32 {.stdcall.}
  {.deprecated: [TSysThread: SysThread].}

  proc createThread(lpThreadAttributes: pointer, dwStackSize: int32,
                     lpStartAddress: WinThreadProc,
                     lpParameter: pointer,
                     dwCreationFlags: int32,
                     lpThreadId: var int32): SysThread {.
    stdcall, dynlib: "kernel32", importc: "CreateThread".}

  proc winSuspendThread(hThread: SysThread): int32 {.
    stdcall, dynlib: "kernel32", importc: "SuspendThread".}

  proc winResumeThread(hThread: SysThread): int32 {.
    stdcall, dynlib: "kernel32", importc: "ResumeThread".}

  proc waitForMultipleObjects(nCount: int32,
                              lpHandles: ptr SysThread,
                              bWaitAll: int32,
                              dwMilliseconds: int32): int32 {.
    stdcall, dynlib: "kernel32", importc: "WaitForMultipleObjects".}

  proc terminateThread(hThread: SysThread, dwExitCode: int32): int32 {.
    stdcall, dynlib: "kernel32", importc: "TerminateThread".}

  proc getCurrentThreadId(): int32 {.
    stdcall, dynlib: "kernel32", importc: "GetCurrentThreadId".}

  type
    ThreadVarSlot = distinct int32

  when true:
    proc threadVarAlloc(): ThreadVarSlot {.
      importc: "TlsAlloc", stdcall, header: "<windows.h>".}
    proc threadVarSetValue(dwTlsIndex: ThreadVarSlot, lpTlsValue: pointer) {.
      importc: "TlsSetValue", stdcall, header: "<windows.h>".}
    proc tlsGetValue(dwTlsIndex: ThreadVarSlot): pointer {.
      importc: "TlsGetValue", stdcall, header: "<windows.h>".}

    proc getLastError(): uint32 {.
      importc: "GetLastError", stdcall, header: "<windows.h>".}
    proc setLastError(x: uint32) {.
      importc: "SetLastError", stdcall, header: "<windows.h>".}

    proc threadVarGetValue(dwTlsIndex: ThreadVarSlot): pointer =
      let realLastError = getLastError()
      result = tlsGetValue(dwTlsIndex)
      setLastError(realLastError)
  else:
    proc threadVarAlloc(): ThreadVarSlot {.
      importc: "TlsAlloc", stdcall, dynlib: "kernel32".}
    proc threadVarSetValue(dwTlsIndex: ThreadVarSlot, lpTlsValue: pointer) {.
      importc: "TlsSetValue", stdcall, dynlib: "kernel32".}
    proc threadVarGetValue(dwTlsIndex: ThreadVarSlot): pointer {.
      importc: "TlsGetValue", stdcall, dynlib: "kernel32".}

  proc setThreadAffinityMask(hThread: SysThread, dwThreadAffinityMask: uint) {.
    importc: "SetThreadAffinityMask", stdcall, header: "<windows.h>".}

  proc getThreadId*(): int =
    ## get the ID of the currently running thread.
    result = int(getCurrentThreadId())

else:
  when not defined(macosx):
    {.passL: "-pthread".}

  {.passC: "-pthread".}
  const
    schedh = "#define _GNU_SOURCE\n#include <sched.h>"
    pthreadh = "#define _GNU_SOURCE\n#include <pthread.h>"

  when not declared(Time):
    when defined(linux):
      type Time = clong
    else:
      type Time = int

  type
    SysThread* {.importc: "pthread_t", header: "<sys/types.h>",
                 final, pure.} = object
    Pthread_attr {.importc: "pthread_attr_t",
                     header: "<sys/types.h>", final, pure.} = object

    Timespec {.importc: "struct timespec",
                header: "<time.h>", final, pure.} = object
      tv_sec: Time
      tv_nsec: clong
  {.deprecated: [TSysThread: SysThread, Tpthread_attr: PThreadAttr,
                Ttimespec: Timespec].}

  proc pthread_attr_init(a1: var PthreadAttr) {.
    importc, header: pthreadh.}
  proc pthread_attr_setstacksize(a1: var PthreadAttr, a2: int) {.
    importc, header: pthreadh.}

  proc pthread_create(a1: var SysThread, a2: var PthreadAttr,
            a3: proc (x: pointer): pointer {.noconv.},
            a4: pointer): cint {.importc: "pthread_create",
            header: pthreadh.}
  proc pthread_join(a1: SysThread, a2: ptr pointer): cint {.
    importc, header: pthreadh.}

  proc pthread_cancel(a1: SysThread): cint {.
    importc: "pthread_cancel", header: pthreadh.}

  type
    ThreadVarSlot {.importc: "pthread_key_t", pure, final,
                   header: "<sys/types.h>".} = object
  {.deprecated: [TThreadVarSlot: ThreadVarSlot].}

  proc pthread_getspecific(a1: ThreadVarSlot): pointer {.
    importc: "pthread_getspecific", header: pthreadh.}
  proc pthread_key_create(a1: ptr ThreadVarSlot,
                          destruct: proc (x: pointer) {.noconv.}): int32 {.
    importc: "pthread_key_create", header: pthreadh.}
  proc pthread_key_delete(a1: ThreadVarSlot): int32 {.
    importc: "pthread_key_delete", header: pthreadh.}

  proc pthread_setspecific(a1: ThreadVarSlot, a2: pointer): int32 {.
    importc: "pthread_setspecific", header: pthreadh.}

  proc threadVarAlloc(): ThreadVarSlot {.inline.} =
    discard pthread_key_create(addr(result), nil)
  proc threadVarSetValue(s: ThreadVarSlot, value: pointer) {.inline.} =
    discard pthread_setspecific(s, value)
  proc threadVarGetValue(s: ThreadVarSlot): pointer {.inline.} =
    result = pthread_getspecific(s)

  when useStackMaskHack:
    proc pthread_attr_setstack(attr: var PthreadAttr, stackaddr: pointer,
                               size: int): cint {.
      importc: "pthread_attr_setstack", header: pthreadh.}

  type CpuSet {.importc: "cpu_set_t", header: schedh.} = object
  proc cpusetZero(s: var CpuSet) {.importc: "CPU_ZERO", header: schedh.}
  proc cpusetIncl(cpu: cint; s: var CpuSet) {.
    importc: "CPU_SET", header: schedh.}

  proc setAffinity(thread: SysThread; setsize: csize; s: var CpuSet) {.
    importc: "pthread_setaffinity_np", header: pthreadh.}

  when defined(linux):
    proc syscall(arg: clong): clong {.varargs, importc: "syscall", header: "<unistd.h>".}
    var NR_gettid {.importc: "__NR_gettid", header: "<sys/syscall.h>".}: int

    #type Pid {.importc: "pid_t", header: "<sys/types.h>".} = distinct int
    #proc gettid(): Pid {.importc, header: "<sys/types.h>".}

    proc getThreadId*(): int =
      ## get the ID of the currently running thread.
      result = int(syscall(NR_gettid))
  elif defined(macosx) or defined(bsd):
    proc pthread_threadid_np(y: pointer; x: var uint64): cint {.importc, header: "pthread.h".}

    proc getThreadId*(): int =
      ## get the ID of the currently running thread.
      var x: uint64
      result = pthread_threadid_np(nil, x)
      result = int(x)
  elif defined(solaris):
    # just a guess really:
    type thread_t {.importc: "thread_t", header: "<thread.h>".} = distinct int
    proc thr_self(): thread_t {.importc, header: "<thread.h>".}

    proc getThreadId*(): int =
      ## get the ID of the currently running thread.
      result = int(thr_self())


const
  emulatedThreadVars = compileOption("tlsEmulation")

when emulatedThreadVars:
  # the compiler generates this proc for us, so that we can get the size of
  # the thread local var block; we use this only for sanity checking though
  proc nimThreadVarsSize(): int {.noconv, importc: "NimThreadVarsSize".}

# we preallocate a fixed size for thread local storage, so that no heap
# allocations are needed. Currently less than 7K are used on a 64bit machine.
# We use ``float`` for proper alignment:
type
  ThreadLocalStorage = array[0..1_000, float]

  PGcThread = ptr GcThread
  GcThread {.pure, inheritable.} = object
    sys: SysThread
    when emulatedThreadVars and not useStackMaskHack:
      tls: ThreadLocalStorage
    else:
      nil
    when hasSharedHeap:
      next, prev: PGcThread
      stackBottom, stackTop: pointer
      stackSize: int
    else:
      nil
{.deprecated: [TThreadLocalStorage: ThreadLocalStorage, TGcThread: GcThread].}

when not defined(useNimRtl):
  when not useStackMaskHack:
    var mainThread: GcThread

#const globalsSlot = ThreadVarSlot(0)
#sysAssert checkSlot.int == globalsSlot.int

when emulatedThreadVars:
  # XXX it'd be more efficient to not use a global variable for the
  # thread storage slot, but to rely on the implementation to assign slot X
  # for us... ;-)
  var globalsSlot: ThreadVarSlot

  proc GetThreadLocalVars(): pointer {.compilerRtl, inl.} =
    result = addr(cast[PGcThread](threadVarGetValue(globalsSlot)).tls)

  proc initThreadVarsEmulation() {.compilerProc, inline.} =
    when not defined(useNimRtl):
      globalsSlot = threadVarAlloc()
      when declared(mainThread):
        threadVarSetValue(globalsSlot, addr(mainThread))

when useStackMaskHack:
  proc maskStackPointer(offset: int): pointer {.compilerRtl, inl.} =
    var x {.volatile.}: pointer
    x = addr(x)
    result = cast[pointer]((cast[int](x) and not ThreadStackMask) +%
      (0) +% offset)

# create for the main thread. Note: do not insert this data into the list
# of all threads; it's not to be stopped etc.
when not defined(useNimRtl):
  when not useStackMaskHack:
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



  when emulatedThreadVars:
    if nimThreadVarsSize() > sizeof(ThreadLocalStorage):
      echo "too large thread local storage size requested"
      quit 1

  when hasSharedHeap and not defined(boehmgc) and not defined(gogc) and not defined(nogc):
    var
      threadList: PGcThread

    proc registerThread(t: PGcThread) =
      # we need to use the GC global lock here!
      acquireSys(HeapLock)
      t.prev = nil
      t.next = threadList
      if threadList != nil:
        sysAssert(threadList.prev == nil, "threadList.prev == nil")
        threadList.prev = t
      threadList = t
      releaseSys(HeapLock)

    proc unregisterThread(t: PGcThread) =
      # we need to use the GC global lock here!
      acquireSys(HeapLock)
      if t == threadList: threadList = t.next
      if t.next != nil: t.next.prev = t.prev
      if t.prev != nil: t.prev.next = t.next
      # so that a thread can be unregistered twice which might happen if the
      # code executes `destroyThread`:
      t.next = nil
      t.prev = nil
      releaseSys(HeapLock)

    # on UNIX, the GC uses ``SIGFREEZE`` to tell every thread to stop so that
    # the GC can examine the stacks?
    proc stopTheWord() = discard

# We jump through some hops here to ensure that Nim thread procs can have
# the Nim calling convention. This is needed because thread procs are
# ``stdcall`` on Windows and ``noconv`` on UNIX. Alternative would be to just
# use ``stdcall`` since it is mapped to ``noconv`` on UNIX anyway.

type
  Thread* {.pure, final.}[TArg] =
      object of GcThread  ## Nim thread. A thread is a heavy object (~14K)
                          ## that **must not** be part of a message! Use
                          ## a ``ThreadId`` for that.
    when TArg is void:
      dataFn: proc () {.nimcall, gcsafe.}
    else:
      dataFn: proc (m: TArg) {.nimcall, gcsafe.}
      data: TArg
  ThreadId*[TArg] = ptr Thread[TArg]  ## the current implementation uses
                                       ## a pointer as a thread ID.
{.deprecated: [TThread: Thread, TThreadId: ThreadId].}

var
  threadDestructionHandlers {.rtlThreadVar.}: seq[proc () {.closure, gcsafe.}]

proc onThreadDestruction*(handler: proc () {.closure, gcsafe.}) =
  ## Registers a *thread local* handler that is called at the thread's
  ## destruction.
  ## A thread is destructed when the ``.thread`` proc returns
  ## normally or when it raises an exception. Note that unhandled exceptions
  ## in a thread nevertheless cause the whole process to die.
  if threadDestructionHandlers.isNil:
    threadDestructionHandlers = @[]
  threadDestructionHandlers.add handler

template afterThreadRuns() =
  for i in countdown(threadDestructionHandlers.len-1, 0):
    threadDestructionHandlers[i]()

when not defined(boehmgc) and not hasSharedHeap and not defined(gogc) and not defined(gcstack):
  proc deallocOsPages()

when defined(boehmgc):
  type GCStackBaseProc = proc(sb: pointer, t: pointer) {.noconv.}
  proc boehmGC_call_with_stack_base(sbp: GCStackBaseProc, p: pointer)
    {.importc: "GC_call_with_stack_base", boehmGC.}
  proc boehmGC_register_my_thread(sb: pointer)
    {.importc: "GC_register_my_thread", boehmGC.}
  proc boehmGC_unregister_my_thread()
    {.importc: "GC_unregister_my_thread", boehmGC.}

  proc threadProcWrapDispatch[TArg](sb: pointer, thrd: pointer) {.noconv.} =
    boehmGC_register_my_thread(sb)
    try:
      let thrd = cast[ptr Thread[TArg]](thrd)
      when TArg is void:
        thrd.dataFn()
      else:
        thrd.dataFn(thrd.data)
    finally:
      afterThreadRuns()
    boehmGC_unregister_my_thread()
else:
  proc threadProcWrapDispatch[TArg](thrd: ptr Thread[TArg]) =
    try:
      when TArg is void:
        thrd.dataFn()
      else:
        var x: TArg
        deepCopy(x, thrd.data)
        thrd.dataFn(x)
    finally:
      afterThreadRuns()

proc threadProcWrapStackFrame[TArg](thrd: ptr Thread[TArg]) =
  when defined(boehmgc):
    boehmGC_call_with_stack_base(threadProcWrapDispatch[TArg], thrd)
  elif not defined(nogc) and not defined(gogc) and not defined(gcstack):
    var p {.volatile.}: proc(a: ptr Thread[TArg]) {.nimcall.} =
      threadProcWrapDispatch[TArg]
    when not hasSharedHeap:
      # init the GC for refc/markandsweep
      setStackBottom(addr(p))
      initGC()
      when declared(threadType):
        threadType = ThreadType.NimThread
    when declared(registerThread):
      thrd.stackBottom = addr(thrd)
      registerThread(thrd)
    p(thrd)
    when declared(registerThread): unregisterThread(thrd)
    when declared(deallocOsPages): deallocOsPages()
  else:
    threadProcWrapDispatch(thrd)

template threadProcWrapperBody(closure: expr) {.immediate.} =
  when declared(globalsSlot): threadVarSetValue(globalsSlot, closure)
  when declared(initAllocator):
    initAllocator()
  var thrd = cast[ptr Thread[TArg]](closure)
  threadProcWrapStackFrame(thrd)
  # Since an unhandled exception terminates the whole process (!), there is
  # no need for a ``try finally`` here, nor would it be correct: The current
  # exception is tried to be re-raised by the code-gen after the ``finally``!
  # However this is doomed to fail, because we already unmapped every heap
  # page!

  # mark as not running anymore:
  thrd.dataFn = nil

{.push stack_trace:off.}
when defined(windows):
  proc threadProcWrapper[TArg](closure: pointer): int32 {.stdcall.} =
    threadProcWrapperBody(closure)
    # implicitly return 0
else:
  proc threadProcWrapper[TArg](closure: pointer): pointer {.noconv.} =
    threadProcWrapperBody(closure)
{.pop.}

proc running*[TArg](t: Thread[TArg]): bool {.inline.} =
  ## returns true if `t` is running.
  result = t.dataFn != nil

proc handle*[TArg](t: Thread[TArg]): SysThread {.inline.} =
  ## returns the thread handle of `t`.
  result = t.sys

when hostOS == "windows":
  proc joinThread*[TArg](t: Thread[TArg]) {.inline.} =
    ## waits for the thread `t` to finish.
    discard waitForSingleObject(t.sys, -1'i32)

  proc joinThreads*[TArg](t: varargs[Thread[TArg]]) =
    ## waits for every thread in `t` to finish.
    var a: array[0..255, SysThread]
    sysAssert a.len >= t.len, "a.len >= t.len"
    for i in 0..t.high: a[i] = t[i].sys
    discard waitForMultipleObjects(t.len.int32,
                                   cast[ptr SysThread](addr(a)), 1, -1)

else:
  proc joinThread*[TArg](t: Thread[TArg]) {.inline.} =
    ## waits for the thread `t` to finish.
    discard pthread_join(t.sys, nil)

  proc joinThreads*[TArg](t: varargs[Thread[TArg]]) =
    ## waits for every thread in `t` to finish.
    for i in 0..t.high: joinThread(t[i])

when false:
  # XXX a thread should really release its heap here somehow:
  proc destroyThread*[TArg](t: var Thread[TArg]) =
    ## forces the thread `t` to terminate. This is potentially dangerous if
    ## you don't have full control over `t` and its acquired resources.
    when hostOS == "windows":
      discard TerminateThread(t.sys, 1'i32)
    else:
      discard pthread_cancel(t.sys)
    when declared(registerThread): unregisterThread(addr(t))
    t.dataFn = nil

when hostOS == "windows":
  proc createThread*[TArg](t: var Thread[TArg],
                           tp: proc (arg: TArg) {.thread, nimcall.},
                           param: TArg) =
    ## creates a new thread `t` and starts its execution. Entry point is the
    ## proc `tp`. `param` is passed to `tp`. `TArg` can be ``void`` if you
    ## don't need to pass any data to the thread.
    when TArg isnot void: t.data = param
    t.dataFn = tp
    when hasSharedHeap: t.stackSize = ThreadStackSize
    var dummyThreadId: int32
    t.sys = createThread(nil, ThreadStackSize, threadProcWrapper[TArg],
                         addr(t), 0'i32, dummyThreadId)
    if t.sys <= 0:
      raise newException(ResourceExhaustedError, "cannot create thread")

  proc pinToCpu*[Arg](t: var Thread[Arg]; cpu: Natural) =
    ## pins a thread to a `CPU`:idx:. In other words sets a
    ## thread's `affinity`:idx:. If you don't know what this means, you
    ## shouldn't use this proc.
    setThreadAffinityMask(t.sys, uint(1 shl cpu))

else:
  proc createThread*[TArg](t: var Thread[TArg],
                           tp: proc (arg: TArg) {.thread, nimcall.},
                           param: TArg) =
    ## creates a new thread `t` and starts its execution. Entry point is the
    ## proc `tp`. `param` is passed to `tp`. `TArg` can be ``void`` if you
    ## don't need to pass any data to the thread.
    when TArg isnot void: t.data = param
    t.dataFn = tp
    when hasSharedHeap: t.stackSize = ThreadStackSize
    var a {.noinit.}: PthreadAttr
    pthread_attr_init(a)
    pthread_attr_setstacksize(a, ThreadStackSize)
    if pthread_create(t.sys, a, threadProcWrapper[TArg], addr(t)) != 0:
      raise newException(ResourceExhaustedError, "cannot create thread")

  proc pinToCpu*[Arg](t: var Thread[Arg]; cpu: Natural) =
    ## pins a thread to a `CPU`:idx:. In other words sets a
    ## thread's `affinity`:idx:. If you don't know what this means, you
    ## shouldn't use this proc.
    when not defined(macosx):
      var s {.noinit.}: CpuSet
      cpusetZero(s)
      cpusetIncl(cpu.cint, s)
      setAffinity(t.sys, sizeof(s), s)

proc createThread*(t: var Thread[void], tp: proc () {.thread, nimcall.}) =
  createThread[void](t, tp)

proc threadId*[TArg](t: var Thread[TArg]): ThreadId[TArg] {.inline.} =
  ## returns the thread ID of `t`.
  result = addr(t)

when false:
  proc mainThreadId*[TArg](): ThreadId[TArg] =
    ## returns the thread ID of the main thread.
    result = cast[ThreadId[TArg]](addr(mainThread))

when useStackMaskHack:
  proc runMain(tp: proc () {.thread.}) {.compilerproc.} =
    var mainThread: Thread[pointer]
    createThread(mainThread, tp)
    joinThread(mainThread)
