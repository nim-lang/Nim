#
#
#            Nim's Runtime Library
#        (c) Copyright 2014 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a high-level asynchronous sockets API based on the
## asynchronous dispatcher defined in the ``asyncdispatch`` module.
##
## Example
## =======
## 
## The following example demonstrates a simple chat server.
##
## .. code-block::nim
##
##   import asyncnet, asyncdispatch
##
##   var clients: seq[AsyncSocket] = @[]
##
##   proc processClient(client: AsyncSocket) {.async.} =
##     while true:
##       let line = await client.recvLine()
##       for c in clients:
##         await c.send(line & "\c\L")
##
##   proc serve() {.async.} =
##     var server = newAsyncSocket()
##     server.bindAddr(Port(12345))
##     server.listen()
##
##     while true:
##       let client = await server.accept()
##       clients.add client
##
##       asyncCheck processClient(client)
##
##   asyncCheck serve()
##   runForever()
##
##
## **Note:** This module is still largely experimental.

import asyncdispatch
import rawsockets
import net
import os

when defined(ssl):
  import openssl

type
  # TODO: I would prefer to just do:
  # PAsyncSocket* {.borrow: `.`.} = distinct PSocket. But that doesn't work.
  AsyncSocketDesc  = object
    fd*: SocketHandle
    case isBuffered*: bool # determines whether this socket is buffered.
    of true:
      buffer*: array[0..BufferSize, char]
      currPos*: int # current index in buffer
      bufLen*: int # current length of buffer
    of false: nil
    case isSsl: bool
    of true:
      when defined(ssl):
        sslHandle: SslPtr
        sslContext: SslContext
        bioIn: BIO
        bioOut: BIO
    of false: nil
  AsyncSocket* = ref AsyncSocketDesc

{.deprecated: [PAsyncSocket: AsyncSocket].}

# TODO: Save AF, domain etc info and reuse it in procs which need it like connect.

proc newSocket(fd: TAsyncFD, isBuff: bool): PAsyncSocket =
  assert fd != osInvalidSocket.TAsyncFD
  new(result)
  result.fd = fd.SocketHandle
  result.isBuffered = isBuff
  if isBuff:
    result.currPos = 0

proc newAsyncSocket*(domain: TDomain = AF_INET, typ: TType = SOCK_STREAM,
    protocol: TProtocol = IPPROTO_TCP, buffered = true): PAsyncSocket =
  ## Creates a new asynchronous socket.
  result = newSocket(newAsyncRawSocket(domain, typ, protocol), buffered)

when defined(ssl):
  proc getSslError(handle: SslPtr, err: cint): cint =
    assert err < 0
    var ret = SSLGetError(handle, err.cint)
    case ret
    of SSL_ERROR_ZERO_RETURN:
      raiseSSLError("TLS/SSL connection failed to initiate, socket closed prematurely.")
    of SSL_ERROR_WANT_CONNECT, SSL_ERROR_WANT_ACCEPT:
      return ret
    of SSL_ERROR_WANT_WRITE, SSL_ERROR_WANT_READ:
      return ret
    of SSL_ERROR_WANT_X509_LOOKUP:
      raiseSSLError("Function for x509 lookup has been called.")
    of SSL_ERROR_SYSCALL, SSL_ERROR_SSL:
      raiseSSLError()
    else: raiseSSLError("Unknown Error")

  proc sendPendingSslData(socket: AsyncSocket,
      flags: set[TSocketFlags]) {.async.} =
    let len = bioCtrlPending(socket.bioOut)
    if len > 0:
      var data = newStringOfCap(len)
      let read = bioRead(socket.bioOut, addr data[0], len)
      assert read != 0
      if read < 0:
        raiseSslError()
      data.setLen(read)
      await socket.fd.TAsyncFd.send(data, flags)

  proc appeaseSsl(socket: AsyncSocket, flags: set[TSocketFlags],
                  sslError: cint) {.async.} =
    case sslError
    of SSL_ERROR_WANT_WRITE:
      await sendPendingSslData(socket, flags)
    of SSL_ERROR_WANT_READ:
      var data = await recv(socket.fd.TAsyncFD, BufferSize, flags)
      let ret = bioWrite(socket.bioIn, addr data[0], data.len.cint)
      if ret < 0:
        raiseSSLError()
    else:
      raiseSSLError("Cannot appease SSL.")

  template sslLoop(socket: AsyncSocket, flags: set[TSocketFlags],
                   op: expr) =
    var opResult {.inject.} = -1.cint
    while opResult < 0:
      opResult = op
      # Bit hackish here.
      # TODO: Introduce an async template transformation pragma?
      yield sendPendingSslData(socket, flags)
      if opResult < 0:
        let err = getSslError(socket.sslHandle, opResult.cint)
        yield appeaseSsl(socket, flags, err.cint)

