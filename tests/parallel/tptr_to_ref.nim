# bug #2854

import locks, threadpool, osproc

const MAX_WORKERS = 10

type
  Killer = object
    lock: Lock
    bailed {.guard: lock.}: bool
    processes {.guard: lock.}: array[0..MAX_WORKERS-1, foreign ptr Process]

template hold(lock: Lock, body: stmt) =
  lock.acquire
  defer: lock.release
  {.locks: [lock].}:
    body

proc initKiller*(): Killer =
  initLock(result.lock)
  result.lock.hold:
    result.bailed = false
    for i, _ in result.processes:
      result.processes[i] = nil

var killer = initKiller()
