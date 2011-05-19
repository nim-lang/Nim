#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Basic thread support for Nimrod. Note that Nimrod's default GC is still
## single-threaded. This means that you MUST turn off the GC while multiple
## threads are executing that allocate GC'ed memory. The alternative is to
## compile with ``--gc:none`` or ``--gc:boehm``.
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
##      Aquire(L) # lock stdout
##      echo i
##      Release(L)
##
##  InitLock(L)
##
##  GC_disable() # native GC does not support multiple thready yet :-(
##  for i in 0..high(thr):
##    createThread(thr[i], threadFunc, (i*10, i*10+5))
##  for i in 0..high(thr):
##    joinThread(thr[i])
##  GC_enable()

when not compileOption("threads"):
  {.error: "Thread support requires ``--threads:on`` commandline switch".}

when not defined(boehmgc) and not defined(nogc) and false:
  {.error: "Thread support requires --gc:boehm or --gc:none".}
  
include "lib/system/systhread"

# We jump through some hops here to ensure that Nimrod thread procs can have
# the Nimrod calling convention. This is needed because thread procs are 
# ``stdcall`` on Windows and ``noconv`` on UNIX. Alternative would be to just
# use ``stdcall`` since it is mapped to ``noconv`` on UNIX anyway. However, 
# the current approach will likely result in less problems later when we have
# GC'ed closures in Nimrod.

type
  TThreadProcClosure {.pure, final.}[TParam] = object
    fn: proc (p: TParam)
    data: TParam
    threadLocalStorage: pointer
  
when defined(windows):
  type
    THandle = int
    TSysThread = THandle
    TWinThreadProc = proc (x: pointer): int32 {.stdcall.}

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

  {.push stack_trace:off.}
  proc threadProcWrapper[TParam](closure: pointer): int32 {.stdcall.} = 
    var c = cast[ptr TThreadProcClosure[TParam]](closure)
    SetThreadLocalStorage(c.threadLocalStorage)
    c.fn(c.data)
    # implicitely return 0
  {.pop.}

else:
  type
    TSysThread {.importc: "pthread_t", header: "<sys/types.h>".} = int
    Ttimespec {.importc: "struct timespec",
                header: "<time.h>", final, pure.} = object
      tv_sec: int
      tv_nsec: int

  proc pthread_create(a1: var TSysThread, a2: ptr int,
            a3: proc (x: pointer) {.noconv.}, 
            a4: pointer): cint {.importc: "pthread_create", 
            header: "<pthread.h>".}
  proc pthread_join(a1: TSysThread, a2: ptr pointer): cint {.
    importc, header: "<pthread.h>".}

  proc pthread_cancel(a1: TSysThread): cint {.
    importc: "pthread_cancel", header: "<pthread.h>".}

  proc AquireSysTimeoutAux(L: var TSysLock, timeout: var Ttimespec): cint {.
    importc: "pthread_mutex_timedlock", header: "<time.h>".}

  proc AquireSysTimeout(L: var TSysLock, msTimeout: int) {.inline.} =
    var a: Ttimespec
    a.tv_sec = msTimeout div 1000
    a.tv_nsec = (msTimeout mod 1000) * 1000
    var res = AquireSysTimeoutAux(L, a)
    if res != 0'i32:
      raise newException(EResourceExhausted, $strerror(res))

  {.push stack_trace:off.}
  proc threadProcWrapper[TParam](closure: pointer) {.noconv.} = 
    var c = cast[ptr TThreadProcClosure[TParam]](closure)
    SetThreadLocalStorage(c.threadLocalStorage)
    c.fn(c.data)
  {.pop.}


const
  noDeadlocks = false # compileOption("deadlockPrevention")

type
  TLock* = TSysLock
  TThread* {.pure, final.}[TParam] = object ## Nimrod thread.
    sys: TSysThread
    c: TThreadProcClosure[TParam]

when nodeadlocks:
  var
    deadlocksPrevented* = 0  ## counts the number of times a 
                             ## deadlock has been prevented

proc InitLock*(lock: var TLock) {.inline.} =
  ## Initializes the lock `lock`.
  InitSysLock(lock)

proc OrderedLocks(g: PGlobals): bool = 
  for i in 0 .. g.locksLen-2:
    if g.locks[i] >= g.locks[i+1]: return false
  result = true

proc TryAquire*(lock: var TLock): bool {.inline.} = 
  ## Try to aquires the lock `lock`. Returns `true` on success.
  when noDeadlocks:
    result = TryAquireSys(lock)
    if not result: return
    # we have to add it to the ordered list. Oh, and we might fail if there#
    # there is no space in the array left ...
    var g = GetGlobals()
    if g.locksLen >= len(g.locks):
      ReleaseSys(lock)
      raise newException(EResourceExhausted, "cannot aquire additional lock")
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
  else:
    result = TryAquireSys(lock)