proc connect*(socket: PAsyncSocket, address: string, port: TPort,
    af = AF_INET) {.async.} =
  ## Connects ``socket`` to server at ``address:port``.
  ##
  ## Returns a ``Future`` which will complete when the connection succeeds
  ## or an error occurs.
  await connect(socket.fd.TAsyncFD, address, port, af)
  let flags = {TSocketFlags.SafeDisconn}
  if socket.isSsl:
    when defined(ssl):
      sslSetConnectState(socket.sslHandle)
      sslLoop(socket, flags, sslDoHandshake(socket.sslHandle))

proc readIntoBuf(socket: PAsyncSocket,
    flags: set[TSocketFlags]): Future[int] {.async.} =
  var data = await recv(socket.fd.TAsyncFD, BufferSize, flags)
  if data.len != 0:
    copyMem(addr socket.buffer[0], addr data[0], data.len)
  if socket.isSsl:
    when defined(ssl):
      # SSL mode.
      let ret = bioWrite(socket.bioIn, addr socket.buffer[0], data.len.cint)
      if ret < 0:
        raiseSSLError()
      sslLoop(socket, flags,
        sslRead(socket.sslHandle, addr socket.buffer[0], BufferSize.cint))
      socket.currPos = 0
      socket.bufLen = opResult # Injected from sslLoop template.
      result = opResult
  else:
    # Not in SSL mode.
    socket.bufLen = data.len
    socket.currPos = 0
    result = data.len

proc recv*(socket: PAsyncSocket, size: int,
           flags = {TSocketFlags.SafeDisconn}): Future[string] {.async.} =
  ## Reads ``size`` bytes from ``socket``. Returned future will complete once
  ## all of the requested data is read. If socket is disconnected during the
  ## recv operation then the future may complete with only a part of the
  ## requested data read. If socket is disconnected and no data is available
  ## to be read then the future will complete with a value of ``""``.
  if socket.isBuffered:
    result = newString(size)
    let originalBufPos = socket.currPos

    if socket.bufLen == 0:
      let res = await socket.readIntoBuf(flags - {TSocketFlags.Peek})
      if res == 0:
        result.setLen(0)
        return

    var read = 0
    while read < size:
      if socket.currPos >= socket.bufLen:
        if TSocketFlags.Peek in flags:
          # We don't want to get another buffer if we're peeking.
          break
        let res = await socket.readIntoBuf(flags - {TSocketFlags.Peek})
        if res == 0:
          break

      let chunk = min(socket.bufLen-socket.currPos, size-read)
      copyMem(addr(result[read]), addr(socket.buffer[socket.currPos]), chunk)
      read.inc(chunk)
      socket.currPos.inc(chunk)

    if TSocketFlags.Peek in flags:
      # Restore old buffer cursor position.
      socket.currPos = originalBufPos
    result.setLen(read)
  else:
    result = await recv(socket.fd.TAsyncFD, size, flags)

