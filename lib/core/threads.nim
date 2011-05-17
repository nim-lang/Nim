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
##  for i in 0..high(thr):
##    createThread(thr[i], threadFunc, (i*10, i*10+5))
##  for i in 0..high(thr):
##    joinThread(thr[i])

when not compileOption("threads"):
  {.error: "Thread support requires ``--threads:on`` commandline switch".}

when not defined(boehmgc) and not defined(nogc) and false:
  {.error: "Thread support requires --gc:boehm or --gc:none".}

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

  proc pthread_create(a1: var TSysThread, a2: ptr int,
            a3: proc (x: pointer) {.noconv.}, 
            a4: pointer): cint {.importc: "pthread_create", 
            header: "<pthread.h>".}
  proc pthread_join(a1: TSysThread, a2: ptr pointer): cint {.
    importc, header: "<pthread.h>".}

  proc pthread_cancel(a1: TSysThread): cint {.
    importc: "pthread_cancel", header: "<pthread.h>".}

  {.push stack_trace:off.}
  proc threadProcWrapper[TParam](closure: pointer) {.noconv.} = 
    var c = cast[ptr TThreadProcClosure[TParam]](closure)
    SetThreadLocalStorage(c.threadLocalStorage)
    c.fn(c.data)
  {.pop.}


const
  noDeadlocks = false # compileOption("deadlockPrevention")
  
include "lib/system/systhread"

when noDeadLocks:
  type
    TLock* {.pure, final.} = object ## Standard Nimrod Lock type.
      key: int       # used for identity and global order!
      sys: TSysLock
      next: ptr TLock
else:
  type 
    TLock* = TSysLock    
    
type
  TThread* {.pure, final.}[TParam] = object ## Nimrod thread.
    sys: TSysThread
    c: TThreadProcClosure[TParam]

when nodeadlocks:
  var 
    lockList {.threadvar.}: ptr TLock
    deadlocksPrevented* = 0  ## counts the number of times a 
                             ## deadlock has been prevented

proc InitLock*(L: var TLock) {.inline.} =
  ## Initializes the lock `L`.
  when noDeadlocks:
    InitSysLock(L.sys)
    L.key = cast[int](addr(L))
  else:
    InitSysLock(L)

proc TryAquire*(L: var TLock): bool {.inline.} = 
  ## Try to aquires the lock `L`. Returns `true` on success.
  when noDeadlocks:
    result = TryAquireSys(L.sys)
  else:
    result = TryAquireSys(L)

proc Aquire*(L: var TLock) =
  ## Aquires the lock `L`.
  when nodeadlocks:
    # Note: we MUST NOT change the linked list of locks before we have aquired
    # the proper locks! This is because the pointer to the next lock is part
    # of the lock itself!
    assert L.key != 0
    var p = lockList
    if p == nil:
      # simple case: no lock aquired yet:
      AquireSys(L.sys)
      locklist = addr(L)
      L.next = nil
    else:
      # check where to put L into the list:
      var r = p
      var last: ptr TLock = nil
      while L.key < r.key: 
        if r.next == nil: 
          # best case: L needs to be aquired as last lock, so we can 
          # skip a good amount of work: 
          AquireSys(L.sys)
          r.next = addr(L)
          L.next = nil
          return
        last = r
        r = r.next
      # special case: thread already holds L!
      if L.key == r.key: return
      
      # bad case: L needs to be somewhere in between
      # release all locks after L: 
      var rollback = r
      while r != nil:
        ReleaseSys(r.sys)
        r = r.next
      # and aquire them in the correct order again:
      AquireSys(L.sys)
      r = rollback
      while r != nil:
        assert r.key < L.key
        AquireSys(r.sys)
        r = r.next
      # now that we have all the locks we need, we can insert L 
      # into our list:
      if last != nil:
        L.next = last.next
        last.next = addr(L)
      else:
        L.next = lockList
        lockList = addr(L)
      inc(deadlocksPrevented)
  else:
    AquireSys(L)
  
proc Release*(L: var TLock) =
  ## Releases the lock `L`.
  when nodeadlocks:
    assert L.key != 0
    var p = lockList
    var last: ptr TLock = nil
    while true:
      # if we don't find the lock, die by reading from nil!
      if p.key == L.key: 
        if last != nil:
          last.next = p.next
        else:
          assert p == lockList
          lockList = locklist.next
        L.next = nil
        break
      last = p
      p = p.next
    ReleaseSys(L.sys)
  else:
    ReleaseSys(L)

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
    thr: array [0..1, TThread[tuple[a,b: int]]]
    L, M, N: TLock
  
  proc doNothing() = nil
  
  proc threadFunc(interval: tuple[a,b: int]) {.procvar.} = 
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
        Aquire(M)
        Aquire(N)
        
      echo i
      os.sleep(10)
      when nodeadlocks:
        echo "deadlocks prevented: ", deadlocksPrevented
      Release(L)
      Release(M)
      Release(N)

  InitLock(L)
  InitLock(M)
  InitLock(N)

  proc main =
    for i in 0..high(thr):
      createThread(thr[i], threadFunc, (i*100, i*100+50))
    for i in 0..high(thr):
      joinThread(thr[i])

  main()

