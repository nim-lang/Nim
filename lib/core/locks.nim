#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains Nim's support for locks and condition vars.
## If the symbol ``preventDeadlocks`` is defined
## (compiled with ``-d:preventDeadlocks``) special logic is added to
## every ``acquire``, ``tryAcquire`` and ``release`` action that ensures at
## runtime that no deadlock can occur. This is achieved by forcing a thread
## to release its locks should it be part of a deadlock. This thread then
## re-acquires its locks and proceeds.

include "system/syslocks"

type
  TLock* = TSysLock ## Nim lock; whether this is re-entrant
                    ## or not is unspecified! However, compilation
                    ## in preventDeadlocks-mode guarantees re-entrancy.
  TCond* = TSysCond ## Nim condition variable
  
  LockEffect* = object of RootEffect ## effect that denotes that some lock operation
                                     ## is performed
  AquireEffect* = object of LockEffect  ## effect that denotes that some lock is
                                        ## aquired
  ReleaseEffect* = object of LockEffect ## effect that denotes that some lock is
                                        ## released
{.deprecated: [FLock: LockEffect, FAquireLock: AquireEffect, 
    FReleaseLock: ReleaseEffect].}
  
const
  noDeadlocks = defined(preventDeadlocks)
  maxLocksPerThread* = 10 ## max number of locks a thread can hold
                          ## at the same time; this limit is only relevant
                          ## when compiled with ``-d:preventDeadlocks``.

var
  deadlocksPrevented*: int ## counts the number of times a 
                           ## deadlock has been prevented

when noDeadlocks:
  var
    locksLen {.threadvar.}: int
    locks {.threadvar.}: array [0..MaxLocksPerThread-1, pointer]

  proc orderedLocks(): bool = 
    for i in 0 .. locksLen-2:
      if locks[i] >= locks[i+1]: return false
    result = true

proc initLock*(lock: var TLock) {.inline.} =
  ## Initializes the given lock.
  initSysLock(lock)

proc deinitLock*(lock: var TLock) {.inline.} =
  ## Frees the resources associated with the lock.
  deinitSys(lock)

proc tryAcquire*(lock: var TLock): bool {.tags: [AquireEffect].} = 
  ## Tries to acquire the given lock. Returns `true` on success.
  result = tryAcquireSys(lock)
  when noDeadlocks:
    if not result: return
    # we have to add it to the ordered list. Oh, and we might fail if
    # there is no space in the array left ...
    if locksLen >= len(locks):
      releaseSys(lock)
      raise newException(EResourceExhausted, "cannot acquire additional lock")
    # find the position to add:
    var p = addr(lock)
    var L = locksLen-1
    var i = 0
    while i <= L:
      assert locks[i] != nil
      if locks[i] < p: inc(i) # in correct order
      elif locks[i] == p: return # thread already holds lock
      else:
        # do the crazy stuff here:
        while L >= i:
          locks[L+1] = locks[L]
          dec L
        locks[i] = p
        inc(locksLen)
        assert orderedLocks()
        return
    # simply add to the end:
    locks[locksLen] = p
    inc(locksLen)
    assert orderedLocks()

proc acquire*(lock: var TLock) {.tags: [AquireEffect].} =
  ## Acquires the given lock.
  when nodeadlocks:
    var p = addr(lock)
    var L = locksLen-1
    var i = 0
    while i <= L:
      assert locks[i] != nil
      if locks[i] < p: inc(i) # in correct order
      elif locks[i] == p: return # thread already holds lock
      else:
        # do the crazy stuff here:
        if locksLen >= len(locks):
          raise newException(EResourceExhausted, 
              "cannot acquire additional lock")
        while L >= i:
          releaseSys(cast[ptr TSysLock](locks[L])[])
          locks[L+1] = locks[L]
          dec L
        # acquire the current lock:
        acquireSys(lock)
        locks[i] = p
        inc(locksLen)
        # acquire old locks in proper order again:
        L = locksLen-1
        inc i
        while i <= L:
          acquireSys(cast[ptr TSysLock](locks[i])[])
          inc(i)
        # DANGER: We can only modify this global var if we gained every lock!
        # NO! We need an atomic increment. Crap.
        discard system.atomicInc(deadlocksPrevented, 1)
        assert orderedLocks()
        return
        
    # simply add to the end:
    if locksLen >= len(locks):
      raise newException(EResourceExhausted, "cannot acquire additional lock")
    acquireSys(lock)
    locks[locksLen] = p
    inc(locksLen)
    assert orderedLocks()
  else:
    acquireSys(lock)
  
proc release*(lock: var TLock) {.tags: [ReleaseEffect].} =
  ## Releases the given lock.
  when nodeadlocks:
    var p = addr(lock)
    var L = locksLen
    for i in countdown(L-1, 0):
      if locks[i] == p: 
        for j in i..L-2: locks[j] = locks[j+1]
        dec locksLen
        break
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

