discard """
  outputsub: "150"
"""

import actors

var
  pool: ActorPool[int, void]
createActorPool(pool)
for i in 0 ..< 300:
  pool.spawn(i, proc (x: int) {.thread.} = echo x)
pool.join()

