#
#
#            Nim's Runtime Library
#        (c) Copyright 2026 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Read-write lock (RwLock) for lib/system.
# Used by YRC and by traceable containers that perform topology-changing ops.
# POSIX: pthread_rwlock_* ; Windows: SRWLOCK (slim reader/writer).

{.push stackTrace: off.}

when defined(windows):
  # SRWLOCK is pointer-sized; use single pointer for ABI compatibility
  type
    RwLock* {.importc: "SRWLOCK", header: "<synchapi.h>", final, pure, byref.} = object
      p: pointer

  proc initializeSRWLock(L: var RwLock) {.importc: "InitializeSRWLock",
    header: "<synchapi.h>".}
  proc acquireSRWLockShared(L: var RwLock) {.importc: "AcquireSRWLockShared",
    header: "<synchapi.h>".}
  proc releaseSRWLockShared(L: var RwLock) {.importc: "ReleaseSRWLockShared",
    header: "<synchapi.h>".}
  proc acquireSRWLockExclusive(L: var RwLock) {.importc: "AcquireSRWLockExclusive",
    header: "<synchapi.h>".}
  proc releaseSRWLockExclusive(L: var RwLock) {.importc: "ReleaseSRWLockExclusive",
    header: "<synchapi.h>".}

  proc initRwLock*(L: var RwLock) {.inline.} =
    initializeSRWLock(L)
  proc deinitRwLock*(L: var RwLock) {.inline.} =
    discard
  proc acquireRead*(L: var RwLock) {.inline.} =
    acquireSRWLockShared(L)
  proc releaseRead*(L: var RwLock) {.inline.} =
    releaseSRWLockShared(L)
  proc acquireWrite*(L: var RwLock) {.inline.} =
    acquireSRWLockExclusive(L)
  proc releaseWrite*(L: var RwLock) {.inline.} =
    releaseSRWLockExclusive(L)

elif defined(genode):
  {.error: "RwLock is not implemented for Genode".}

else:
  # POSIX: pthread_rwlock_*
  type
    SysRwLockObj {.importc: "pthread_rwlock_t", pure, final,
                  header: """#include <sys/types.h>
                             #include <pthread.h>""", byref.} = object
      when defined(linux) and defined(amd64):
        abi: array[56 div sizeof(clong), clong]

  proc pthread_rwlock_init(rwlock: var SysRwLockObj, attr: pointer): cint {.
    importc: "pthread_rwlock_init", header: "<pthread.h>", noSideEffect.}
  proc pthread_rwlock_destroy(rwlock: var SysRwLockObj): cint {.
    importc: "pthread_rwlock_destroy", header: "<pthread.h>", noSideEffect.}
  proc pthread_rwlock_rdlock(rwlock: var SysRwLockObj): cint {.
    importc: "pthread_rwlock_rdlock", header: "<pthread.h>", noSideEffect.}
  proc pthread_rwlock_wrlock(rwlock: var SysRwLockObj): cint {.
    importc: "pthread_rwlock_wrlock", header: "<pthread.h>", noSideEffect.}
  proc pthread_rwlock_unlock(rwlock: var SysRwLockObj): cint {.
    importc: "pthread_rwlock_unlock", header: "<pthread.h>", noSideEffect.}

  when defined(ios):
    type RwLock* = ptr SysRwLockObj
    proc initRwLock*(L: var RwLock) =
      when not declared(c_malloc):
        proc c_malloc(size: csize_t): pointer {.importc: "malloc", header: "<stdlib.h>".}
        proc c_free(p: pointer) {.importc: "free", header: "<stdlib.h>".}
      L = cast[RwLock](c_malloc(csize_t(sizeof(SysRwLockObj))))
      discard pthread_rwlock_init(L[], nil)
    proc deinitRwLock*(L: var RwLock) =
      if L != nil:
        discard pthread_rwlock_destroy(L[])
        when not declared(c_free):
          proc c_free(p: pointer) {.importc: "free", header: "<stdlib.h>".}
        c_free(L)
        L = nil
    proc acquireRead*(L: var RwLock) =
      discard pthread_rwlock_rdlock(L[])
    proc releaseRead*(L: var RwLock) =
      discard pthread_rwlock_unlock(L[])
    proc acquireWrite*(L: var RwLock) =
      discard pthread_rwlock_wrlock(L[])
    proc releaseWrite*(L: var RwLock) =
      discard pthread_rwlock_unlock(L[])
  else:
    type RwLock* = SysRwLockObj
    proc initRwLock*(L: var RwLock) =
      discard pthread_rwlock_init(L, nil)
    proc deinitRwLock*(L: var RwLock) =
      discard pthread_rwlock_destroy(L)
    proc acquireRead*(L: var RwLock) =
      discard pthread_rwlock_rdlock(L)
    proc releaseRead*(L: var RwLock) =
      discard pthread_rwlock_unlock(L)
    proc acquireWrite*(L: var RwLock) =
      discard pthread_rwlock_wrlock(L)
    proc releaseWrite*(L: var RwLock) =
      discard pthread_rwlock_unlock(L)

template withReadLock*(L: var RwLock, body: untyped) =
  acquireRead(L)
  try:
    body
  finally:
    releaseRead(L)

template withWriteLock*(L: var RwLock, body: untyped) =
  acquireWrite(L)
  try:
    body
  finally:
    releaseWrite(L)

{.pop.}
