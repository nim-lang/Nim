#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Thread support for Nimrod. **Note**: This is part of the system module.
## Do not import it directly. To active thread support you need to compile
## with the ``--threads:on`` command line switch.
##
## Nimrod's memory model for threads is quite different from other common 
## programming languages (C, Pascal): Each thread has its own
## (garbage collected) heap and sharing of memory is restricted. This helps
## to prevent race conditions and improves efficiency. See the manual for
## details of this memory model.
##
## Example:
##
## .. code-block:: nimrod
##
##  var
##    thr: array [0..4, TThread[tuple[a,b: int]]]
##    L: TLock
##  
##  proc threadFunc(interval: tuple[a,b: int]) {.procvar.} = 
##    for i in interval.a..interval.b: 
##      Acquire(L) # lock stdout
##      echo i
##      Release(L)
##
##  InitLock(L)
##
##  for i in 0..high(thr):
##    createThread(thr[i], threadFunc, (i*10, i*10+5))
##  joinThreads(thr)
  
const
  maxRegisters = 256 # don't think there is an arch with more registers
  maxLocksPerThread* = 10 ## max number of locks a thread can hold
                          ## at the same time

when defined(Windows):
  type
    TSysLock {.final, pure.} = object # CRITICAL_SECTION in WinApi
      DebugInfo: pointer
      LockCount: int32
      RecursionCount: int32
      OwningThread: int
      LockSemaphore: int
      Reserved: int32
          
  proc InitSysLock(L: var TSysLock) {.stdcall, noSideEffect,
    dynlib: "kernel32", importc: "InitializeCriticalSection".}
    ## Initializes the lock `L`.

  proc TryAcquireSysAux(L: var TSysLock): int32 {.stdcall, noSideEffect,
    dynlib: "kernel32", importc: "TryEnterCriticalSection".}
    ## Tries to acquire the lock `L`.
    
  proc TryAcquireSys(L: var TSysLock): bool {.inline.} = 
    result = TryAcquireSysAux(L) != 0'i32

  proc AcquireSys(L: var TSysLock) {.stdcall, noSideEffect,
    dynlib: "kernel32", importc: "EnterCriticalSection".}
    ## Acquires the lock `L`.
    
  proc ReleaseSys(L: var TSysLock) {.stdcall, noSideEffect,
    dynlib: "kernel32", importc: "LeaveCriticalSection".}
    ## Releases the lock `L`.

  type
    THandle = int
    TSysThread = THandle
    TWinThreadProc = proc (x: pointer): int32 {.stdcall.}

  proc CreateThread(lpThreadAttributes: Pointer, dwStackSize: int32,
                     lpStartAddress: TWinThreadProc, 
                     lpParameter: Pointer,
                     dwCreationFlags: int32, 
                     lpThreadId: var int32): TSysThread {.
    stdcall, dynlib: "kernel32", importc: "CreateThread".}

  proc winSuspendThread(hThread: TSysThread): int32 {.
    stdcall, dynlib: "kernel32", importc: "SuspendThread".}
      
  proc winResumeThread(hThread: TSysThread): int32 {.
    stdcall, dynlib: "kernel32", importc: "ResumeThread".}

  proc WaitForMultipleObjects(nCount: int32,
                              lpHandles: ptr TSysThread,
                              bWaitAll: int32,
                              dwMilliseconds: int32): int32 {.
    stdcall, dynlib: "kernel32", importc: "WaitForMultipleObjects".}

  proc WaitForSingleObject(hHandle: TSysThread, dwMilliseconds: int32): int32 {.
    stdcall, dynlib: "kernel32", importc: "WaitForSingleObject".}

  proc TerminateThread(hThread: TSysThread, dwExitCode: int32): int32 {.
    stdcall, dynlib: "kernel32", importc: "TerminateThread".}
    
  type
    TThreadVarSlot = distinct int32

  proc ThreadVarAlloc(): TThreadVarSlot {.
    importc: "TlsAlloc", stdcall, dynlib: "kernel32".}
  proc ThreadVarSetValue(dwTlsIndex: TThreadVarSlot, lpTlsValue: pointer) {.
    importc: "TlsSetValue", stdcall, dynlib: "kernel32".}
  proc ThreadVarGetValue(dwTlsIndex: TThreadVarSlot): pointer {.
    importc: "TlsGetValue", stdcall, dynlib: "kernel32".}
  
