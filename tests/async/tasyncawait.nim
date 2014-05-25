discard """
  file: "tasyncawait.nim"
  output: "5000"
"""
import asyncdispatch, rawsockets, net, strutils, os

var msgCount = 0

const
  swarmSize = 50
  messagesToSend = 100

var clientCount = 0

proc sendMessages(client: TAsyncFD) {.async.} =
  for i in 0 .. <messagesToSend:
    await send(client, "Message " & $i & "\c\L")

proc launchSwarm(port: TPort) {.async.} =
  for i in 0 .. <swarmSize:
    var sock = newAsyncRawSocket()

    await connect(sock, "localhost", port)
    when true:
      await sendMessages(sock)
      closeSocket(sock)
    else:
      # Issue #932: https://github.com/Araq/Nimrod/issues/932
      var msgFut = sendMessages(sock)
      msgFut.callback =
        proc () =
          closeSocket(sock)

proc readMessages(client: TAsyncFD) {.async.} =
  while true:
    var line = await recvLine(client)
    if line == "":
      closeSocket(client)
      clientCount.inc
      break
    else:
      if line.startswith("Message "):
        msgCount.inc
      else:
        doAssert false

proc createServer(port: TPort) {.async.} =
  var server = newAsyncRawSocket()
  block:
    var name: TSockaddr_in
    when defined(windows):
      name.sin_family = toInt(AF_INET).int16
    else:
      name.sin_family = toInt(AF_INET)
    name.sin_port = htons(int16(port))
    name.sin_addr.s_addr = htonl(INADDR_ANY)
    if bindAddr(server.TSocketHandle, cast[ptr TSockAddr](addr(name)),
                sizeof(name).TSocklen) < 0'i32:
      osError(osLastError())
  
  discard server.TSocketHandle.listen()
  while true:
    var client = await accept(server)
    readMessages(client)
    # TODO: Test: readMessages(disp, await disp.accept(server))

createServer(TPort(10335))
launchSwarm(TPort(10335))
while true:
  poll()
  if clientCount == swarmSize: break

assert msgCount == swarmSize * messagesToSend
echo msgCount
