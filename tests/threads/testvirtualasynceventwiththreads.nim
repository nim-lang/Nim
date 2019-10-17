discard """
output: '''
triggerCount: 1000
'''
"""

import asyncDispatch, threadpool, os, random

var triggerCount = 0
var evs = newSeq[VirtualAsyncEvent]()

proc threadTask(ev: VirtualAsyncEvent) =
  sleep(rand(1000))
  ev.trigger()

for i in 0 ..< 1000:
  var ev = newVirtualAsyncEvent()
  evs.add ev
  addEvent(ev, proc(fd: AsyncFD): bool {.gcsafe,closure.} = triggerCount += 1; true)
  spawn(threadTask(ev))

drain()
echo "triggerCount: ", triggerCount
