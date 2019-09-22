discard """
output: '''
runForever should throw ValueError, this is expected
triggerCount: 100
'''
"""

import asyncDispatch

var triggerCount = 0
var evs = newSeq[AsyncEvent]()

for i in 0 ..< 100:
  var ev = newAsyncEvent()
  evs.add(ev)
  addEvent(ev, proc(fd: AsyncFD): bool {.gcsafe,closure.} = triggerCount += 1; true)

proc main() {.async.} =
  for ev in evs:
    await sleepAsync(10)
    ev.trigger()

try:
  asyncCheck main()
  runForever()
except ValueError:
  echo "runForever should throw ValueError, this is expected"
  echo "triggerCount: ", triggerCount
