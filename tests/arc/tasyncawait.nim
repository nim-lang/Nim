discard """
  outputsub: "result: 5000"
  cmd: "nim c --gc:orc $file"
"""

import asyncdispatch, asyncnet, nativesockets, net, strutils
from stdtest/netutils import bindAvailablePort

var msgCount = 0

const
  swarmSize = 50
  messagesToSend = 100

var clientCount = 0

proc sendMessages(client: AsyncFD) {.async.} =
  for i in 0 ..< messagesToSend:
    await send(client, "Message " & $i & "\c\L")

proc launchSwarm(port: Port) {.async.} =
  for i in 0 ..< swarmSize:
    var sock = createAsyncNativeSocket()

    await connect(sock, "localhost", port)
    await sendMessages(sock)
    closeSocket(sock)

proc readMessages(client: AsyncFD) {.async.} =
  # wrapping the AsyncFd into a AsyncSocket object
  var sockObj = newAsyncSocket(client)
  var (ipaddr, port) = sockObj.getPeerAddr()
  doAssert ipaddr == "127.0.0.1"
  (ipaddr, port) = sockObj.getLocalAddr()
  doAssert ipaddr == "127.0.0.1"
  while true:
    var line = await recvLine(sockObj)
    if line == "":
      closeSocket(client)
      clientCount.inc
      break
    else:
      if line.startsWith("Message "):
        msgCount.inc
      else:
        doAssert false

proc createServer(server: AsyncFD) {.async.} =
  discard server.SocketHandle.listen()
  while true:
    asyncCheck readMessages(await accept(server))

proc main =
  let server = createAsyncNativeSocket()
  let port = bindAvailablePort(server.SocketHandle)
  asyncCheck createServer(server)
  asyncCheck launchSwarm(port)
  while true:
    poll()
    if clientCount == swarmSize: break

let mem = getOccupiedMem()
main()

doAssert msgCount == swarmSize * messagesToSend
echo "result: ", msgCount
GC_fullCollect()
echo "memory: ", formatSize(getOccupiedMem() - mem)
