discard """
  cmd: "nim $target --hints:on --define:ssl $options $file"
  output: "500"
  disabled: "windows"
  target: c
  action: compile
"""

# XXX, deactivated

import asyncdispatch, asyncnet, net, strutils, os

when defined(ssl):
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
        if line.startswith("Message "):
          inc(msgCount)
        else:
          doAssert false

  proc createServer(port: Port) {.async.} =
    let serverContext = newContext(verifyMode = CVerifyNone,
                                   certFile = "tests/testdata/mycert.pem",
                                   keyFile = "tests/testdata/mycert.pem")
    var server = newAsyncSocket()
    serverContext.wrapSocket(server)
    server.setSockOpt(OptReuseAddr, true)
    bindAddr(server, port)
    server.listen()
    while true:
      let client = await accept(server)
      serverContext.wrapConnectedSocket(client, handshakeAsServer)
      asyncCheck readMessages(client)

  asyncCheck createServer(Port(10335))
  asyncCheck launchSwarm(Port(10335))
  while true:
    poll()
    if clientCount == swarmSize: break

  assert msgCount == swarmSize * messagesToSend
  echo msgCount
