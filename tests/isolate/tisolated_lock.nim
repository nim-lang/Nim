discard """
  cmd: "nim $target --threads:on $options $file"
  action: "compile"
"""

import std / [os, locks, atomics, isolation]

type
  MyList {.acyclic.} = ref object
    data: string
    next: Isolated[MyList]

template withMyLock*(a: Lock, body: untyped) =
  acquire(a)
  {.gcsafe.}:
    try:
      body
    finally:
      release(a)

var head: Isolated[MyList]
var headL: Lock

var shouldStop: Atomic[bool]

initLock headL

proc send(x: sink string) =
  withMyLock headL:
    head = isolate MyList(data: x, next: move head)

proc worker() {.thread.} =
  var workItem = MyList(nil)
  var echoed = 0
  while true:
    withMyLock headL:
      var h = extract head
      if h != nil:
        workItem = h
        # workitem is now isolated:
        head = move h.next
      else:
        workItem = nil
    # workItem is isolated, so we can access it outside
    # the lock:
    if workItem.isNil:
      if shouldStop.load:
        break
      else:
        # give producer time to breath:
        os.sleep 30
    else:
      if echoed < 100:
        echo workItem.data
      inc echoed

var thr: Thread[void]
createThread(thr, worker)

send "abc"
send "def"
for i in 0 ..< 10_000:
  send "xzy"
  send "zzz"
shouldStop.store true

joinThread(thr)
