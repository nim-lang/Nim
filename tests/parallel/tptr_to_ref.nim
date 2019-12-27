# bug #2854

# Test case for the compiler correctly detecting if a type used by a shared
# global is gcsafe.

import locks, threadpool, osproc

const MAX_WORKERS = 50

type
  Killer* = object
    lock:                      Lock
    bailed    {.guard: lock.}: bool
    processes {.guard: lock.}: array[0..MAX_WORKERS-1, ptr Process]

# Hold a lock for a statement.
template hold(lock: Lock, body: untyped) =
  lock.acquire
  defer: lock.release
  {.locks: [lock].}:
    body

# Return an initialized Killer.
proc initKiller*(): Killer =
  initLock(result.lock)
  result.lock.hold:
    result.bailed = false
    for i, _ in result.processes:
      result.processes[i] = nil

# Global Killer instance.
var killer = initKiller()

# remember that a process has been launched, killing it if we have bailed.
proc launched*(process: ptr Process): int {.gcsafe.} =
  result = killer.processes.high + 1
  killer.lock.hold:
    if killer.bailed:
      process[].terminate()
    else:
      for i, _ in killer.processes:
        if killer.processes[i] == nil:
          killer.processes[i] = process
          result = i
      assert(result <= killer.processes.high)


# A process has been finished with - remove the process from death row.
# Return true if the process was still present, which will be the
# case unless we have bailed.
proc completed*(index: int): bool {.gcsafe.} =
  result = true
  if index <= killer.processes.high:
    killer.lock.hold:
      result = false
      if killer.processes[index] != nil:
        result = true
        killer.processes[index] = nil


# Terminate all the processes killer knows about, doing nothing if
# already bailed.
proc bail(): bool {.gcsafe.} =
  killer.lock.hold:
    result = not killer.bailed
    if not killer.bailed:
      killer.bailed = true
      for i, process in killer.processes:
        if process != nil:
          process[].terminate
          killer.processes[i] = nil