else:
  {.passL: "-pthread".}
  {.passC: "-pthread".}

  type
    TSysLock {.importc: "pthread_mutex_t", pure, final,
               header: "<sys/types.h>".} = object

  proc InitSysLock(L: var TSysLock, attr: pointer = nil) {.
    importc: "pthread_mutex_init", header: "<pthread.h>", noSideEffect.}

  proc AcquireSys(L: var TSysLock) {.noSideEffect,
    importc: "pthread_mutex_lock", header: "<pthread.h>".}
  proc TryAcquireSysAux(L: var TSysLock): cint {.noSideEffect,
    importc: "pthread_mutex_trylock", header: "<pthread.h>".}

  proc TryAcquireSys(L: var TSysLock): bool {.inline.} = 
    result = TryAcquireSysAux(L) == 0'i32

  proc ReleaseSys(L: var TSysLock) {.noSideEffect,
    importc: "pthread_mutex_unlock", header: "<pthread.h>".}

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
            a3: proc (x: pointer) {.noconv.}, 
            a4: pointer): cint {.importc: "pthread_create", 
            header: "<pthread.h>".}
  proc pthread_join(a1: TSysThread, a2: ptr pointer): cint {.
    importc, header: "<pthread.h>".}

  proc pthread_cancel(a1: TSysThread): cint {.
    importc: "pthread_cancel", header: "<pthread.h>".}

  proc AcquireSysTimeoutAux(L: var TSysLock, timeout: var Ttimespec): cint {.
    importc: "pthread_mutex_timedlock", header: "<time.h>".}

  proc AcquireSysTimeout(L: var TSysLock, msTimeout: int) {.inline.} =
    var a: Ttimespec
    a.tv_sec = msTimeout div 1000
    a.tv_nsec = (msTimeout mod 1000) * 1000
    var res = AcquireSysTimeoutAux(L, a)
    if res != 0'i32: raise newException(EResourceExhausted, $strerror(res))

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
  
  proc ThreadVarAlloc(): TThreadVarSlot {.inline.} =
    discard pthread_key_create(addr(result), nil)
  proc ThreadVarSetValue(s: TThreadVarSlot, value: pointer) {.inline.} =
    discard pthread_setspecific(s, value)
  proc ThreadVarGetValue(s: TThreadVarSlot): pointer {.inline.} =
    result = pthread_getspecific(s)

const emulatedThreadVars = defined(macosx)

when emulatedThreadVars:
  # the compiler generates this proc for us, so that we can get the size of
  # the thread local var block:
  proc NimThreadVarsSize(): int {.noconv, importc: "NimThreadVarsSize".}

proc ThreadVarsAlloc(size: int): pointer =
  result = c_malloc(size)
  zeroMem(result, size)
proc ThreadVarsDealloc(p: pointer) {.importc: "free", nodecl.}

type
  PGcThread = ptr TGcThread
  TGcThread {.pure.} = object
    sys: TSysThread
    next, prev: PGcThread
    stackBottom, stackTop, threadLocalStorage: pointer
    stackSize: int
    locksLen: int
    locks: array [0..MaxLocksPerThread-1, pointer]
    registers: array[0..maxRegisters-1, pointer] # register contents for GC

# XXX it'd be more efficient to not use a global variable for the 
# thread storage slot, but to rely on the implementation to assign slot 0
# for us... ;-)
var globalsSlot = ThreadVarAlloc()
#const globalsSlot = TThreadVarSlot(0)
#assert checkSlot.int == globalsSlot.int
  
proc ThisThread(): PGcThread {.compilerRtl, inl.} =
  result = cast[PGcThread](ThreadVarGetValue(globalsSlot))

proc GetThreadLocalVars(): pointer {.compilerRtl, inl.} =
  result = cast[PGcThread](ThreadVarGetValue(globalsSlot)).threadLocalStorage

