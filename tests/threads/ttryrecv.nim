discard """
  outputsub: "channel is empty"
"""

# bug #1816

from math import random
from os import sleep

type PComm = ptr TChannel[int]

proc doAction(outC: PComm) {.thread.} =
  for i in 0.. <5:
    sleep(random(100))
    send(outC[], i)

var
  thr: TThread[PComm]
  chan: TChannel[int]

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
