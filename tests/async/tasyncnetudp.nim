# It is a reproduction of the 'tnewasyncudp' test code, but using a high level
# of asynchronous procedures. Output: "5000"
import asyncdispatch, asyncnet, nativesockets, net, strutils

var msgCount = 0
var recvCount = 0

const
  messagesToSend = 100
  swarmSize = 50
  serverPort = 10333

var
  sendports = 0
  recvports = 0

proc saveSendingPort(port: Port) =
  sendports = sendports + int(port)

proc saveReceivedPort(port: Port) =
  recvports = recvports + int(port)

proc launchSwarm(serverIp: string, serverPort: Port) {.async.} =
  var i = 0

  while i < swarmSize:
    var sock = newAsyncSocket(nativesockets.AF_INET, nativesockets.SOCK_DGRAM,
                              Protocol.IPPROTO_UDP, false)

    bindAddr(sock, address = "127.0.0.1")

    let (null, localPort) = getLocalAddr(sock)

    var k = 0
    
    while k < messagesToSend:
      let message = "Message " & $(i * messagesToSend + k)

      await asyncnet.sendTo(sock, serverIp, serverPort, message)

      let (data, fromIp, fromPort) = await recvFrom(sock, 16384)

      if data == message:
        saveSendingPort(localPort)

        inc(recvCount)

      inc(k)
    
    close(sock)

    inc(i)

proc readMessages(server: AsyncSocket) {.async.} =
  let maxResponses = (swarmSize * messagesToSend)

  var i = 0
  
  while i < maxResponses:
    let (data, fromIp, fromPort) = await recvFrom(server, 16384)

    if data.startsWith("Message ") and fromIp == "127.0.0.1":
      await sendTo(server, fromIp, fromPort, data)

      inc(msgCount)

      saveReceivedPort(fromPort)

    inc(i)

proc createServer() {.async.} =
  var server = newAsyncSocket(nativesockets.AF_INET, nativesockets.SOCK_DGRAM, Protocol.IPPROTO_UDP, false)
  
  bindAddr(server, Port(serverPort), "127.0.0.1")

  asyncCheck readMessages(server)

asyncCheck createServer()
asyncCheck launchSwarm("127.0.0.1", Port(serverPort))

while true:
  poll()

  if recvCount == swarmSize * messagesToSend:
    break

doAssert msgCount == swarmSize * messagesToSend
doAssert sendports == recvports

echo msgCount