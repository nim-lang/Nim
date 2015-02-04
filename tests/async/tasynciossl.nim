discard """
  file: "tasynciossl.nim"
  cmd: "nim $target --hints:on --define:ssl $options $file"
  output: "20000"
"""
import sockets, asyncio, strutils, times

var disp {.threadvar.}: PDispatcher
disp = newDispatcher()
var msgCount = 0

when defined(ssl):
  var ctx = newContext(verifyMode = CVerifyNone,
      certFile = "tests/testdata/mycert.pem", keyFile = "tests/testdata/mycert.pem")

  var ctx1 = newContext(verifyMode = CVerifyNone)

const
  swarmSize = 50
  messagesToSend = 100

proc swarmConnect(s: PAsyncSocket) =
  #echo("Connected")
  for i in 1..messagesToSend:
    s.send("Message " & $i & "\c\L")
  s.close()

proc serverRead(s: PAsyncSocket) =
  var line = ""
  assert s.readLine(line)
  if line != "":
    #echo(line)
    if line.startsWith("Message "):
      msgCount.inc()
    else:
      assert(false)
  else:
    s.close()

proc serverAccept(s: PAsyncSocket) =
  var client: PAsyncSocket
  new(client)
  s.accept(client)
  client.handleRead = serverRead
  disp.register(client)

proc launchSwarm(disp: var PDispatcher, port: TPort, count: int,
                 buffered = true, useSSL = false) =
  for i in 1..count:
    var client = asyncSocket()
    when defined(ssl):
      if useSSL:
        ctx1.wrapSocket(client)
    client.handleConnect = swarmConnect
    disp.register(client)
    client.connect("localhost", port)

proc createSwarm(port: TPort, buffered = true, useSSL = false) =
  var server = asyncSocket()
  when defined(ssl):
    if useSSL:
      ctx.wrapSocket(server)
  server.handleAccept = serverAccept
  disp.register(server)
  server.bindAddr(port)
  server.listen()
  disp.launchSwarm(port, swarmSize, buffered, useSSL)

when defined(ssl):
  const serverCount = 4
else:
  const serverCount = 2

createSwarm(TPort(10235))
createSwarm(TPort(10236), false)

when defined(ssl):
  createSwarm(TPort(10237), true, true)
  createSwarm(TPort(10238), false, true)

var startTime = epochTime()
while true:
  if epochTime() - startTime >= 300.0:
    break
  if not disp.poll(): break
  if disp.len == serverCount:
    # Only the servers are left in the dispatcher. All clients finished,
    # we need to therefore break.
    break

assert msgCount == (swarmSize * messagesToSend) * serverCount
echo(msgCount)
