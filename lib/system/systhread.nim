#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

const
  hasThreadSupport = false # deactivate for now: thread stack walking
                           # is missing!
  maxThreads = 256

when (defined(gcc) or defined(llvm_gcc)) and hasThreadSupport:
  proc sync_add_and_fetch(p: var int, val: int): int {.
    importc: "__sync_add_and_fetch", nodecl.}
  proc sync_sub_and_fetch(p: var int, val: int): int {.
    importc: "__sync_sub_and_fetch", nodecl.}
elif defined(vcc) and hasThreadSupport:
  proc sync_add_and_fetch(p: var int, val: int): int {.
    importc: "NimXadd", nodecl.}
else:
  proc sync_add_and_fetch(p: var int, val: int): int {.inline.} =
    inc(p, val)
    result = p

var
  isMultiThreaded: bool # true when prog created at least 1 thread

proc atomicInc(memLoc: var int, x: int): int =
  when hasThreadSupport:
    result = sync_add_and_fetch(memLoc, x)
  else:
    inc(memLoc, x)
    result = memLoc
  
proc atomicDec(memLoc: var int, x: int): int =
  when hasThreadSupport:
    when defined(sync_sub_and_fetch):
      result = sync_sub_and_fetch(memLoc, x)
    else:
      result = sync_add_and_fetch(memLoc, -x)
  else:
    dec(memLoc, x)
    result = memLoc  
  
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
  
  proc InitLock(L: var TSysLock) {.stdcall,
    dynlib: "kernel32", importc: "InitializeCriticalSection".}
  proc Aquire(L: var TSysLock) {.stdcall,
    dynlib: "kernel32", importc: "EnterCriticalSection".}
  proc Release(L: var TSysLock) {.stdcall,
    dynlib: "kernel32", importc: "LeaveCriticalSection".}

  proc CreateThread(lpThreadAttributes: Pointer, dwStackSize: int32,
                     lpStartAddress: pointer, lpParameter: Pointer,
                     dwCreationFlags: int32, lpThreadId: var int32): THandle {.
    stdcall, dynlib: "kernel32", importc: "CreateThread".}

  
else:
  type
    TSysLock {.importc: "pthread_mutex_t", header: "<sys/types.h>".} = int
    TSysThread {.importc: "pthread_t", header: "<sys/types.h>".} = int

  proc InitLock(L: var TSysLock, attr: pointer = nil) {.
    importc: "pthread_mutex_init", header: "<pthread.h>".}
  proc Aquire(L: var TSysLock) {.
    importc: "pthread_mutex_lock", header: "<pthread.h>".}
  proc Release(L: var TSysLock) {.
    importc: "pthread_mutex_unlock", header: "<pthread.h>".}
  
  
type
  TThread* = TSysThread
  TLock* = TSysLock
  TThreadFunc* = proc (closure: pointer) {.cdecl.}
  
DWORD WINAPI SuspendThread(
  __in  HANDLE hThread
);
DWORD WINAPI ResumeThread(
  __in  HANDLE hThread
);
DWORD WINAPI ThreadProc(
  __in  LPVOID lpParameter
);

proc createThread*(t: var TThread, fn: TThreadFunc, closure: pointer) = 
  when defined(windows):
    
  else: 
    nil
    #pthread_create(
  
proc joinThread*(t: TThread) = 
  nil

#proc pthread_exit(void *value_ptr)
  
proc destroyThread*(t: var TThread) =
  nil

