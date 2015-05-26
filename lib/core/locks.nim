#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains Nim's support for locks and condition vars.

include "system/syslocks"

type
  Lock* = SysLock ## Nim lock; whether this is re-entrant
                    ## or not is unspecified!

  Cond* = SysCond ## Nim condition variable

{.deprecated: [TLock: Lock, TCond: Cond].}

proc initLock*(lock: var Lock) {.inline.} =
  ## Initializes the given lock.
  initSysLock(lock)

proc deinitLock*(lock: var Lock) {.inline.} =
  ## Frees the resources associated with the lock.
  deinitSys(lock)

proc tryAcquire*(lock: var Lock): bool =
  ## Tries to acquire the given lock. Returns `true` on success.
  result = tryAcquireSys(lock)

proc acquire*(lock: var Lock) =
  ## Acquires the given lock.
  acquireSys(lock)

proc release*(lock: var Lock) =
  ## Releases the given lock.
  releaseSys(lock)


proc initCond*(cond: var Cond) {.inline.} =
  ## Initializes the given condition variable.
  initSysCond(cond)

proc deinitCond*(cond: var Cond) {.inline.} =
  ## Frees the resources associated with the lock.
  deinitSysCond(cond)

proc wait*(cond: var Cond, lock: var Lock) {.inline.} =
  ## waits on the condition variable `cond`.
  waitSysCond(cond, lock)

proc signal*(cond: var Cond) {.inline.} =
  ## sends a signal to the condition variable `cond`.
  signalSysCond(cond)