proc Aquire*(lock: var TLock) =
  ## Aquires the lock `lock`.
  when nodeadlocks:
    var g = GetGlobals()
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
          raise newException(EResourceExhausted, "cannot aquire additional lock")
        while L >= i:
          ReleaseSys(cast[ptr TSysLock](g.locks[L])[])
          g.locks[L+1] = g.locks[L]
          dec L
        # aquire the current lock:
        AquireSys(lock)
        g.locks[i] = p
        inc(g.locksLen)
        # aquire old locks in proper order again:
        L = g.locksLen-1
        inc i
        while i <= L:
          AquireSys(cast[ptr TSysLock](g.locks[i])[])
          inc(i)
        # DANGER: We can only modify this global var if we gained every lock!
        # NO! We need an atomic increment. Crap.
        discard system.atomicInc(deadlocksPrevented, 1)
        assert OrderedLocks(g)
        return
        
    # simply add to the end:
    if g.locksLen >= len(g.locks):
      raise newException(EResourceExhausted, "cannot aquire additional lock")
    AquireSys(lock)
    g.locks[g.locksLen] = p
    inc(g.locksLen)
    assert OrderedLocks(g)
  else:
    AquireSys(lock)
  
proc Release*(lock: var TLock) =
  ## Releases the lock `lock`.
  when nodeadlocks:
    var g = GetGlobals()
    var p = addr(lock)
    var L = g.locksLen
    for i in countdown(L-1, 0):
      if g.locks[i] == p: 
        for j in i..L-2: g.locks[j] = g.locks[j+1]
        dec g.locksLen
        break
  ReleaseSys(lock)

proc joinThread*[TParam](t: TThread[TParam]) {.inline.} = 
  ## waits for the thread `t` until it has terminated.
  when hostOS == "windows":
    discard WaitForSingleObject(t.sys, -1'i32)
  else:
    discard pthread_join(t.sys, nil)

proc destroyThread*[TParam](t: var TThread[TParam]) {.inline.} =
  ## forces the thread `t` to terminate. This is potentially dangerous if
  ## you don't have full control over `t` and its aquired resources.
  when hostOS == "windows":
    discard TerminateThread(t.sys, 1'i32)
  else:
    discard pthread_cancel(t.sys)

proc createThread*[TParam](t: var TThread[TParam], 
                           tp: proc (param: TParam), 
                           param: TParam) = 
  ## creates a new thread `t` and starts its execution. Entry point is the
  ## proc `tp`. `param` is passed to `tp`.
  t.c.threadLocalStorage = AllocThreadLocalStorage()
  t.c.data = param
  t.c.fn = tp
  when hostOS == "windows":
    var dummyThreadId: int32
    t.sys = CreateThread(nil, 0'i32, threadProcWrapper[TParam], 
                         addr(t.c), 0'i32, dummyThreadId)
  else:
    if pthread_create(t.sys, nil, threadProcWrapper[TParam], addr(t.c)) != 0:
      raise newException(EIO, "cannot create thread")

when isMainModule:
  import os
  
  var
    thr: array [0..5, TThread[tuple[a, b: int]]]
    L, M, N: TLock
  
  proc doNothing() = nil
  
  proc threadFunc(interval: tuple[a, b: int]) {.procvar.} = 
    doNothing()
    for i in interval.a..interval.b: 
      when nodeadlocks:
        case i mod 6
        of 0:
          Aquire(L) # lock stdout
          Aquire(M)
          Aquire(N)
        of 1:
          Aquire(L)
          Aquire(N) # lock stdout
          Aquire(M)
        of 2:
          Aquire(M)
          Aquire(L)
          Aquire(N)
        of 3:
          Aquire(M)
          Aquire(N)
          Aquire(L)
        of 4:
          Aquire(N)
          Aquire(M)
          Aquire(L)
        of 5:
          Aquire(N)
          Aquire(L)
          Aquire(M)
        else: assert false
      else:
        Aquire(L) # lock stdout
        
      echo i
      os.sleep(10)
      when nodeadlocks:
        echo "deadlocks prevented: ", deadlocksPrevented
      when nodeadlocks:
        Release(N)
        Release(M)
      Release(L)

  InitLock(L)
  InitLock(M)
  InitLock(N)

  proc main =
    for i in 0..high(thr):
      createThread(thr[i], threadFunc, (i*100, i*100+50))
    for i in 0..high(thr):
      joinThread(thr[i])

  GC_disable() 
  main()
  GC_enable()

