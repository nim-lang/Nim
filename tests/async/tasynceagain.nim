discard """
  disabled: "windows"
  exitcode: 0
"""
# AsyncSocketBug.nim
# Jens Alfke (@snej) -- 16 July 2020
# Demonstrates data loss by Nim's AsyncSocket.
# Just run it, and it will raise an assertion failure within a minute.

import asyncdispatch, asyncnet, strformat, strutils, sugar

const FrameSize = 9999   # Exact size not important, but larger sizes fail quicker

proc runServer() {.async.} =
  # Server side:
  var server = newAsyncSocket()
  server.bindAddr(Port(9001))
  server.listen()
  let client = await server.accept()
  echo "Server got client connection"
  var lastN = 0
  while true:
    let frame = await client.recv(FrameSize)
    doAssert frame.len == FrameSize
    let n = frame[0..<6].parseInt()
    echo "RCVD #", n, ":  ", frame[0..80], "..."
    if n != lastN + 1:
      echo &"******** ERROR: Server received #{n}, but last was #{lastN}!"
    doAssert n == lastN + 1
    lastN = n
    await sleepAsync 100


proc main() {.async.} =
  asyncCheck runServer()

  # Client side:
  let socket = newAsyncSocket(buffered = false)
  await socket.connect("localhost", Port(9001))
  echo "Client socket connected"

  var sentCount = 0
  var completedCount = 0

  while sentCount < 2000:
    sentCount += 1
    let n = sentCount

    var message = &"{n:06} This is message #{n} of ∞. Please stay tuned for more. "
    #echo ">>> ", message
    while message.len < FrameSize:
      message = message & message
    let frame = message[0..<FrameSize]

    capture n:
      socket.send(frame).addCallback proc(f: Future[void]) =
        # Callback when the send completes:
        assert not f.failed
        echo "SENT #", n
        if n != completedCount + 1:
          echo &"******** ERROR: Client completed #{n}, but last completed was #{completedCount}!"
        # If this assert is enabled, it will trigger earlier than the server-side assert above:
        assert n == completedCount + 1
        completedCount = n
    await sleepAsync 1

waitFor main()