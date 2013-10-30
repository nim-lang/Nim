#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains Nimrod's support for locks and condition vars.
## If the symbol ``preventDeadlocks`` is defined
## (compiled with ``-d:preventDeadlocks``) special logic is added to
## every ``acquire``, ``tryAcquire`` and ``release`` action that ensures at
## runtime that no deadlock can occur. This is achieved by forcing a thread
## to release its locks should it be part of a deadlock. This thread then
## re-acquires its locks and proceeds.

include "system/syslocks"

type
  TLock* = TSysLock ## Nimrod lock; whether this is re-entrant
                    ## or not is unspecified! However, compilation
                    ## in preventDeadlocks-mode guarantees re-entrancy.
  TCond* = TSysCond ## Nimrod condition variable

  FLock* = object of TEffect ## effect that denotes that some lock operation
                             ## is performed
  FAquireLock* = object of FLock  ## effect that denotes that some lock is
                                  ## aquired
  FReleaseLock* = object of FLock ## effect that denotes that some lock is
                                  ## released

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

  proc OrderedLocks(): bool =
    for i in 0 .. locksLen-2:
      if locks[i] >= locks[i+1]: return false
    result = true

proc InitLock*(lock: var TLock) {.inline.} =
  ## Initializes the given lock.
  InitSysLock(lock)

proc DeinitLock*(lock: var TLock) {.inline.} =
  ## Frees the resources associated with the lock.
  DeinitSys(lock)

proc TryAcquire*(lock: var TLock): bool {.tags: [FAquireLock].} =
  ## Tries to acquire the given lock. Returns `true` on success.
  result = TryAcquireSys(lock)
  when noDeadlocks:
    if not result: return
    # we have to add it to the ordered list. Oh, and we might fail if
    # there is no space in the array left ...
    if locksLen >= len(locks):
      ReleaseSys(lock)
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
        assert OrderedLocks()
        return
    # simply add to the end:
    locks[locksLen] = p
    inc(locksLen)
    assert OrderedLocks()

proc Acquire*(lock: var TLock) {.tags: [FAquireLock].} =
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
          ReleaseSys(cast[ptr TSysLock](locks[L])[])
          locks[L+1] = locks[L]
          dec L
        # acquire the current lock:
        AcquireSys(lock)
        locks[i] = p
        inc(locksLen)
        # acquire old locks in proper order again:
        L = locksLen-1
        inc i
        while i <= L:
          AcquireSys(cast[ptr TSysLock](locks[i])[])
          inc(i)
        # DANGER: We can only modify this global var if we gained every lock!
        # NO! We need an atomic increment. Crap.
        discard system.atomicInc(deadlocksPrevented, 1)
        assert OrderedLocks()
        return

    # simply add to the end:
    if locksLen >= len(locks):
      raise newException(EResourceExhausted, "cannot acquire additional lock")
    AcquireSys(lock)
    locks[locksLen] = p
    inc(locksLen)
    assert OrderedLocks()
  else:
    AcquireSys(lock)

proc Release*(lock: var TLock) {.tags: [FReleaseLock].} =
  ## Releases the given lock.
  when nodeadlocks:
    var p = addr(lock)
    var L = locksLen
    for i in countdown(L-1, 0):
      if locks[i] == p:
        for j in i..L-2: locks[j] = locks[j+1]
        dec locksLen
        break
  ReleaseSys(lock)


proc InitCond*(cond: var TCond) {.inline.} =
  ## Initializes the given condition variable.
  InitSysCond(cond)

proc DeinitCond*(cond: var TCond) {.inline.} =
  ## Frees the resources associated with the lock.
  DeinitSysCond(cond)

proc wait*(cond: var TCond, lock: var TLock) {.inline.} =
  ## waits on the condition variable `cond`.
  WaitSysCond(cond, lock)

proc signal*(cond: var TCond) {.inline.} =
  ## sends a signal to the condition variable `cond`.
  signalSysCond(cond)

