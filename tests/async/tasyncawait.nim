discard """
  file: "tasyncawait.nim"
  cmd: "nimrod cc --hints:on $# $#"
  output: "5000"
"""
import asyncio2, sockets2, net, strutils, os

var disp = newDispatcher()
var msgCount = 0

const
  swarmSize = 50
  messagesToSend = 100

var clientCount = 0

proc sendMessages(disp: PDispatcher, client: TSocketHandle) {.async.} =
  for i in 0 .. <messagesToSend:
    await disp.send(client, "Message " & $i & "\c\L")

proc launchSwarm(disp: PDispatcher, port: TPort) {.async.} =
  for i in 0 .. <swarmSize:
    var sock = disp.socket()

    #disp.register(sock)
    await disp.connect(sock, "localhost", port)
    when true:
      await sendMessages(disp, sock)
      disp.close(sock)
    else:
      # Issue #932: https://github.com/Araq/Nimrod/issues/932
      var msgFut = sendMessages(disp, sock)
      msgFut.callback =
        proc () =
          disp.close(sock)

proc readMessages(disp: PDispatcher, client: TSocketHandle) {.async.} =
  while true:
    var line = await disp.recvLine(client)
    if line == "":
      disp.close(client)
      clientCount.inc
      break
    else:
      if line.startswith("Message "):
        msgCount.inc
      else:
        doAssert false

proc createServer(disp: PDispatcher, port: TPort) {.async.} =
  var server = disp.socket()
  #disp.register(server)
  block:
    var name: TSockaddr_in
    when defined(windows):
      name.sin_family = toInt(AF_INET).int16
    else:
      name.sin_family = toInt(AF_INET)
    name.sin_port = htons(int16(port))
    name.sin_addr.s_addr = htonl(INADDR_ANY)
    if bindAddr(server, cast[ptr TSockAddr](addr(name)),
                  sizeof(name).TSocklen) < 0'i32:
      osError(osLastError())
  
  discard server.listen()
  while true:
    var client = await disp.accept(server)
    readMessages(disp, client)
    # TODO: Test: readMessages(disp, await disp.accept(server))

disp.createServer(TPort(10335))
disp.launchSwarm(TPort(10335))
while true:
  disp.poll()
  if clientCount == swarmSize: break

assert msgCount == swarmSize * messagesToSend
echo msgCount
