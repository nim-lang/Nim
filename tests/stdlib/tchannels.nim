discard """
  matrix: "--gc:orc --threads:on -d:danger"
"""

import std/[channels, isolation]

var
  sender: array[10, Thread[void]]
  receiver: array[5, Thread[void]] 

var chan = newChannel[seq[string]](40)
proc sendHandler() =
  chan.send(isolate(@["Hello, Nim"]))
proc recvHandler() =
  var x = chan.recv()
  discard x

template benchmark() =
  for t in mitems(sender):
    t.createThread(sendHandler)
  joinThreads(sender)
  for i in 0 .. receiver.high:
    createThread(receiver[i], recvHandler)
  joinThreads(receiver)

benchmark()