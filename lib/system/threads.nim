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
##    thr: array [0..4, TThread[tuple[a,b: int]]]
##    L: TLock
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
    TSysThread = THandle
    TWinThreadProc = proc (x: pointer): int32 {.stdcall.}

  proc createThread(lpThreadAttributes: pointer, dwStackSize: int32,
                     lpStartAddress: TWinThreadProc, 
                     lpParameter: pointer,
                     dwCreationFlags: int32, 
                     lpThreadId: var int32): TSysThread {.
    stdcall, dynlib: "kernel32", importc: "CreateThread".}

  proc winSuspendThread(hThread: TSysThread): int32 {.
    stdcall, dynlib: "kernel32", importc: "SuspendThread".}
      
  proc winResumeThread(hThread: TSysThread): int32 {.
    stdcall, dynlib: "kernel32", importc: "ResumeThread".}

  proc waitForMultipleObjects(nCount: int32,
                              lpHandles: ptr TSysThread,
                              bWaitAll: int32,
                              dwMilliseconds: int32): int32 {.
    stdcall, dynlib: "kernel32", importc: "WaitForMultipleObjects".}

  proc terminateThread(hThread: TSysThread, dwExitCode: int32): int32 {.
    stdcall, dynlib: "kernel32", importc: "TerminateThread".}
    
  type
    TThreadVarSlot = distinct int32

  when true:
    proc threadVarAlloc(): TThreadVarSlot {.
      importc: "TlsAlloc", stdcall, header: "<windows.h>".}
    proc threadVarSetValue(dwTlsIndex: TThreadVarSlot, lpTlsValue: pointer) {.
      importc: "TlsSetValue", stdcall, header: "<windows.h>".}
    proc tlsGetValue(dwTlsIndex: TThreadVarSlot): pointer {.
      importc: "TlsGetValue", stdcall, header: "<windows.h>".}

    proc getLastError(): uint32 {.
      importc: "GetLastError", stdcall, header: "<windows.h>".}
    proc setLastError(x: uint32) {.
      importc: "SetLastError", stdcall, header: "<windows.h>".}

    proc threadVarGetValue(dwTlsIndex: TThreadVarSlot): pointer =
      let realLastError = getLastError()
      result = tlsGetValue(dwTlsIndex)
      setLastError(realLastError)
  else:
    proc threadVarAlloc(): TThreadVarSlot {.
      importc: "TlsAlloc", stdcall, dynlib: "kernel32".}
    proc threadVarSetValue(dwTlsIndex: TThreadVarSlot, lpTlsValue: pointer) {.
      importc: "TlsSetValue", stdcall, dynlib: "kernel32".}
    proc threadVarGetValue(dwTlsIndex: TThreadVarSlot): pointer {.
      importc: "TlsGetValue", stdcall, dynlib: "kernel32".}
  
