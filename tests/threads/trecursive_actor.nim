discard """
  outputsub: "0"
"""

import actors

var
  a: TActorPool[int, void]
createActorPool(a)

proc task(i: int) {.thread.} =
  echo i
  if i != 0: a.spawn (i-1, task)

# count from 9 till 0 and check 0 is somewhere in the output
a.spawn(9, task)
a.join()
