discard """
output: '''
triggerCount: 10
'''
"""

import asyncDispatch

var triggerCount = 0
var evs = newSeq[AsyncEvent]()

for i in 0 ..< 10:
  var ev = newAsyncEvent()
  evs.add(ev)
  addEvent(ev, proc(fd: AsyncFD): bool {.gcsafe,closure.} = triggerCount += 1; true)

proc main() {.async.} =
  for ev in evs:
    ev.trigger()
    await sleepAsync(10)
    ev.close

asyncCheck main()
drain()
echo "triggerCount: ", triggerCount
