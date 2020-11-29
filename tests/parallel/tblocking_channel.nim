discard """
output: ""
disabled: "freebsd"
"""
# disabled pending bug #15725
import threadpool, os

var chan: Channel[int]

chan.open(2)
chan.send(1)
chan.send(2)
doAssert(not chan.trySend(3)) # At this point chan is at max capacity

proc receiver() =
    doAssert(chan.recv() == 1)
    doAssert(chan.recv() == 2)
    doAssert(chan.recv() == 3)
    doAssert(chan.recv() == 4)
    doAssert(chan.recv() == 5)

var msgSent = false

proc emitter() =
    chan.send(3)
    msgSent = true

spawn emitter()
# At this point emitter should be stuck in `send`
sleep(50) # Sleep a bit to ensure that it is still stuck
doAssert(not msgSent)

spawn receiver()
sleep(50) # Sleep a bit to let receicer consume the messages
doAssert(msgSent) # Sender should be unblocked

doAssert(chan.trySend(4))
chan.send(5)
sync()
