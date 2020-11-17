#
#
#            Nim's Runtime Library
#        (c) Copyright 2016 Anatoly Galiulin
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains Nim's support for reentrant locks.


when not compileOption("threads") and not defined(nimdoc):
  {.error: "Rlocks requires --threads:on option.".}

const insideRLocksModule = true
include "system/syslocks"

type
  RLock* = SysLock ## Nim lock, re-entrant

proc initRLock*(lock: var RLock) {.inline.} =
  ## Initializes the given lock.
  when defined(posix):
    var a: SysLockAttr
    initSysLockAttr(a)
    setSysLockType(a, SysLockType_Reentrant())
    initSysLock(lock, a.addr)
  else:
    initSysLock(lock)

proc deinitRLock*(lock: var RLock) {.inline.} =
  ## Frees the resources associated with the lock.
  deinitSys(lock)

proc tryAcquire*(lock: var RLock): bool =
  ## Tries to acquire the given lock. Returns `true` on success.
  result = tryAcquireSys(lock)

proc acquire*(lock: var RLock) =
  ## Acquires the given lock.
  acquireSys(lock)

proc release*(lock: var RLock) =
  ## Releases the given lock.
  releaseSys(lock)

template withRLock*(lock: var RLock, code: untyped): untyped =
  ## Acquires the given lock and then executes the code.
  block:
    acquire(lock)
    defer:
      release(lock)
    {.locks: [lock].}:
      code
