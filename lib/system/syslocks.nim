#
#
#            Nim's Runtime Library
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

  proc initSysLock(L: var TSysLock) {.stdcall, noSideEffect,
    dynlib: "kernel32", importc: "InitializeCriticalSection".}
    ## Initializes the lock `L`.

  proc tryAcquireSysAux(L: var TSysLock): int32 {.stdcall, noSideEffect,
    dynlib: "kernel32", importc: "TryEnterCriticalSection".}
    ## Tries to acquire the lock `L`.

  proc tryAcquireSys(L: var TSysLock): bool {.inline.} =
    result = tryAcquireSysAux(L) != 0'i32

  proc acquireSys(L: var TSysLock) {.stdcall, noSideEffect,
    dynlib: "kernel32", importc: "EnterCriticalSection".}
    ## Acquires the lock `L`.

  proc releaseSys(L: var TSysLock) {.stdcall, noSideEffect,
    dynlib: "kernel32", importc: "LeaveCriticalSection".}
    ## Releases the lock `L`.

  proc deinitSys(L: var TSysLock) {.stdcall, noSideEffect,
    dynlib: "kernel32", importc: "DeleteCriticalSection".}

  proc createEvent(lpEventAttributes: pointer,
                   bManualReset, bInitialState: int32,
                   lpName: cstring): TSysCond {.stdcall, noSideEffect,
    dynlib: "kernel32", importc: "CreateEventA".}

  proc closeHandle(hObject: THandle) {.stdcall, noSideEffect,
    dynlib: "kernel32", importc: "CloseHandle".}
  proc waitForSingleObject(hHandle: THandle, dwMilliseconds: int32): int32 {.
    stdcall, dynlib: "kernel32", importc: "WaitForSingleObject", noSideEffect.}

  proc signalSysCond(hEvent: TSysCond) {.stdcall, noSideEffect,
    dynlib: "kernel32", importc: "SetEvent".}

  proc initSysCond(cond: var TSysCond) {.inline.} =
    cond = createEvent(nil, 0'i32, 0'i32, nil)
  proc deinitSysCond(cond: var TSysCond) {.inline.} =
    closeHandle(cond)
  proc waitSysCond(cond: var TSysCond, lock: var TSysLock) =
    releaseSys(lock)
    discard waitForSingleObject(cond, -1'i32)
    acquireSys(lock)

  proc waitSysCondWindows(cond: var TSysCond) =
    discard waitForSingleObject(cond, -1'i32)

else:
  type
    TSysLock {.importc: "pthread_mutex_t", pure, final,
               header: "<sys/types.h>".} = object
    TSysCond {.importc: "pthread_cond_t", pure, final,
               header: "<sys/types.h>".} = object

  proc initSysLock(L: var TSysLock, attr: pointer = nil) {.
    importc: "pthread_mutex_init", header: "<pthread.h>", noSideEffect.}

  proc acquireSys(L: var TSysLock) {.noSideEffect,
    importc: "pthread_mutex_lock", header: "<pthread.h>".}
  proc tryAcquireSysAux(L: var TSysLock): cint {.noSideEffect,
    importc: "pthread_mutex_trylock", header: "<pthread.h>".}

  proc tryAcquireSys(L: var TSysLock): bool {.inline.} =
    result = tryAcquireSysAux(L) == 0'i32

  proc releaseSys(L: var TSysLock) {.noSideEffect,
    importc: "pthread_mutex_unlock", header: "<pthread.h>".}
  proc deinitSys(L: var TSysLock) {.noSideEffect,
    importc: "pthread_mutex_destroy", header: "<pthread.h>".}

  proc initSysCond(cond: var TSysCond, cond_attr: pointer = nil) {.
    importc: "pthread_cond_init", header: "<pthread.h>", noSideEffect.}
  proc waitSysCond(cond: var TSysCond, lock: var TSysLock) {.
    importc: "pthread_cond_wait", header: "<pthread.h>", noSideEffect.}
  proc signalSysCond(cond: var TSysCond) {.
    importc: "pthread_cond_signal", header: "<pthread.h>", noSideEffect.}

  proc deinitSysCond(cond: var TSysCond) {.noSideEffect,
    importc: "pthread_cond_destroy", header: "<pthread.h>".}

