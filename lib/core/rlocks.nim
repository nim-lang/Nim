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
  when false:
    # make rlocks modlue consistent with locks module,
    # so they can replace each other seamlessly.
    {.error: "Rlocks requires --threads:on option.".}

const insideRLocksModule = true
const useOrcArc = defined(gcArc) or defined(gcOrc)

include "system/syslocks"

type
  RLock* = object
    ## Nim lock, re-entrant
    lock: SysLock

proc initRLock*(lock: var RLock) {.inline.} =
  ## Initializes the given lock.
  when defined(posix):
    var a: SysLockAttr
    initSysLockAttr(a)
    setSysLockType(a, SysLockType_Reentrant)
    initSysLock(lock.lock, a.addr)
  else:
    initSysLock(lock.lock)

when useOrcArc:
  proc `=sink`*(x: var RLock, y: RLock) {.error.}

  proc `=copy`*(x: var RLock, y: RLock) {.error.}

  proc `=destroy`*(lock: var RLock) {.inline.} =
    deinitSys(lock.lock)

  proc deinitRLock*(lock: var RLock) {.inline, 
        deprecated: "`deinitRLock` is not needed anymore in ARC/ORC(it is a no-op now); `=destroy` is already defined for `RLock`".} =
    discard
else:
  proc deinitRLock*(lock: var RLock) {.inline.} =
    ## Frees the resources associated with the lock.
    deinitSys(lock.lock)

proc tryAcquire*(lock: var RLock): bool {.inline.} =
  ## Tries to acquire the given lock. Returns `true` on success.
  result = tryAcquireSys(lock.lock)

proc acquire*(lock: var RLock) {.inline.} =
  ## Acquires the given lock.
  acquireSys(lock.lock)

proc release*(lock: var RLock) {.inline.} =
  ## Releases the given lock.
  releaseSys(lock.lock)

template withRLock*(lock: RLock, code: untyped) =
  ## Acquires the given lock and then executes the code.
  acquire(lock)
  {.locks: [lock].}:
    try:
      code
    finally:
      release(lock)
