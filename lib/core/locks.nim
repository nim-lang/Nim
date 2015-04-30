#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains Nim's support for locks and condition vars.

include "system/syslocks"

type
  TLock* = TSysLock ## Nim lock; whether this is re-entrant
                    ## or not is unspecified!
  TCond* = TSysCond ## Nim condition variable
  
  LockEffect* {.deprecated.} = object of RootEffect ## \
    ## effect that denotes that some lock operation
    ## is performed. Deprecated, do not use anymore!
  AquireEffect* {.deprecated.} = object of LockEffect  ## \
    ## effect that denotes that some lock is
    ## acquired. Deprecated, do not use anymore!
  ReleaseEffect* {.deprecated.} = object of LockEffect ## \
    ## effect that denotes that some lock is
    ## released. Deprecated, do not use anymore!
{.deprecated: [FLock: LockEffect, FAquireLock: AquireEffect, 
    FReleaseLock: ReleaseEffect].}

proc initLock*(lock: var TLock) {.inline.} =
  ## Initializes the given lock.
  initSysLock(lock)

proc deinitLock*(lock: var TLock) {.inline.} =
  ## Frees the resources associated with the lock.
  deinitSys(lock)

proc tryAcquire*(lock: var TLock): bool = 
  ## Tries to acquire the given lock. Returns `true` on success.
  result = tryAcquireSys(lock)

proc acquire*(lock: var TLock) =
  ## Acquires the given lock.
  acquireSys(lock)
  
proc release*(lock: var TLock) =
  ## Releases the given lock.
  releaseSys(lock)


proc initCond*(cond: var TCond) {.inline.} =
  ## Initializes the given condition variable.
  initSysCond(cond)

proc deinitCond*(cond: var TCond) {.inline.} =
  ## Frees the resources associated with the lock.
  deinitSysCond(cond)

proc wait*(cond: var TCond, lock: var TLock) {.inline.} =
  ## waits on the condition variable `cond`. 
  waitSysCond(cond, lock)
  
proc signal*(cond: var TCond) {.inline.} =
  ## sends a signal to the condition variable `cond`. 
  signalSysCond(cond)

