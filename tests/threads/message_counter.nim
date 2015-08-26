import os
import threadpool

var 
  chanA: TChannel[string]
  chanB: TChannel[string]

proc heavyTaskA() {.thread.} =
  chanA.send("One")
  sleep(400)
  chanA.send("Three")
  sleep(400)
  chanA.close()

proc heavyTaskB() {.thread.} =
  sleep(200)
  chanA.send("Two")
  sleep(400)
  chanA.send("Four")
  chanB.close()

chanA.open()
chanB.open()

var threads = newSeq[TThread[void]](2)
createThread[void](threads[0], heavyTaskA)
createThread[void](threads[1], heavyTaskB)

var counter: int
while not chanA.isClosed() or not chanA.isClosed():
  waitForNextMessage(counter)
  echo "going on, let's check, let's check..."
  var s = ""
  while chanA.tryRecv(s):
    echo "from channelA: ", s
  while chanB.tryRecv(s):
    echo "from channelA: ", s
  
