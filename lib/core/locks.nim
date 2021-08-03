#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains Nim's support for locks and condition vars.

#[
for js, for now we treat locks as noop's to avoid pushing `when defined(js)`
in client code that uses locks.
]#

when not compileOption("threads") and not defined(nimdoc):
  when false: # fix #12330
    {.error: "Locks requires --threads:on option.".}

const insideRLocksModule = false
const useOrcArc = defined(gcArc) or defined(gcOrc)

include "system/syslocks"

type
  Lock* = object
    ## Nim lock; whether this is re-entrant or not is unspecified!
    lock: SysLock
  Cond* = object
    ## Nim condition variable
    cond: SysCond

{.push stackTrace: off.}


proc `$`*(lock: Lock): string =
  # workaround bug #14873
  result = "()"

proc initLock*(lock: var Lock) {.inline.} =
  ## Initializes the given lock.
  when not defined(js):
    initSysLock(lock.lock)

when useOrcArc:
  proc `=copy`*(x: var Lock, y: Lock) {.error.}

  proc `=destroy`*(lock: var Lock) {.inline.} =
    deinitSys(lock.lock)

  proc deinitLock*(lock: var Lock) {.inline, 
        deprecated: "`deinitLock` is not needed anymore in ARC/ORC(it is a no-op now); `=destroy` is already defined for `Lock`".} =
    discard
else:
  proc deinitLock*(lock: var Lock) {.inline.} =
    ## Frees the resources associated with the lock.
    deinitSys(lock.lock)

proc tryAcquire*(lock: var Lock): bool {.inline.} =
  ## Tries to acquire the given lock. Returns `true` on success.
  result = tryAcquireSys(lock.lock)

proc acquire*(lock: var Lock) {.inline.} =
  ## Acquires the given lock.
  when not defined(js):
    acquireSys(lock.lock)

proc release*(lock: var Lock) {.inline.} =
  ## Releases the given lock.
  when not defined(js):
    releaseSys(lock.lock)


proc initCond*(cond: var Cond) {.inline.} =
  ## Initializes the given condition variable.
  initSysCond(cond.cond)


when useOrcArc:
  proc `=copy`*(x: var Cond, y: Cond) {.error.}

  proc `=destroy`*(cond: var Cond) {.inline.} =
    deinitSysCond(cond.cond)

  proc deinitCond*(cond: var Cond) {.inline, 
        deprecated: "`deinitCond` is not needed anymore in ARC/ORC(it is a no-op now); `=destroy` is already defined for `Cond`".} =
    discard
else:
  proc deinitCond*(cond: var Cond) {.inline.} =
    ## Frees the resources associated with the condition variable.
    deinitSysCond(cond.cond)

proc wait*(cond: var Cond, lock: var Lock) {.inline.} =
  ## Waits on the condition variable `cond`.
  waitSysCond(cond.cond, lock.lock)

proc signal*(cond: var Cond) {.inline.} =
  ## Sends a signal to the condition variable `cond`.
  signalSysCond(cond.cond)

proc broadcast*(cond: var Cond) {.inline.} =
  ## Unblocks all threads currently blocked on the
  ## specified condition variable `cond`.
  broadcastSysCond(cond.cond)

template withLock*(a: Lock, body: untyped) =
  ## Acquires the given lock, executes the statements in body and
  ## releases the lock after the statements finish executing.
  acquire(a)
  {.locks: [a].}:
    try:
      body
    finally:
      release(a)

{.pop.}
