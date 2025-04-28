discard """
  cmd: "nim $target --hints:on --define:ssl $options $file"
"""

{.define: ssl.}

import std/[asyncdispatch, asyncnet, net, openssl]

var port0: Port
var checked = 0

proc server {.async.} =
  let sock = newAsyncSocket(AF_INET, SOCK_STREAM, IPPROTO_TCP, buffered = true)
  doAssert sock != nil
  defer: sock.close()
  let sslCtx = newContext(
    protSSLv23,
    verifyMode = CVerifyNone,
    certFile = "tests/testdata/mycert.pem",
    keyFile = "tests/testdata/mycert.pem"
  )
  doAssert sslCtx != nil
  defer: sslCtx.destroyContext()
  wrapSocket(sslCtx, sock)
  #sock.bindAddr(Port 8181)
  sock.bindAddr()
  port0 = getLocalAddr(sock)[1]
  sock.listen()
  echo "accept"
  let clientSocket = await sock.accept()
  defer: clientSocket.close()
  wrapConnectedSocket(
    sslCtx, clientSocket, handshakeAsServer, "localhost"
  )
  let sdata = "x" & newString(41)
  let sfut = clientSocket.send(sdata)
  let rdata = newString(42)
  let rfut = clientSocket.recvInto(addr rdata[0], rdata.len)
  echo "send"
  await sfut
  echo "recv"
  let rLen = await rfut  # it hang here until the client closes the connection or sends more data
  doAssert rLen == 42, $rLen
  doAssert rdata[0] == 'x', $rdata[0]
  echo "ok"
  inc checked

proc client {.async.} =
  let sock = newAsyncSocket(AF_INET, SOCK_STREAM, IPPROTO_TCP, buffered = true)
  doAssert sock != nil
  defer: sock.close()
  let sslCtx = newContext(
    protSSLv23,
    verifyMode = CVerifyNone
  )
  doAssert sslCtx != nil
  defer: sslCtx.destroyContext()
  wrapSocket(sslCtx, sock)
  #await sock.connect("127.0.0.1", Port 8181)
  await sock.connect("localhost", port0)
  let sdata = "x" & newString(41)
  echo "send"
  await sock.send(sdata)
  let rdata = newString(42)
  echo "recv"
  let rLen = await sock.recvInto(addr rdata[0], rdata.len)
  doAssert rLen == 42, $rLen
  doAssert rdata[0] == 'x', $rdata[0]
  #await sleepAsync(10_000)
  #await sock.send("x")
  echo "ok"
  inc checked

discard getGlobalDispatcher()
let serverFut = server()
waitFor client()
waitFor serverFut
doAssert checked == 2
doAssert not hasPendingOperations()
