discard """
  errormsg: "unguarded access: counter"
  line: 14
"""

import threadpool, locks

var counterLock: Lock
initLock(counterLock)
var counter {.guard: counterLock.} = 0

proc increment(x: int) =
  for i in 0 ..< x:
    let value = counter + 1
    counter = value

spawn increment(10_000)
spawn increment(10_000)
sync()
echo(counter)
