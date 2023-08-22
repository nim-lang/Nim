discard """
action: compile
"""

import threadpool

var counter = 0

proc increment(x: int) =
  for i in 0 ..< x:
    let value = counter + 1
    counter = value

spawn increment(10_000)
spawn increment(10_000)
sync()
echo(counter)
