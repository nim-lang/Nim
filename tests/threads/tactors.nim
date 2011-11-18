discard """
  outputsub: "150"
"""

import actors

var
  a: TActorPool[int, void]
createActorPool(a)
for i in 0 .. < 300:
  a.spawn(i, proc (x: int) {.thread.} = echo x)
a.join()