# create for the main thread. Note: do not insert this data into the list
# of all threads; it's not to be stopped etc.
when not defined(useNimRtl):
  var mainThread: TGcThread
  
  ThreadVarSetValue(globalsSlot, addr(mainThread))
  when emulatedThreadVars:
    mainThread.threadLocalStorage = ThreadVarsAlloc(NimThreadVarsSize())

  initStackBottom()
  initGC()
  
  var heapLock: TSysLock
  InitSysLock(HeapLock)

  var
    threadList: PGcThread
    
  proc registerThread(t: PGcThread) = 
    # we need to use the GC global lock here!
    AcquireSys(HeapLock)
    t.prev = nil
    t.next = threadList
    if threadList != nil: 
      assert(threadList.prev == nil)
      threadList.prev = t
    threadList = t
    ReleaseSys(HeapLock)
        
  proc unregisterThread(t: PGcThread) =
    # we need to use the GC global lock here!
    AcquireSys(HeapLock)
    if t == threadList: threadList = t.next
    if t.next != nil: t.next.prev = t.prev
    if t.prev != nil: t.prev.next = t.next
    # so that a thread can be unregistered twice which might happen if the
    # code executes `destroyThread`:
    t.next = nil
    t.prev = nil
    ReleaseSys(HeapLock)
    
  # on UNIX, the GC uses ``SIGFREEZE`` to tell every thread to stop so that
  # the GC can examine the stacks?
  
  proc stopTheWord() =
    nil
    
# We jump through some hops here to ensure that Nimrod thread procs can have
# the Nimrod calling convention. This is needed because thread procs are 
# ``stdcall`` on Windows and ``noconv`` on UNIX. Alternative would be to just
# use ``stdcall`` since it is mapped to ``noconv`` on UNIX anyway. However, 
# the current approach will likely result in less problems later when we have
# GC'ed closures in Nimrod.

type
  TThread* {.pure, final.}[TParam] = object of TGcThread ## Nimrod thread.
    fn: proc (p: TParam)
    data: TParam

when not defined(boehmgc) and not hasSharedHeap:
  proc deallocOsPages()
  
template ThreadProcWrapperBody(closure: expr) =
  ThreadVarSetValue(globalsSlot, closure)
  var t = cast[ptr TThread[TParam]](closure)
  when emulatedThreadVars:
    t.threadLocalStorage = ThreadVarsAlloc(NimThreadVarsSize())
  when not defined(boehmgc) and not hasSharedHeap:
    # init the GC for this thread:
    setStackBottom(addr(t))
    initGC()
  t.stackBottom = addr(t)
  registerThread(t)
  try:
    t.fn(t.data)
  finally:
    # XXX shut-down is not executed when the thread is forced down!
    when emulatedThreadVars:
      ThreadVarsDealloc(t.threadLocalStorage)
    unregisterThread(t)
    when defined(deallocOsPages): deallocOsPages()
  
{.push stack_trace:off.}
when defined(windows):
  proc threadProcWrapper[TParam](closure: pointer): int32 {.stdcall.} = 
    ThreadProcWrapperBody(closure)
    # implicitely return 0
else:
  proc threadProcWrapper[TParam](closure: pointer) {.noconv.} = 
    ThreadProcWrapperBody(closure)
{.pop.}

