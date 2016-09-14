#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Low level system locks and condition vars.

{.push stackTrace: off.}

when defined(Windows):
  type
    Handle = int

    SysLock {.importc: "CRITICAL_SECTION",
              header: "<windows.h>", final, pure.} = object # CRITICAL_SECTION in WinApi
      DebugInfo: pointer
      LockCount: int32
      RecursionCount: int32
      OwningThread: int
      LockSemaphore: int
      SpinCount: int

    SysCond = Handle

  {.deprecated: [THandle: Handle, TSysLock: SysLock, TSysCond: SysCond].}

  proc initSysLock(L: var SysLock) {.importc: "InitializeCriticalSection",
                                     header: "<windows.h>".}
    ## Initializes the lock `L`.

  proc tryAcquireSysAux(L: var SysLock): int32 {.importc: "TryEnterCriticalSection",
                                                 header: "<windows.h>".}
    ## Tries to acquire the lock `L`.

  proc tryAcquireSys(L: var SysLock): bool {.inline.} =
    result = tryAcquireSysAux(L) != 0'i32

  proc acquireSys(L: var SysLock) {.importc: "EnterCriticalSection",
                                    header: "<windows.h>".}
    ## Acquires the lock `L`.

  proc releaseSys(L: var SysLock) {.importc: "LeaveCriticalSection",
                                    header: "<windows.h>".}
    ## Releases the lock `L`.

  proc deinitSys(L: var SysLock) {.importc: "DeleteCriticalSection",
                                   header: "<windows.h>".}

  proc createEvent(lpEventAttributes: pointer,
                   bManualReset, bInitialState: int32,
                   lpName: cstring): SysCond {.stdcall, noSideEffect,
    dynlib: "kernel32", importc: "CreateEventA".}

  proc closeHandle(hObject: Handle) {.stdcall, noSideEffect,
    dynlib: "kernel32", importc: "CloseHandle".}
  proc waitForSingleObject(hHandle: Handle, dwMilliseconds: int32): int32 {.
    stdcall, dynlib: "kernel32", importc: "WaitForSingleObject", noSideEffect.}

  proc signalSysCond(hEvent: SysCond) {.stdcall, noSideEffect,
    dynlib: "kernel32", importc: "SetEvent".}

  proc initSysCond(cond: var SysCond) {.inline.} =
    cond = createEvent(nil, 0'i32, 0'i32, nil)
  proc deinitSysCond(cond: var SysCond) {.inline.} =
    closeHandle(cond)
  proc waitSysCond(cond: var SysCond, lock: var SysLock) =
    releaseSys(lock)
    discard waitForSingleObject(cond, -1'i32)
    acquireSys(lock)

  proc waitSysCondWindows(cond: var SysCond) =
    discard waitForSingleObject(cond, -1'i32)

else:
  when defined(linux) and defined(amd64):
    type
      SysLock {.importc: "pthread_mutex_t", pure, final,
                 header: """#include <sys/types.h>
                            #include <pthread.h>""".} = object
        lock {.importc: "__data.__lock".}: cint
        count {.importc: "__data.__count".}: cuint
        owner {.importc: "__data.__owner".}: cint
        nusers {.importc: "__data.__nusers".}: cuint
        kind {.importc: "__data.__kind".}: cint
        spins {.importc: "__data.__spins".}: cint
        # glibc 2.18+:
        # spins {.importc: "__data.__spins".}: cshort
        # elision {.importc: "__data.__elision".}: cshort
        list_next {.importc: "__data.__list.__next".}: pointer
        list_prev {.importc: "__data.__list.__prev".}: pointer

      SysLockAttr {.importc: "pthread_mutexattr_t",
                 header: """#include <sys/types.h>
                            #include <pthread.h>""".} = object
        size: array[4, char]  # alignas(long)!

      SysCond {.importc: "pthread_cond_t", pure, final,
                 header: """#include <sys/types.h>
                            #include <pthread.h>""".} = object
        lock {.importc: "__data.__lock".}: cint
        futex {.importc: "__data.__futex".}: cuint
        total_seq {.importc: "__data.__total_seq".}: culonglong
        wakeup_seq {.importc: "__data.__wakeup_seq".}: culonglong
        woken_seq {.importc: "__data.__woken_seq".}: culonglong
        mutex {.importc: "__data.__mutex".}: pointer
        nwaiters {.importc: "__data.__nwaiters".}: cuint
        broadcast_seq {.importc: "__data.__broadcast_seq".}: cuint

      SysLockType = distinct cint
  else:
    type
      SysLock {.importc: "pthread_mutex_t", pure, final,
                 header: """#include <sys/types.h>
                            #include <pthread.h>""".} = object
      SysLockAttr {.importc: "pthread_mutexattr_t", pure, final
                 header: """#include <sys/types.h>
                            #include <pthread.h>""".} = object
      SysCond {.importc: "pthread_cond_t", pure, final,
                 header: """#include <sys/types.h>
                            #include <pthread.h>""".} = object
      SysLockType = distinct cint

  proc initSysLock(L: var SysLock, attr: ptr SysLockAttr = nil) {.
    importc: "pthread_mutex_init", header: "<pthread.h>", noSideEffect.}

  when insideRLocksModule:
    proc SysLockType_Reentrant: SysLockType =
      {.emit: "`result` = PTHREAD_MUTEX_RECURSIVE;".}
    proc initSysLockAttr(a: var SysLockAttr) {.
      importc: "pthread_mutexattr_init", header: "<pthread.h>", noSideEffect.}
    proc setSysLockType(a: var SysLockAttr, t: SysLockType) {.
      importc: "pthread_mutexattr_settype", header: "<pthread.h>", noSideEffect.}

  proc acquireSys(L: var SysLock) {.noSideEffect,
    importc: "pthread_mutex_lock", header: "<pthread.h>".}
  proc tryAcquireSysAux(L: var SysLock): cint {.noSideEffect,
    importc: "pthread_mutex_trylock", header: "<pthread.h>".}

  proc tryAcquireSys(L: var SysLock): bool {.inline.} =
    result = tryAcquireSysAux(L) == 0'i32

  proc releaseSys(L: var SysLock) {.noSideEffect,
    importc: "pthread_mutex_unlock", header: "<pthread.h>".}
  proc deinitSys(L: var SysLock) {.noSideEffect,
    importc: "pthread_mutex_destroy", header: "<pthread.h>".}

  when not insideRLocksModule:
    proc initSysCond(cond: var SysCond, cond_attr: pointer = nil) {.
      importc: "pthread_cond_init", header: "<pthread.h>", noSideEffect.}
    proc waitSysCond(cond: var SysCond, lock: var SysLock) {.
      importc: "pthread_cond_wait", header: "<pthread.h>", noSideEffect.}
    proc signalSysCond(cond: var SysCond) {.
      importc: "pthread_cond_signal", header: "<pthread.h>", noSideEffect.}
    proc deinitSysCond(cond: var SysCond) {.noSideEffect,
      importc: "pthread_cond_destroy", header: "<pthread.h>".}

{.pop.}
