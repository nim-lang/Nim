discard """
  matrix: "--threads:on --gc:orc; --threads:on --gc:arc"
  disabled: "freebsd"
"""

import std/channels
import std/os

var chan = newChannel[string]()

# This proc will be run in another thread using the threads module.
proc firstWorker() =
  chan.send("Hello World!")

# This is another proc to run in a background thread. This proc takes a while
# to send the message since it sleeps for 2 seconds (or 2000 milliseconds).
proc secondWorker() =
  sleep(2000)
  chan.send("Another message")


# Launch the worker.
var worker1: Thread[void]
createThread(worker1, firstWorker)

# Block until the message arrives, then print it out.
var dest = ""
chan.recv(dest)
doAssert dest == "Hello World!"

# Wait for the thread to exit before moving on to the next example.
worker1.joinThread()

# Launch the other worker.
var worker2: Thread[void]
createThread(worker2, secondWorker)
# This time, use a non-blocking approach with tryRecv.
# Since the main thread is not blocked, it could be used to perform other
# useful work while it waits for data to arrive on the channel.

var messages: seq[string]
var msg = ""
while true:
  let tried = chan.tryRecv(msg)
  if tried:
    messages.add move(msg)
    break
  
  messages.add "Pretend I'm doing useful work..."
  # For this example, sleep in order not to flood stdout with the above
  # message.
  sleep(400)

# Wait for the second thread to exit before cleaning up the channel.
worker2.joinThread()

# Clean up the channel.
doAssert chan.close()
doAssert messages[^1] == "Another message"
doAssert messages.len >= 2


block:
  let chan0 = newChannel[int]()
  let chan1 = chan0
  block:
    let chan3 = chan0
    let chan4 = chan0