proc send*(socket: PAsyncSocket, data: string,
           flags = {TSocketFlags.SafeDisconn}) {.async.} =
  ## Sends ``data`` to ``socket``. The returned future will complete once all
  ## data has been sent.
  assert socket != nil
  if socket.isSsl:
    when defined(ssl):
      var copy = data
      sslLoop(socket, flags,
        sslWrite(socket.sslHandle, addr copy[0], copy.len.cint))
      await sendPendingSslData(socket, flags)
  else:
    await send(socket.fd.TAsyncFD, data, flags)

proc acceptAddr*(socket: PAsyncSocket, flags = {TSocketFlags.SafeDisconn}):
      Future[tuple[address: string, client: PAsyncSocket]] =
  ## Accepts a new connection. Returns a future containing the client socket
  ## corresponding to that connection and the remote address of the client.
  ## The future will complete when the connection is successfully accepted.
  var retFuture = newFuture[tuple[address: string, client: PAsyncSocket]]("asyncnet.acceptAddr")
  var fut = acceptAddr(socket.fd.TAsyncFD, flags)
  fut.callback =
    proc (future: Future[tuple[address: string, client: TAsyncFD]]) =
      assert future.finished
      if future.failed:
        retFuture.fail(future.readError)
      else:
        let resultTup = (future.read.address,
                         newSocket(future.read.client, socket.isBuffered))
        retFuture.complete(resultTup)
  return retFuture

proc accept*(socket: PAsyncSocket,
    flags = {TSocketFlags.SafeDisconn}): Future[PAsyncSocket] =
  ## Accepts a new connection. Returns a future containing the client socket
  ## corresponding to that connection.
  ## The future will complete when the connection is successfully accepted.
  var retFut = newFuture[PAsyncSocket]("asyncnet.accept")
  var fut = acceptAddr(socket, flags)
  fut.callback =
    proc (future: Future[tuple[address: string, client: PAsyncSocket]]) =
      assert future.finished
      if future.failed:
        retFut.fail(future.readError)
      else:
        retFut.complete(future.read.client)
  return retFut

proc recvLine*(socket: PAsyncSocket,
    flags = {TSocketFlags.SafeDisconn}): Future[string] {.async.} =
  ## Reads a line of data from ``socket``. Returned future will complete once
  ## a full line is read or an error occurs.
  ##
  ## If a full line is read ``\r\L`` is not
  ## added to ``line``, however if solely ``\r\L`` is read then ``line``
  ## will be set to it.
  ## 
  ## If the socket is disconnected, ``line`` will be set to ``""``.
  ##
  ## If the socket is disconnected in the middle of a line (before ``\r\L``
  ## is read) then line will be set to ``""``.
  ## The partial line **will be lost**.
  ##
  ## **Warning**: The ``Peek`` flag is not yet implemented.
  template addNLIfEmpty(): stmt =
    if result.len == 0:
      result.add("\c\L")
  assert TSocketFlags.Peek notin flags ## TODO:
  if socket.isBuffered:
    result = ""
    if socket.bufLen == 0:
      let res = await socket.readIntoBuf(flags)
      if res == 0:
        return

    var lastR = false
    while true:
      if socket.currPos >= socket.bufLen:
        let res = await socket.readIntoBuf(flags)
        if res == 0:
          result = ""
          break

      case socket.buffer[socket.currPos]
      of '\r':
        lastR = true
        addNLIfEmpty()
      of '\L':
        addNLIfEmpty()
        socket.currPos.inc()
        return
      else:
        if lastR:
          socket.currPos.inc()
          return
        else:
          result.add socket.buffer[socket.currPos]
      socket.currPos.inc()
  else:
    result = ""
    var c = ""
    while true:
      c = await recv(socket, 1, flags)
      if c.len == 0:
        return ""
      if c == "\r":
        c = await recv(socket, 1, flags + {TSocketFlags.Peek})
        if c.len > 0 and c == "\L":
          let dummy = await recv(socket, 1, flags)
          assert dummy == "\L"
        addNLIfEmpty()
        return
      elif c == "\L":
        addNLIfEmpty()
        return
      add(result.string, c)

