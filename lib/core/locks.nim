#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
## This module contains Nim's support for locks and condition variables.
##
## .. warning:: This module is not available for the JavaScript backend.
##
## Basic usage
## ===========
##
## .. code-block:: Nim
##   var L: Lock
##   initLock(L)
##   withLock(L):
##     echo "protected section"
##   deinitLock(L)
##
## See also
## ========
## * `threads <threads.html>`_ for Nim thread support

when not compileOption("threads") and not defined(nimdoc):
  when false: # fix #12330
    {.error: "Locks requires --threads:on option.".}

import std/private/syslocks

type
  Lock* = SysLock ## Nim lock; whether this is re-entrant
                  ## or not is unspecified!
  Cond* = SysCond ## Nim condition variable

{.push stackTrace: off.}

proc `$`*(lock: Lock): string =
  # workaround bug #14873
  result = "()"

proc initLock*(lock: var Lock) {.inline.} =
  ## Initializes the given lock.
  ##
  ## Must be called before any other lock operations.
  ## Pair with `deinitLock <#deinitLock,Lock>`_ to free resources.
  runnableExamples("--threads:on"):
    var L: Lock
    initLock(L)
    deinitLock(L)
  when not defined(js):
    initSysLock(lock)

proc deinitLock*(lock: Lock) {.inline.} =
  ## Frees the resources associated with the lock.
  ##
  ## The lock must not be acquired when calling this proc.
  runnableExamples("--threads:on"):
    var L: Lock
    initLock(L)
    deinitLock(L)
  deinitSys(lock)

proc tryAcquire*(lock: var Lock): bool {.inline.} =
  ## Tries to acquire the given lock. Returns `true` on success.
  ##
  ## Returns `false` immediately if the lock is already held
  ## by another thread, unlike `acquire <#acquire,Lock>`_ which blocks.
  runnableExamples("--threads:on"):
    var L: Lock
    initLock(L)
    assert tryAcquire(L) == true  # not yet locked, succeeds
    release(L)
    deinitLock(L)
  result = tryAcquireSys(lock)

proc acquire*(lock: var Lock) {.inline.} =
  ## Acquires the given lock.
  ##
  ## Blocks until the lock becomes available if it is held by another thread.
  ## Use `tryAcquire <#tryAcquire,Lock>`_ for a non-blocking variant.
  runnableExamples("--threads:on"):
    var L: Lock
    initLock(L)
    acquire(L)
    release(L)
    deinitLock(L)
  when not defined(js):
    acquireSys(lock)

proc release*(lock: var Lock) {.inline.} =
  ## Releases the given lock.
  ##
  ## The lock must be acquired before calling this proc.
  runnableExamples("--threads:on"):
    var L: Lock
    initLock(L)
    acquire(L)
    release(L)
    deinitLock(L)
  when not defined(js):
    releaseSys(lock)

proc initCond*(cond: var Cond) {.inline.} =
  ## Initializes the given condition variable.
  ##
  ## Must be used together with a `Lock <#Lock>`_.
  ## Pair with `deinitCond <#deinitCond,Cond>`_ to free resources.
  runnableExamples("--threads:on"):
    var L: Lock
    var C: Cond
    initLock(L)
    initCond(C)
    deinitCond(C)
    deinitLock(L)
  initSysCond(cond)

proc deinitCond*(cond: Cond) {.inline.} =
  ## Frees the resources associated with the condition variable.
  runnableExamples("--threads:on"):
    var C: Cond
    initCond(C)
    deinitCond(C)
  deinitSysCond(cond)

proc wait*(cond: var Cond, lock: var Lock) {.inline.} =
  ## Waits on the condition variable `cond`.
  ##
  ## Atomically releases `lock` and suspends the calling thread
  ## until `signal <#signal,Cond>`_ or `broadcast <#broadcast,Cond>`_
  ## is called on `cond`. The lock is re-acquired before returning.
  ##
  ## The lock must be acquired before calling this proc.
  waitSysCond(cond, lock)

proc signal*(cond: var Cond) {.inline.} =
  ## Sends a signal to the condition variable `cond`.
  ##
  ## Unblocks at least one thread that is waiting on `cond`.
  ## If no threads are waiting, this is a no-op.
  ## To unblock all waiting threads use `broadcast <#broadcast,Cond>`_.
  runnableExamples("--threads:on"):
    var C: Cond
    initCond(C)
    signal(C)  # no-op if no threads are waiting
    deinitCond(C)
  signalSysCond(cond)

proc broadcast*(cond: var Cond) {.inline.} =
  ## Unblocks all threads currently blocked on the
  ## specified condition variable `cond`.
  ##
  ## If no threads are waiting, this is a no-op.
  ## To unblock only one thread use `signal <#signal,Cond>`_.
  runnableExamples("--threads:on"):
    var C: Cond
    initCond(C)
    broadcast(C)  # no-op if no threads are waiting
    deinitCond(C)
  broadcastSysCond(cond)

template withLock*(a: Lock, body: untyped) =
  ## Acquires the given lock, executes the statements in `body` and
  ## releases the lock after the statements finish executing.
  ##
  ## Even if an exception is raised within `body`, the lock will
  ## still be released.
  runnableExamples("--threads:on"):
    var L: Lock
    var counter = 0
    initLock(L)
    withLock(L):
      counter = 1
    assert counter == 1
    deinitLock(L)
  acquire(a)
  {.locks: [a].}:
    try:
      body
    finally:
      release(a)

{.pop.}