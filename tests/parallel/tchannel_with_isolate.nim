discard """
output: "Got: (value: (foo: 3))"
"""

import std/isolation

type
  Msg = object
    foo: int

var chan: Channel[Isolated[Msg]]
chan.open()

proc worker() {.thread.} =
  let msg = Msg(foo: 3)
  chan.send(isolate(msg))

var workerThread: Thread[void]
createThread(workerThread, worker)

proc main() =
  let val = chan.recv()
  echo "Got: ", val

when isMainModule:
  main()
  chan.close()
