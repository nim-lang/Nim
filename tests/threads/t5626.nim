import os
import threadpool

type EventChannel = Channel[int]

proc sender(c: ptr EventChannel, starting_from:int) {.thread.} =
  for i in 0..5:
    doAssert c[].trysend(i + starting_from) == true
    echo "sent " & $(i + starting_from)
    sleep 10

proc sender_broken(c: ptr EventChannel, starting_from: int) {.thread.} =
  var chan = c[]
  for i in 0..5:
    doAssert chan.trysend(i + starting_from) == true
    echo "sent " & $(i + starting_from)
    sleep 10

proc receiver(pc: ptr EventChannel, n:int) {.thread.} =
  var chan = pc[]
  chan.open(0)
  while true:
    echo $n & " blocks"
    let x = recv(chan)
    echo($n & " received from chan: " & $x)

var chan: EventChannel
chan.open(0)
spawn sender(addr chan, 0)
spawn sender_broken(addr chan, 100)
spawn sender(addr chan, 200)

spawn receiver(addr chan, 1)
sleep 10
spawn receiver(addr chan, 2)
sleep 10
spawn receiver(addr chan, 3)

sleep 500
echo "Finished listening"

close(chan)
