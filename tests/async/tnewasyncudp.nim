discard """
  output: "5000"
"""
import asyncdispatch, nativesockets, net, strutils, os

when defined(windows):
  import winlean
else:
  import posix

var msgCount = 0
var recvCount = 0

const
  messagesToSend = 100
  swarmSize = 50
  serverPort = 10333

var
  sendports = 0
  recvports = 0

proc saveSendingPort(port: int) =
  sendports = sendports + port

proc saveReceivedPort(port: int) =
  recvports = recvports + port

proc prepareAddress(intaddr: uint32, intport: uint16): ptr Sockaddr_in =
  result = cast[ptr Sockaddr_in](alloc0(sizeof(Sockaddr_in)))
  result.sin_family = typeof(result.sin_family)(toInt(nativesockets.AF_INET))
  result.sin_port = nativesockets.htons(intport)
  result.sin_addr.s_addr = nativesockets.htonl(intaddr)

proc launchSwarm(name: ptr SockAddr) {.async.} =
  var i = 0
  var k = 0
  var buffer: array[16384, char]
  var slen = sizeof(Sockaddr_in).SockLen
  var saddr = Sockaddr_in()
  while i < swarmSize:
    var peeraddr = prepareAddress(INADDR_LOOPBACK, 0)
    var sock = createAsyncNativeSocket(nativesockets.AF_INET,
                                       nativesockets.SOCK_DGRAM,
                                       Protocol.IPPROTO_UDP)
    if bindAddr(sock.SocketHandle, cast[ptr SockAddr](peeraddr),
              sizeof(Sockaddr_in).Socklen) < 0'i32:
      raiseOSError(osLastError())
    let sockport = getSockName(sock.SocketHandle).int
    k = 0
    while k < messagesToSend:
      zeroMem(addr(buffer[0]), 16384)
      zeroMem(cast[pointer](addr(saddr)), sizeof(Sockaddr_in))
      var message = "Message " & $(i * messagesToSend + k)
      await sendTo(sock, addr message[0], len(message),
                   name, sizeof(Sockaddr_in).SockLen)
      var size = await recvFromInto(sock, cast[pointer](addr buffer[0]),
                                    16384, cast[ptr SockAddr](addr saddr),
                                    addr slen)
      size = 0
      var grammString = $cast[cstring](addr buffer)
      if grammString == message:
        saveSendingPort(sockport)
        inc(recvCount)
      inc(k)
    closeSocket(sock)
    inc(i)

proc readMessages(server: AsyncFD) {.async.} =
  var buffer: array[16384, char]
  var slen = sizeof(Sockaddr_in).SockLen
  var saddr = Sockaddr_in()
  var maxResponses = (swarmSize * messagesToSend)

  var i = 0
  while i < maxResponses:
    zeroMem(addr(buffer[0]), 16384)
    zeroMem(cast[pointer](addr(saddr)), sizeof(Sockaddr_in))
    var size = await recvFromInto(server, cast[cstring](addr buffer[0]),
                                  16384, cast[ptr SockAddr](addr(saddr)),
                                  addr(slen))
    size = 0
    var grammString = $cast[cstring](addr buffer)
    if grammString.startsWith("Message ") and
       saddr.sin_addr.s_addr == nativesockets.ntohl(INADDR_LOOPBACK.uint32):
      await sendTo(server, addr grammString[0], len(grammString),
                   cast[ptr SockAddr](addr saddr), slen)
      inc(msgCount)
      saveReceivedPort(nativesockets.ntohs(saddr.sin_port).int)
    inc(i)

proc createServer() {.async.} =
  var name = prepareAddress(INADDR_LOOPBACK, serverPort)
  var server = createAsyncNativeSocket(nativesockets.AF_INET,
                                       nativesockets.SOCK_DGRAM,
                                       Protocol.IPPROTO_UDP)
  if bindAddr(server.SocketHandle, cast[ptr SockAddr](name),
              sizeof(Sockaddr_in).Socklen) < 0'i32:
    raiseOSError(osLastError())
  asyncCheck readMessages(server)

var name = prepareAddress(INADDR_LOOPBACK, serverPort) # 127.0.0.1
asyncCheck createServer()
asyncCheck launchSwarm(cast[ptr SockAddr](name))
while true:
  poll()
  if recvCount == swarmSize * messagesToSend:
    break
assert msgCount == swarmSize * messagesToSend
assert sendports == recvports
echo msgCount
