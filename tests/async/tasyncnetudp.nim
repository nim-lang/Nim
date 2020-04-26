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
  var
    buffer = newString(16384)
    i = 0

  while i < swarmSize:
    var sock = newAsyncSocket(nativesockets.AF_INET, nativesockets.SOCK_DGRAM,
                              Protocol.IPPROTO_UDP, false)

    bindAddr(sock, address = "127.0.0.1")

    let (null, localPort) = getLocalAddr(sock)

    var k = 0
    
    while k < messagesToSend:
      zeroMem(addr(buffer[0]), 16384)

      let message = "Message " & $(i * messagesToSend + k)

      await sendTo(sock, message, serverIp, serverPort)

      let (size, fromIp, fromPort) = await recvFrom(sock, addr buffer[0],
                                                    16384)

      if buffer[0 .. (size - 1)] == message:
        saveSendingPort(localPort)

        inc(recvCount)

      inc(k)
    
    close(sock)

    inc(i)

proc readMessages(server: AsyncSocket) {.async.} =
  let maxResponses = (swarmSize * messagesToSend)

  var
    buffer = newString(16384)
    i = 0
  
  while i < maxResponses:
    zeroMem(addr(buffer[0]), 16384)
    
    let (size, fromIp, fromPort) = await recvFrom(server, addr buffer[0], 16384)

    if buffer.startswith("Message ") and fromIp == "127.0.0.1":
      await sendTo(server, buffer[0 .. (size - 1)], fromIp, fromPort)

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

assert msgCount == swarmSize * messagesToSend
assert sendports == recvports

echo msgCount