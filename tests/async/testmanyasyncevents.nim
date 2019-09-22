discard """
output: '''
triggerCount: 8000
'''
"""

import asyncDispatch

var triggerCount = 0
var evs = newSeq[AsyncEvent]()

for i in 0 ..< 8000: # some number way higher than the typical physical fd limit
  var ev = newAsyncEvent()
  evs.add(ev)
  addEvent(ev, proc(fd: AsyncFD): bool {.gcsafe,closure.} = triggerCount += 1; true)

for ev in evs:
  ev.trigger()

drain()
echo "triggerCount: ", triggerCount
