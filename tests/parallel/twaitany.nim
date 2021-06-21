discard """
  output: '''true'''
"""

# bug #7638
import threadpool, os

proc timer(d: int): int =
  #echo fmt"sleeping {d}"
  sleep(d)
  #echo fmt"done {d}"
  return d

var durations = [1000, 1500, 2000]
var tasks: seq[FlowVarBase] = @[]
var results: seq[int] = @[]

for i in 0 .. durations.high:
  tasks.add spawn timer(durations[i])

var index = blockUntilAny(tasks)
while index != -1:
  results.add ^cast[FlowVar[int]](tasks[index])
  tasks.del(index)
  #echo repr results
  index = blockUntilAny(tasks)

doAssert results.len == 3
doAssert 1000 in results
doAssert 1500 in results
doAssert 2000 in results
sync()
echo "true"
