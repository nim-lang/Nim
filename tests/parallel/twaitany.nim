discard """
  output: '''true'''
"""

# bug #7638
import threadpool, os, strformat

proc timer(d: int): int =
  #echo fmt"sleeping {d}"
  sleep(d)
  #echo fmt"done {d}"
  return d

var durations = [1000, 2000, 3000, 4000, 5000]
var tasks: seq[FlowVarBase] = @[]
var results: seq[int] = @[]

for i in 0 .. durations.high:
  tasks.add spawn timer(durations[i])

var index = awaitAny(tasks)
while index != -1:
  results.add ^cast[FlowVar[int]](tasks[index])
  tasks.del(index)
  #echo repr results
  index = awaitAny(tasks)

doAssert results.len == 5
doAssert 1000 in results
doAssert 2000 in results
doAssert 3000 in results
doAssert 4000 in results
doAssert 5000 in results
sync()
echo "true"