else:
  when not defined(macosx):
    {.passL: "-pthread".}

  {.passC: "-pthread".}

  type
    TSysThread {.importc: "pthread_t", header: "<sys/types.h>",
                 final, pure.} = object
    Tpthread_attr {.importc: "pthread_attr_t",
                     header: "<sys/types.h>", final, pure.} = object
                 
    Ttimespec {.importc: "struct timespec",
                header: "<time.h>", final, pure.} = object
      tv_sec: int
      tv_nsec: int

  proc pthread_attr_init(a1: var TPthread_attr) {.
    importc, header: "<pthread.h>".}
  proc pthread_attr_setstacksize(a1: var TPthread_attr, a2: int) {.
    importc, header: "<pthread.h>".}

  proc pthread_create(a1: var TSysThread, a2: var TPthread_attr,
            a3: proc (x: pointer): pointer {.noconv.}, 
            a4: pointer): cint {.importc: "pthread_create", 
            header: "<pthread.h>".}
  proc pthread_join(a1: TSysThread, a2: ptr pointer): cint {.
    importc, header: "<pthread.h>".}

  proc pthread_cancel(a1: TSysThread): cint {.
    importc: "pthread_cancel", header: "<pthread.h>".}

  type
    TThreadVarSlot {.importc: "pthread_key_t", pure, final,
                   header: "<sys/types.h>".} = object

  proc pthread_getspecific(a1: TThreadVarSlot): pointer {.
    importc: "pthread_getspecific", header: "<pthread.h>".}
  proc pthread_key_create(a1: ptr TThreadVarSlot, 
                          destruct: proc (x: pointer) {.noconv.}): int32 {.
    importc: "pthread_key_create", header: "<pthread.h>".}
  proc pthread_key_delete(a1: TThreadVarSlot): int32 {.
    importc: "pthread_key_delete", header: "<pthread.h>".}

  proc pthread_setspecific(a1: TThreadVarSlot, a2: pointer): int32 {.
    importc: "pthread_setspecific", header: "<pthread.h>".}
  
  proc threadVarAlloc(): TThreadVarSlot {.inline.} =
    discard pthread_key_create(addr(result), nil)
  proc threadVarSetValue(s: TThreadVarSlot, value: pointer) {.inline.} =
    discard pthread_setspecific(s, value)
  proc threadVarGetValue(s: TThreadVarSlot): pointer {.inline.} =
    result = pthread_getspecific(s)

  when useStackMaskHack:
    proc pthread_attr_setstack(attr: var TPthread_attr, stackaddr: pointer,
                               size: int): cint {.
      importc: "pthread_attr_setstack", header: "<pthread.h>".}

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
  TThreadLocalStorage = array [0..1_000, float]

  PGcThread = ptr TGcThread
  TGcThread {.pure, inheritable.} = object
    sys: TSysThread
    when emulatedThreadVars and not useStackMaskHack:
      tls: TThreadLocalStorage
    else:
      nil
    when hasSharedHeap:
      next, prev: PGcThread
      stackBottom, stackTop: pointer
      stackSize: int
    else:
      nil

# XXX it'd be more efficient to not use a global variable for the 
# thread storage slot, but to rely on the implementation to assign slot X
# for us... ;-)
var globalsSlot: TThreadVarSlot

when not defined(useNimRtl):
  when not useStackMaskHack:
    var mainThread: TGcThread

proc initThreadVarsEmulation() {.compilerProc, inline.} =
  when not defined(useNimRtl):
    globalsSlot = threadVarAlloc()
    when declared(mainThread):
      threadVarSetValue(globalsSlot, addr(mainThread))

#const globalsSlot = TThreadVarSlot(0)
#sysAssert checkSlot.int == globalsSlot.int

when emulatedThreadVars:
  proc GetThreadLocalVars(): pointer {.compilerRtl, inl.} =
    result = addr(cast[PGcThread](threadVarGetValue(globalsSlot)).tls)

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
    initGC()
    
  when emulatedThreadVars:
    if nimThreadVarsSize() > sizeof(TThreadLocalStorage):
      echo "too large thread local storage size requested"
      quit 1
  
  when hasSharedHeap and not defined(boehmgc) and not defined(nogc):
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
  TThread* {.pure, final.}[TArg] =
      object of TGcThread ## Nim thread. A thread is a heavy object (~14K)
                          ## that **must not** be part of a message! Use
                          ## a ``TThreadId`` for that.
    when TArg is void:
      dataFn: proc () {.nimcall, gcsafe.}
    else:
      dataFn: proc (m: TArg) {.nimcall, gcsafe.}
      data: TArg
  TThreadId*[TArg] = ptr TThread[TArg] ## the current implementation uses
                                       ## a pointer as a thread ID.

when not defined(boehmgc) and not hasSharedHeap:
  proc deallocOsPages()

template threadProcWrapperBody(closure: expr) {.immediate.} =
  when declared(globalsSlot): threadVarSetValue(globalsSlot, closure)
  var t = cast[ptr TThread[TArg]](closure)
  when useStackMaskHack:
    var tls: TThreadLocalStorage
  when not defined(boehmgc) and not defined(nogc) and not hasSharedHeap:
    # init the GC for this thread:
    setStackBottom(addr(t))
    initGC()
  when declared(registerThread):
    t.stackBottom = addr(t)
    registerThread(t)
  when TArg is void: t.dataFn()
  else: t.dataFn(t.data)
  when declared(registerThread): unregisterThread(t)
  when declared(deallocOsPages): deallocOsPages()
  # Since an unhandled exception terminates the whole process (!), there is
  # no need for a ``try finally`` here, nor would it be correct: The current
  # exception is tried to be re-raised by the code-gen after the ``finally``!
  # However this is doomed to fail, because we already unmapped every heap
  # page!
  
  # mark as not running anymore:
  t.dataFn = nil
  
