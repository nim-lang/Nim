#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Basic thread support for Nimrod. Note that Nimrod's default GC is still
## single-threaded. This means that either your threads should not allocate
## GC'ed memory, or you should compile with ``--gc:none`` or ``--gc:boehm``.
##
## Example:
##
## .. code-block:: nimrod
##
##  var
##    thr: array [0..4, TThread]
##    L: TLock
##  
##  proc threadFunc(c: pointer) {.procvar.} = 
##    for i in 0..9: 
##      Aquire(L) # lock stdout
##      echo i
##      Release(L)
##
##  InitLock(L)
##
##  for i in 0..high(thr):
##    createThread(thr[i], threadFunc)
##  for i in 0..high(thr):
##    joinThread(thr[i])


# We jump through some hops here to ensure that Nimrod thread procs can have
# the Nimrod calling convention. This is needed because thread procs are 
# ``stdcall`` on Windows and ``noconv`` on UNIX. Alternative would be to just
# use ``stdcall`` since it is mapped to ``noconv`` on UNIX anyway. However, 
# the current approach will likely result in less problems later when we have
# GC'ed closures in Nimrod.

type
  TThreadProc* = proc (closure: pointer) ## Standard Nimrod thread proc.
  TThreadProcClosure {.pure, final.} = object
    fn: TThreadProc
    data: pointer
  
when defined(Windows):
  type 
    THandle = int
    TSysThread = THandle
    TSysLock {.final, pure.} = object # CRITICAL_SECTION in WinApi
      DebugInfo: pointer
      LockCount: int32
      RecursionCount: int32
      OwningThread: int
      LockSemaphore: int
      Reserved: int32
      
    TWinThreadProc = proc (x: pointer): int32 {.stdcall.}
    
    TLock* = TSysLock ## Standard Nimrod Lock type.
  
  proc InitLock*(L: var TLock) {.stdcall,
    dynlib: "kernel32", importc: "InitializeCriticalSection".}
    ## Initializes the lock `L`.

  proc Aquire*(L: var TLock) {.stdcall,
    dynlib: "kernel32", importc: "EnterCriticalSection".}
    ## Aquires the lock `L`.
    
  proc Release*(L: var TLock) {.stdcall,
    dynlib: "kernel32", importc: "LeaveCriticalSection".}
    ## Releases the lock `L`.

  proc CreateThread(lpThreadAttributes: Pointer, dwStackSize: int32,
                     lpStartAddress: TWinThreadProc, 
                     lpParameter: Pointer,
                     dwCreationFlags: int32, lpThreadId: var int32): THandle {.
    stdcall, dynlib: "kernel32", importc: "CreateThread".}

  when false:
    proc winSuspendThread(hThread: TSysThread): int32 {.
      stdcall, dynlib: "kernel32", importc: "SuspendThread".}
      
    proc winResumeThread(hThread: TSysThread): int32 {.
      stdcall, dynlib: "kernel32", importc: "ResumeThread".}

    proc WaitForMultipleObjects(nCount: int32,
                                lpHandles: ptr array[0..10, THandle],
                                bWaitAll: int32,
                                dwMilliseconds: int32): int32 {.
      stdcall, dynlib: "kernel32", importc: "WaitForMultipleObjects".}

  proc WaitForSingleObject(hHandle: THANDLE, dwMilliseconds: int32): int32 {.
      stdcall, dynlib: "kernel32", importc: "WaitForSingleObject".}

  proc TerminateThread(hThread: THandle, dwExitCode: int32): int32 {.
    stdcall, dynlib: "kernel32", importc: "TerminateThread".}

  proc threadProcWrapper(closure: pointer): int32 {.stdcall.} = 
    var c = cast[ptr TThreadProcClosure](closure)
    c.fn(c.data)
    # implicitely return 0

else:
  type
    TSysLock {.importc: "pthread_mutex_t", header: "<sys/types.h>".} = int
    TSysThread {.importc: "pthread_t", header: "<sys/types.h>".} = int
    
    TLock* = TSysLock

  proc InitLockAux(L: var TSysLock, attr: pointer = nil) {.
    importc: "pthread_mutex_init", header: "<pthread.h>".}

  proc InitLock*(L: var TLock) {.inline.} = 
    InitLockAux(L)
  proc Aquire*(L: var TLock) {.
    importc: "pthread_mutex_lock", header: "<pthread.h>".}
  proc Release*(L: var TLock) {.
    importc: "pthread_mutex_unlock", header: "<pthread.h>".}

  proc pthread_create(a1: var TSysThread, a2: ptr int,
            a3: proc (x: pointer) {.noconv.}, 
            a4: pointer): cint {.importc: "pthread_create", 
            header: "<pthread.h>".}
  proc pthread_join(a1: TSysThread, a2: ptr pointer): cint {.
    importc, header: "<pthread.h>".}

  proc pthread_cancel(a1: TSysThread): cint {.
    importc: "pthread_cancel", header: "<pthread.h>".}

  proc threadProcWrapper(closure: pointer) {.noconv.} = 
    var c = cast[ptr TThreadProcClosure](closure)
    c.fn(c.data)

  {.passL: "-pthread".}
  {.passC: "-pthread".}

type
  TThread* = object of TObject ## Nimrod thread.
    sys: TSysThread
    c: TThreadProcClosure

  
proc createThread*(t: var TThread, tp: TThreadProc, 
                   closure: pointer = nil) = 
  ## creates a new thread `t` and starts its execution. Entry point is the
  ## proc `tp`. `closure` is passed to `tp`.
  t.c.data = closure
  t.c.fn = tp
  when defined(windows):
    var dummyThreadId: int32
    t.sys = CreateThread(nil, 0'i32, threadProcWrapper, addr(t.c), 0'i32, 
                         dummyThreadId)
  else: 
    discard pthread_create(t.sys, nil, threadProcWrapper, addr(t.c))

proc joinThread*(t: TThread) = 
  ## waits for the thread `t` until it has terminated.
  when defined(windows):
    discard WaitForSingleObject(t.sys, -1'i32)
  else:
    discard pthread_join(t.sys, nil)

proc destroyThread*(t: var TThread) =
  ## forces the thread `t` to terminate. This is potentially dangerous if
  ## you don't have full control over `t` and its aquired ressources.
  when defined(windows):
    discard TerminateThread(t.sys, 1'i32)
  else:
    discard pthread_cancel(t.sys)