proc listen*(socket: Socket, backlog = SOMAXCONN) {.tags: [ReadIOEffect].} =
  ## Marks ``socket`` as accepting connections.
  ## ``Backlog`` specifies the maximum length of the
  ## queue of pending connections.
  ##
  ## Raises an EOS error upon failure.
  if listen(socket.fd, backlog) < 0'i32: raiseOSError(osLastError())

proc bindAddr*(socket: Socket, port = Port(0), address = "") {.
  tags: [ReadIOEffect].} =
  ## Binds ``address``:``port`` to the socket.
  ##
  ## If ``address`` is "" then ADDR_ANY will be bound.

  if address == "":
    var name: Sockaddr_in
    when defined(Windows) or defined(nimdoc):
      name.sin_family = toInt(AF_INET).int16
    else:
      name.sin_family = toInt(AF_INET)
    name.sin_port = htons(int16(port))
    name.sin_addr.s_addr = htonl(INADDR_ANY)
    if bindAddr(socket.fd, cast[ptr SockAddr](addr(name)),
                  sizeof(name).Socklen) < 0'i32:
      raiseOSError(osLastError())
  else:
    var aiList = getAddrInfo(address, port, AF_INET)
    if bindAddr(socket.fd, aiList.ai_addr, aiList.ai_addrlen.Socklen) < 0'i32:
      dealloc(aiList)
      raiseOSError(osLastError())
    dealloc(aiList)

proc close*(socket: PAsyncSocket) =
  ## Closes the socket.
  socket.fd.TAsyncFD.closeSocket()
  when defined(ssl):
    if socket.isSSL:
      let res = SslShutdown(socket.sslHandle)
      if res == 0:
        if SslShutdown(socket.sslHandle) != 1:
          raiseSslError()
      elif res != 1:
        raiseSslError()

when defined(ssl):
  proc wrapSocket*(ctx: SslContext, socket: AsyncSocket) =
    ## Wraps a socket in an SSL context. This function effectively turns
    ## ``socket`` into an SSL socket.
    ##
    ## **Disclaimer**: This code is not well tested, may be very unsafe and
    ## prone to security vulnerabilities.
    socket.isSsl = true
    socket.sslContext = ctx
    socket.sslHandle = SSLNew(PSSLCTX(socket.sslContext))
    if socket.sslHandle == nil:
      raiseSslError()

    socket.bioIn = bioNew(bio_s_mem())
    socket.bioOut = bioNew(bio_s_mem())
    sslSetBio(socket.sslHandle, socket.bioIn, socket.bioOut)


when isMainModule:
  type
    TestCases = enum
      HighClient, LowClient, LowServer

  const test = HighClient

  when test == HighClient:
    proc main() {.async.} =
      var sock = newAsyncSocket()
      await sock.connect("irc.freenode.net", TPort(6667))
      while true:
        let line = await sock.recvLine()
        if line == "":
          echo("Disconnected")
          break
        else:
          echo("Got line: ", line)
    asyncCheck main()
  elif test == LowClient:
    var sock = newAsyncSocket()
    var f = connect(sock, "irc.freenode.net", TPort(6667))
    f.callback =
      proc (future: Future[void]) =
        echo("Connected in future!")
        for i in 0 .. 50:
          var recvF = recv(sock, 10)
          recvF.callback =
            proc (future: Future[string]) =
              echo("Read ", future.read.len, ": ", future.read.repr)
  elif test == LowServer:
    var sock = newAsyncSocket()
    sock.bindAddr(TPort(6667))
    sock.listen()
    proc onAccept(future: Future[PAsyncSocket]) =
      let client = future.read
      echo "Accepted ", client.fd.cint
      var t = send(client, "test\c\L")
      t.callback =
        proc (future: Future[void]) =
          echo("Send")
          client.close()
      
      var f = accept(sock)
      f.callback = onAccept
      
    var f = accept(sock)
    f.callback = onAccept
  runForever()
    
