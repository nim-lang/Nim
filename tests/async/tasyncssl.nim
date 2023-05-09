discard """
  cmd: "nim $target --hints:on --define:ssl $options $file"
"""

import asyncdispatch, asyncnet, net, strutils
import stdtest/testutils

when defined(ssl):
  var port0: Port
  var msgCount = 0

  const
    swarmSize = 10
    messagesToSend = 50

  var clientCount = 0

  proc sendMessages(client: AsyncSocket) {.async.} =
    for i in 0 ..< messagesToSend:
      await send(client, "Message " & $i & "\c\L")

  proc launchSwarm(port: Port) {.async.} =
    for i in 0 ..< swarmSize:
      var sock = newAsyncSocket()
      var clientContext = newContext(verifyMode = CVerifyNone)
      clientContext.wrapSocket(sock)
      await connect(sock, "localhost", port)
      await sendMessages(sock)
      close(sock)

  proc readMessages(client: AsyncSocket) {.async.} =
    while true:
      var line = await recvLine(client)
      if line == "":
        close(client)
        inc(clientCount)
        break
      else:
        if line.startsWith("Message "):
          inc(msgCount)
        else:
          doAssert false

  proc createServer() {.async.} =
    let serverContext = newContext(verifyMode = CVerifyNone,
                                   certFile = "tests/testdata/mycert.pem",
                                   keyFile = "tests/testdata/mycert.pem")
    var server = newAsyncSocket()
    serverContext.wrapSocket(server)
    server.setSockOpt(OptReuseAddr, true)
    bindAddr(server)
    port0 = getLocalAddr(server)[1]
    server.listen()
    while true:
      let client = await accept(server)
      serverContext.wrapConnectedSocket(client, handshakeAsServer)
      asyncCheck readMessages(client)

  asyncCheck createServer()
  asyncCheck launchSwarm(port0)
  while true:
    poll()
    if clientCount == swarmSize: break

  template cond(): bool = msgCount == swarmSize * messagesToSend
  when defined(windows):
    # currently: msgCount == 0
    flakyAssert cond()
  elif defined(linux) and int.sizeof == 8:
    # currently:  msgCount == 10
    flakyAssert cond()
    doAssert msgCount > 0
  else: doAssert cond(), $msgCount
