discard """
  matrix: "--parsem:on --experimental:strictEffects"
  action: "compile"
"""
# `--parsem:on` variant of tests/async/tasyncRecvLine, compile only: the
# lifted environments of two async procs of `asyncnet` are anonymous objects
# with one content key. Sharing hooks by that key alone gave both one
# `=destroy`, and the C compiler rejected the call with the other's type.

import asyncdispatch, asyncnet

const recvLinePort = Port(6048)

proc setupTestServer(): AsyncSocket =
  result = newAsyncSocket()
  result.setSockOpt(OptReuseAddr, true)
  result.bindAddr(recvLinePort)
  result.listen()

proc testUnbuffered(): Future[void] {.async.} =
  let serverSock = setupTestServer()
  let serverAcceptClientFut = serverSock.accept()

  let clientSock = newAsyncSocket(buffered = false)
  let clientConnectFut = clientSock.connect("localhost", recvLinePort)

  let serverAcceptedClient = await serverAcceptClientFut
  await clientConnectFut

  await serverAcceptedClient.send("Hello World\c\L")

  echo await clientSock.recvLine()

  clientSock.close()
  serverSock.close()

proc testBuffered(): Future[void] {.async.} =
  let serverSock = setupTestServer()
  let serverAcceptClientFut = serverSock.accept()

  let clientSock = newAsyncSocket(buffered = true)
  let clientConnectFut = clientSock.connect("localhost", recvLinePort)

  let serverAcceptedClient = await serverAcceptClientFut
  await clientConnectFut

  await serverAcceptedClient.send("Hello World\c\L")

  echo await clientSock.recvLine()

  clientSock.close()
  serverSock.close()

waitFor testUnbuffered()
waitFor testBuffered()
