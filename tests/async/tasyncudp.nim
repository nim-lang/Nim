discard """
  file: "tasyncudp.nim"
  output: "2000"
"""
import asyncio, sockets, strutils, times

const
  swarmSize = 5
  messagesToSend = 200

var
  disp = newDispatcher()
  msgCount = 0
  currentClient = 0

proc serverRead(s: PAsyncSocket) =
  var data = ""
  var address = ""
  var port: TPort
  if s.recvFromAsync(data, 9, address, port):
    assert address == "127.0.0.1"
    msgCount.inc()
  
  discard """
  
  var line = ""
  assert s.recvLine(line)
  
  if line == "":
    assert(false)
  else:
    if line.startsWith("Message "):
      msgCount.inc()
    else:
      assert(false)
  """

proc swarmConnect(s: PAsyncSocket) =
  for i in 1..messagesToSend:
    s.send("Message\c\L")

proc createClient(disp: var PDispatcher, port: TPort,
                  buffered = true) =
  currentClient.inc()
  var client = AsyncSocket(typ = SOCK_DGRAM, protocol = IPPROTO_UDP,
                           buffered = buffered)
  client.handleConnect = swarmConnect
  disp.register(client)
  client.connect("localhost", port)

proc createServer(port: TPort, buffered = true) =
  var server = AsyncSocket(typ = SOCK_DGRAM, protocol = IPPROTO_UDP,
                           buffered = buffered)
  server.handleRead = serverRead
  disp.register(server)
  server.bindAddr(port)

let serverCount = 2

createServer(TPort(10335), false)
createServer(TPort(10336), true)
var startTime = epochTime()
while true:
  if epochTime() - startTime >= 300.0:
    break

  if not disp.poll():
    break
  
  if (msgCount div messagesToSend) * serverCount == currentClient:
    createClient(disp, TPort(10335), false)
    createClient(disp, TPort(10336), true)
  
  if msgCount == messagesToSend * serverCount * swarmSize:
    break

assert msgCount == messagesToSend * serverCount * swarmSize
echo(msgCount)