#
#
#            Nim's Runtime Library
#        (c) Copyright 2021 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains Nim's support for mutexes. It provides basic
## destructors supports.

runnableExamples("--threads:on --gc:orc"):
  type
    PassObj = object
      id: int

    Pass = ptr PassObj

  proc worker(p: Pass) {.thread.} =
    var m: Mutex
    init(m)
    acquire(m)
    inc p.id
    release(m)
    # After leaving the function scope, 
    # the resource owned by `m` is freed.

  var p = cast[Pass](allocShared0(sizeof(PassObj)))
  var ts = newSeq[Thread[Pass]](10)
  for i in 0..<ts.len:
    createThread(ts[i], worker, p)

  joinThreads(ts)
  assert p.id == 10


import locks, rlocks

type
  Mutex* = object ## Mutex; whether this is re-entrant
                  ## or not is unspecified.
    lock: Lock

  ReentrantMutex* = object ## Reentrant Mutex.
    lock: RLock

proc init*(mutex: var Mutex) {.inline.} =
  ## Initializes the given mutex.
  initLock(mutex.lock)

proc `=copy`*(x: var Mutex, y: Mutex) {.error.}

proc `=destroy`*(mutex: var Mutex) {.inline.} =
  ## Frees the resources associated with the mutex.
  deinitLock(mutex.lock)

proc tryAcquire*(mutex: var Mutex): bool {.inline.} =
  ## Tries to acquire the given mutex. Returns `true` on success.
  result = tryAcquire(mutex.lock)

proc acquire*(mutex: var Mutex) {.inline.} =
  ## Acquires the given mutex.
  acquire(mutex.lock)

proc release*(mutex: var Mutex) {.inline.} =
  ## Releases the given mutex.
  release(mutex.lock)

proc init*(mutex: var ReentrantMutex) {.inline.} =
  ## Initializes the given mutex.
  initRLock(mutex.lock)

proc `=copy`*(x: var ReentrantMutex, y: ReentrantMutex) {.error.}

proc `=destroy`*(mutex: var ReentrantMutex) {.inline.} =
  ## Frees the resources associated with the mutex.
  deinitRlock(mutex.lock)

proc tryAcquire*(mutex: var ReentrantMutex): bool {.inline.} =
  ## Tries to acquire the given mutex. Returns `true` on success.
  result = tryAcquire(mutex.lock)

proc acquire*(mutex: var ReentrantMutex) {.inline.} =
  ## Acquires the given mutex.
  acquire(mutex.lock)

proc release*(mutex: var ReentrantMutex) {.inline.} =
  ## Releases the given mutex.
  release(mutex.lock)
