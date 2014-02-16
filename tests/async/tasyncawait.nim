discard """
  file: "tasyncawait.nim"
  cmd: "nimrod cc --hints:on $# $#"
  output: "5000"
"""
import asyncio2, sockets2, net, strutils

var disp = newDispatcher()
var msgCount = 0

const
  swarmSize = 50
  messagesToSend = 100

var clientCount = 0

proc sendMessages(disp: PDispatcher, client: TSocketHandle): PFuture[int] {.async.} =
  for i in 0 .. <messagesToSend:
    discard await disp.send(client, "Message " & $i & "\c\L") 

proc launchSwarm(disp: PDispatcher, port: TPort): PFuture[int] {.async.} =
  for i in 0 .. <swarmSize:
    var sock = socket()
    disp.register(sock)
    discard await disp.connect(sock, "localhost", port)
    when true:
      discard await sendMessages(disp, sock)
      sock.close()
    else:
      # Issue #932: https://github.com/Araq/Nimrod/issues/932
      var msgFut = sendMessages(disp, sock)
      msgFut.callback =
        proc () =
          sock.close()

proc readMessages(disp: PDispatcher, client: TSocketHandle): PFuture[int] {.async.} =
  while true:
    var line = await disp.recvLine(client)
    if line == "":
      client.close()
      clientCount.inc
      break
    else:
      if line.startswith("Message "):
        msgCount.inc
      else:
        doAssert false

proc createServer(disp: PDispatcher, port: TPort): PFuture[int] {.async.} =
  var server = socket()
  disp.register(server)
  server.bindAddr(port)
  server.listen()
  while true:
    var client = await disp.accept(server)
    discard readMessages(disp, client)

discard disp.createServer(TPort(10335))
discard disp.launchSwarm(TPort(10335))
while true:
  disp.poll()
  if clientCount == swarmSize: break

assert msgCount == swarmSize * messagesToSend
echo msgCount