{.push stack_trace:off.}
when defined(windows):
  proc threadProcWrapper[TArg](closure: pointer): int32 {.stdcall.} = 
    threadProcWrapperBody(closure)
    # implicitly return 0
else:
  proc threadProcWrapper[TArg](closure: pointer): pointer {.noconv.} = 
    threadProcWrapperBody(closure)
{.pop.}

proc running*[TArg](t: TThread[TArg]): bool {.inline.} = 
  ## returns true if `t` is running.
  result = t.dataFn != nil

when hostOS == "windows":
  proc joinThread*[TArg](t: TThread[TArg]) {.inline.} = 
    ## waits for the thread `t` to finish.
    discard waitForSingleObject(t.sys, -1'i32)

  proc joinThreads*[TArg](t: varargs[TThread[TArg]]) = 
    ## waits for every thread in `t` to finish.
    var a: array[0..255, TSysThread]
    sysAssert a.len >= t.len, "a.len >= t.len"
    for i in 0..t.high: a[i] = t[i].sys
    discard waitForMultipleObjects(t.len.int32,
                                   cast[ptr TSysThread](addr(a)), 1, -1)

else:
  proc joinThread*[TArg](t: TThread[TArg]) {.inline.} =
    ## waits for the thread `t` to finish.
    discard pthread_join(t.sys, nil)

  proc joinThreads*[TArg](t: varargs[TThread[TArg]]) =
    ## waits for every thread in `t` to finish.
    for i in 0..t.high: joinThread(t[i])

when false:
  # XXX a thread should really release its heap here somehow:
  proc destroyThread*[TArg](t: var TThread[TArg]) =
    ## forces the thread `t` to terminate. This is potentially dangerous if
    ## you don't have full control over `t` and its acquired resources.
    when hostOS == "windows":
      discard TerminateThread(t.sys, 1'i32)
    else:
      discard pthread_cancel(t.sys)
    when declared(registerThread): unregisterThread(addr(t))
    t.dataFn = nil

when hostOS == "windows":
  proc createThread*[TArg](t: var TThread[TArg],
                           tp: proc (arg: TArg) {.thread.}, 
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
else:
  proc createThread*[TArg](t: var TThread[TArg], 
                           tp: proc (arg: TArg) {.thread.}, 
                           param: TArg) =
    ## creates a new thread `t` and starts its execution. Entry point is the
    ## proc `tp`. `param` is passed to `tp`. `TArg` can be ``void`` if you
    ## don't need to pass any data to the thread.
    when TArg isnot void: t.data = param
    t.dataFn = tp
    when hasSharedHeap: t.stackSize = ThreadStackSize
    var a {.noinit.}: Tpthread_attr
    pthread_attr_init(a)
    pthread_attr_setstacksize(a, ThreadStackSize)
    if pthread_create(t.sys, a, threadProcWrapper[TArg], addr(t)) != 0:
      raise newException(ResourceExhaustedError, "cannot create thread")

proc threadId*[TArg](t: var TThread[TArg]): TThreadId[TArg] {.inline.} =
  ## returns the thread ID of `t`.
  result = addr(t)

proc myThreadId*[TArg](): TThreadId[TArg] =
  ## returns the thread ID of the thread that calls this proc. This is unsafe
  ## because the type ``TArg`` is not checked for consistency!
  result = cast[TThreadId[TArg]](threadVarGetValue(globalsSlot))

when false:
  proc mainThreadId*[TArg](): TThreadId[TArg] =
    ## returns the thread ID of the main thread.
    result = cast[TThreadId[TArg]](addr(mainThread))

when useStackMaskHack:
  proc runMain(tp: proc () {.thread.}) {.compilerproc.} =
    var mainThread: TThread[pointer]
    createThread(mainThread, tp)
    joinThread(mainThread)

