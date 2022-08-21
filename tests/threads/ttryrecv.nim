discard """
  outputsub: "channel is empty"
"""

# bug #1816

from random import rand
from os import sleep

type PComm = ptr Channel[int]

proc doAction(outC: PComm) {.thread.} =
  for i in 0 ..< 5:
    sleep(rand(50))
    send(outC[], i)

var
  thr: Thread[PComm]
  chan: Channel[int]

open(chan)
createThread[PComm](thr, doAction, addr(chan))

while true:
  let (flag, x) = tryRecv(chan)
  if flag:
    echo("received from chan: " & $x)
  else:
    echo "channel is empty"
    break

echo "Finished listening"

joinThread(thr)
close(chan)
