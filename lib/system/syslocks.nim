#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Low level system locks and condition vars.

when defined(Windows):
  type
    THandle = int
    TSysLock {.final, pure.} = object # CRITICAL_SECTION in WinApi
      DebugInfo: pointer
      LockCount: int32
      RecursionCount: int32
      OwningThread: int
      LockSemaphore: int
      Reserved: int32

    TSysCond = THandle

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

  proc DeinitSys(L: var TSysLock) {.stdcall, noSideEffect,
    dynlib: "kernel32", importc: "DeleteCriticalSection".}

  proc CreateEvent(lpEventAttributes: pointer,
                   bManualReset, bInitialState: int32,
                   lpName: cstring): TSysCond {.stdcall, noSideEffect,
    dynlib: "kernel32", importc: "CreateEventA".}

  proc CloseHandle(hObject: THandle) {.stdcall, noSideEffect,
    dynlib: "kernel32", importc: "CloseHandle".}
  proc WaitForSingleObject(hHandle: THandle, dwMilliseconds: int32): int32 {.
    stdcall, dynlib: "kernel32", importc: "WaitForSingleObject".}

  proc SignalSysCond(hEvent: TSysCond) {.stdcall, noSideEffect,
    dynlib: "kernel32", importc: "SetEvent".}

  proc InitSysCond(cond: var TSysCond) {.inline.} =
    cond = CreateEvent(nil, 0'i32, 0'i32, nil)
  proc DeinitSysCond(cond: var TSysCond) {.inline.} =
    CloseHandle(cond)
  proc WaitSysCond(cond: var TSysCond, lock: var TSysLock) =
    releaseSys(lock)
    discard WaitForSingleObject(cond, -1'i32)
    acquireSys(lock)

else:
  type
    TSysLock {.importc: "pthread_mutex_t", pure, final,
               header: "<sys/types.h>".} = object
    TSysCond {.importc: "pthread_cond_t", pure, final,
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
  proc DeinitSys(L: var TSysLock) {.
    importc: "pthread_mutex_destroy", header: "<pthread.h>".}

  proc InitSysCond(cond: var TSysCond, cond_attr: pointer = nil) {.
    importc: "pthread_cond_init", header: "<pthread.h>".}
  proc WaitSysCond(cond: var TSysCond, lock: var TSysLock) {.
    importc: "pthread_cond_wait", header: "<pthread.h>".}
  proc SignalSysCond(cond: var TSysCond) {.
    importc: "pthread_cond_signal", header: "<pthread.h>".}

  proc DeinitSysCond(cond: var TSysCond) {.
    importc: "pthread_cond_destroy", header: "<pthread.h>".}