proc joinThread*[TParam](t: TThread[TParam]) {.inline.} = 
  ## waits for the thread `t` to finish.
  when hostOS == "windows":
    discard WaitForSingleObject(t.sys, -1'i32)
  else:
    discard pthread_join(t.sys, nil)

proc joinThreads*[TParam](t: openArray[TThread[TParam]]) = 
  ## waits for every thread in `t` to finish.
  when hostOS == "windows":
    var a: array[0..255, TSysThread]
    assert a.len >= t.len
    for i in 0..t.high: a[i] = t[i].sys
    discard WaitForMultipleObjects(t.len, cast[ptr TSysThread](addr(a)), 1, -1)
  else:
    for i in 0..t.high: joinThread(t[i])

when false:
  # XXX a thread should really release its heap here somehow:
  proc destroyThread*[TParam](t: var TThread[TParam]) {.inline.} =
    ## forces the thread `t` to terminate. This is potentially dangerous if
    ## you don't have full control over `t` and its acquired resources.
    when hostOS == "windows":
      discard TerminateThread(t.sys, 1'i32)
    else:
      discard pthread_cancel(t.sys)
    unregisterThread(addr(t))

proc createThread*[TParam](t: var TThread[TParam], 
                           tp: proc (param: TParam), 
                           param: TParam,
                           stackSize = 1024*256*sizeof(int)) {.
                           magic: "CreateThread".} = 
  ## creates a new thread `t` and starts its execution. Entry point is the
  ## proc `tp`. `param` is passed to `tp`.
  t.data = param
  t.fn = tp
  t.stackSize = stackSize
  when hostOS == "windows":
    var dummyThreadId: int32
    t.sys = CreateThread(nil, stackSize, threadProcWrapper[TParam],
                         addr(t), 0'i32, dummyThreadId)
    if t.sys <= 0:
      raise newException(EResourceExhausted, "cannot create thread")
  else:
    var a: Tpthread_attr
    pthread_attr_init(a)
    pthread_attr_setstacksize(a, stackSize)
    if pthread_create(t.sys, a, threadProcWrapper[TParam], addr(t)) != 0:
      raise newException(EResourceExhausted, "cannot create thread")

# --------------------------- lock handling ----------------------------------

type
  TLock* = TSysLock ## Nimrod lock
  
const
  noDeadlocks = false # compileOption("deadlockPrevention")

when nodeadlocks:
  var
    deadlocksPrevented* = 0  ## counts the number of times a 
                             ## deadlock has been prevented

proc InitLock*(lock: var TLock) {.inline.} =
  ## Initializes the lock `lock`.
  InitSysLock(lock)

proc OrderedLocks(g: PGcThread): bool = 
  for i in 0 .. g.locksLen-2:
    if g.locks[i] >= g.locks[i+1]: return false
  result = true

proc TryAcquire*(lock: var TLock): bool {.inline.} = 
  ## Try to acquires the lock `lock`. Returns `true` on success.
  result = TryAcquireSys(lock)
  when noDeadlocks:
    if not result: return
    # we have to add it to the ordered list. Oh, and we might fail if
    # there is no space in the array left ...
    var g = ThisThread()
    if g.locksLen >= len(g.locks):
      ReleaseSys(lock)
      raise newException(EResourceExhausted, "cannot acquire additional lock")
    # find the position to add:
    var p = addr(lock)
    var L = g.locksLen-1
    var i = 0
    while i <= L:
      assert g.locks[i] != nil
      if g.locks[i] < p: inc(i) # in correct order
      elif g.locks[i] == p: return # thread already holds lock
      else:
        # do the crazy stuff here:
        while L >= i:
          g.locks[L+1] = g.locks[L]
          dec L
        g.locks[i] = p
        inc(g.locksLen)
        assert OrderedLocks(g)
        return
    # simply add to the end:
    g.locks[g.locksLen] = p
    inc(g.locksLen)
    assert OrderedLocks(g)

proc Acquire*(lock: var TLock) =
  ## Acquires the lock `lock`.
  when nodeadlocks:
    var g = ThisThread()
    var p = addr(lock)
    var L = g.locksLen-1
    var i = 0
    while i <= L:
      assert g.locks[i] != nil
      if g.locks[i] < p: inc(i) # in correct order
      elif g.locks[i] == p: return # thread already holds lock
      else:
        # do the crazy stuff here:
        if g.locksLen >= len(g.locks):
          raise newException(EResourceExhausted, 
              "cannot acquire additional lock")
        while L >= i:
          ReleaseSys(cast[ptr TSysLock](g.locks[L])[])
          g.locks[L+1] = g.locks[L]
          dec L
        # acquire the current lock:
        AcquireSys(lock)
        g.locks[i] = p
        inc(g.locksLen)
        # acquire old locks in proper order again:
        L = g.locksLen-1
        inc i
        while i <= L:
          AcquireSys(cast[ptr TSysLock](g.locks[i])[])
          inc(i)
        # DANGER: We can only modify this global var if we gained every lock!
        # NO! We need an atomic increment. Crap.
        discard system.atomicInc(deadlocksPrevented, 1)
        assert OrderedLocks(g)
        return
        
    # simply add to the end:
    if g.locksLen >= len(g.locks):
      raise newException(EResourceExhausted, "cannot acquire additional lock")
    AcquireSys(lock)
    g.locks[g.locksLen] = p
    inc(g.locksLen)
    assert OrderedLocks(g)
  else:
    AcquireSys(lock)
  
proc Release*(lock: var TLock) =
  ## Releases the lock `lock`.
  when nodeadlocks:
    var g = ThisThread()
    var p = addr(lock)
    var L = g.locksLen
    for i in countdown(L-1, 0):
      if g.locks[i] == p: 
        for j in i..L-2: g.locks[j] = g.locks[j+1]
        dec g.locksLen
        break
  ReleaseSys(lock)

