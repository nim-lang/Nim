discard """
  outputsub: "101"
  cmd: "nim $target --hints:on --threads:on $options $file"
"""

import os, locks

const
  noDeadlocks = defined(preventDeadlocks)

var
  thr: array [0..5, TThread[tuple[a, b: int]]]
  L, M, N: TLock

proc doNothing() = discard

proc threadFunc(interval: tuple[a, b: int]) {.thread.} = 
  doNothing()
  for i in interval.a..interval.b: 
    when nodeadlocks:
      case i mod 6
      of 0:
        acquire(L) # lock stdout
        acquire(M)
        acquire(N)
      of 1:
        acquire(L)
        acquire(N) # lock stdout
        acquire(M)
      of 2:
        acquire(M)
        acquire(L)
        acquire(N)
      of 3:
        acquire(M)
        acquire(N)
        acquire(L)
      of 4:
        acquire(N)
        acquire(M)
        acquire(L)
      of 5:
        acquire(N)
        acquire(L)
        acquire(M)
      else: assert false
    else:
      acquire(L) # lock stdout
      acquire(M)
      
    echo i
    os.sleep(10)
    when nodeadlocks:
      echo "deadlocks prevented: ", deadlocksPrevented
    when nodeadlocks:
      release(N)
    release(M)
    release(L)

initLock(L)
initLock(M)
initLock(N)

proc main =
  for i in 0..high(thr):
    createThread(thr[i], threadFunc, (i*100, i*100+50))
  joinThreads(thr)

main()

