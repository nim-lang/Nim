discard """
  outputsub: "101"
"""

import os

const
  noDeadlocks = defined(system.deadlocksPrevented)

var
  thr: array [0..5, TThread[tuple[a, b: int]]]
  L, M, N: TLock

proc doNothing() = nil

proc threadFunc(interval: tuple[a, b: int]) {.procvar.} = 
  doNothing()
  for i in interval.a..interval.b: 
    when nodeadlocks:
      case i mod 6
      of 0:
        Aquire(L) # lock stdout
        Aquire(M)
        Aquire(N)
      of 1:
        Aquire(L)
        Aquire(N) # lock stdout
        Aquire(M)
      of 2:
        Aquire(M)
        Aquire(L)
        Aquire(N)
      of 3:
        Aquire(M)
        Aquire(N)
        Aquire(L)
      of 4:
        Aquire(N)
        Aquire(M)
        Aquire(L)
      of 5:
        Aquire(N)
        Aquire(L)
        Aquire(M)
      else: assert false
    else:
      Aquire(L) # lock stdout
      Aquire(M)
      
    echo i
    os.sleep(10)
    when nodeadlocks:
      echo "deadlocks prevented: ", deadlocksPrevented
    when nodeadlocks:
      Release(N)
    Release(M)
    Release(L)

InitLock(L)
InitLock(M)
InitLock(N)

proc main =
  for i in 0..high(thr):
    createThread(thr[i], threadFunc, (i*100, i*100+50))
  joinThreads(thr)

main()

