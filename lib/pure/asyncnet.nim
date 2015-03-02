#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a high-level asynchronous sockets API based on the
## asynchronous dispatcher defined in the ``asyncdispatch`` module.
##
## SSL
## ---
##
## SSL can be enabled by compiling with the ``-d:ssl`` flag.
##
## You must create a new SSL context with the ``newContext`` function defined
## in the ``net`` module. You may then call ``wrapSocket`` on your socket using
## the newly created SSL context to get an SSL socket.
##
## Examples
## --------
##
## Chat server
## ^^^^^^^^^^^
## 
## The following example demonstrates a simple chat server.
##
## .. code-block::nim
##
##   import asyncnet, asyncdispatch
##
##   var clients {.threadvar.}: seq[AsyncSocket]
##
##   proc processClient(client: AsyncSocket) {.async.} =
##     while true:
##       let line = await client.recvLine()
##       for c in clients:
##         await c.send(line & "\c\L")
##
##   proc serve() {.async.} =
##     clients = @[]
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

import asyncdispatch
import rawsockets
import net
import os

export SOBool

when defined(ssl):
  import openssl

type
  # TODO: I would prefer to just do:
  # AsyncSocket* {.borrow: `.`.} = distinct Socket. But that doesn't work.
  AsyncSocketDesc  = object
    fd*: SocketHandle
    closed: bool ## determines whether this socket has been closed
    case isBuffered: bool ## determines whether this socket is buffered.
    of true:
      buffer: array[0..BufferSize, char]
      currPos: int # current index in buffer
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

proc newAsyncSocket*(fd: TAsyncFD, isBuff: bool): AsyncSocket =
  ## Creates a new ``AsyncSocket`` based on the supplied params.
  assert fd != osInvalidSocket.TAsyncFD
  new(result)
  result.fd = fd.SocketHandle
  result.isBuffered = isBuff
  if isBuff:
    result.currPos = 0

proc newAsyncSocket*(domain: Domain = AF_INET, typ: SockType = SOCK_STREAM,
    protocol: Protocol = IPPROTO_TCP, buffered = true): AsyncSocket =
  ## Creates a new asynchronous socket.
  ##
  ## This procedure will also create a brand new file descriptor for
  ## this socket.
  result = newAsyncSocket(newAsyncRawSocket(domain, typ, protocol), buffered)

proc newAsyncSocket*(domain, typ, protocol: cint, buffered = true): AsyncSocket =
  ## Creates a new asynchronous socket.
  ##
  ## This procedure will also create a brand new file descriptor for
  ## this socket.
  result = newAsyncSocket(newAsyncRawSocket(domain, typ, protocol), buffered)

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
      flags: set[SocketFlag]) {.async.} =
    let len = bioCtrlPending(socket.bioOut)
    if len > 0:
      var data = newStringOfCap(len)
      let read = bioRead(socket.bioOut, addr data[0], len)
      assert read != 0
      if read < 0:
        raiseSslError()
      data.setLen(read)
      await socket.fd.TAsyncFd.send(data, flags)

  proc appeaseSsl(socket: AsyncSocket, flags: set[SocketFlag],
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

  template sslLoop(socket: AsyncSocket, flags: set[SocketFlag],
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

proc connect*(socket: AsyncSocket, address: string, port: Port,
    af = AF_INET) {.async.} =
  ## Connects ``socket`` to server at ``address:port``.
  ##
  ## Returns a ``Future`` which will complete when the connection succeeds
  ## or an error occurs.
  await connect(socket.fd.TAsyncFD, address, port, af)
  if socket.isSsl:
    when defined(ssl):
      let flags = {SocketFlag.SafeDisconn}
      sslSetConnectState(socket.sslHandle)
      sslLoop(socket, flags, sslDoHandshake(socket.sslHandle))

template readInto*(buf: cstring, size: int, socket: AsyncSocket,
                   flags: set[SocketFlag]): int =
  ## Reads **up to** ``size`` bytes from ``socket`` into ``buf``. Note that
  ## this is a template and not a proc.
  var res = 0
  if socket.isSsl:
    when defined(ssl):
      # SSL mode.
      sslLoop(socket, flags,
        sslRead(socket.sslHandle, buf, size.cint))
      res = opResult
  else:
    var recvIntoFut = recvInto(socket.fd.TAsyncFD, buf, size, flags)
    yield recvIntoFut
    # Not in SSL mode.
    res = recvIntoFut.read()
  res

template readIntoBuf*(socket: AsyncSocket,
    flags: set[SocketFlag]): int =
  var size = readInto(addr socket.buffer[0], BufferSize, socket, flags)
  socket.currPos = 0
  socket.bufLen = size
  size

proc recv*(socket: AsyncSocket, size: int,
           flags = {SocketFlag.SafeDisconn}): Future[string] {.async.} =
  ## Reads **up to** ``size`` bytes from ``socket``.
  ##
  ## For buffered sockets this function will attempt to read all the requested
  ## data. It will read this data in ``BufferSize`` chunks.
  ##
  ## For unbuffered sockets this function makes no effort to read
  ## all the data requested. It will return as much data as the operating system
  ## gives it.
  ##
  ## If socket is disconnected during the
  ## recv operation then the future may complete with only a part of the
  ## requested data.
  ##
  ## If socket is disconnected and no data is available
  ## to be read then the future will complete with a value of ``""``.
  if socket.isBuffered:
    result = newString(size)
    shallow(result)
    let originalBufPos = socket.currPos

    if socket.bufLen == 0:
      let res = socket.readIntoBuf(flags - {SocketFlag.Peek})
      if res == 0:
        result.setLen(0)
        return

    var read = 0
    while read < size:
      if socket.currPos >= socket.bufLen:
        if SocketFlag.Peek in flags:
          # We don't want to get another buffer if we're peeking.
          break
        let res = socket.readIntoBuf(flags - {SocketFlag.Peek})
        if res == 0:
          break

      let chunk = min(socket.bufLen-socket.currPos, size-read)
      copyMem(addr(result[read]), addr(socket.buffer[socket.currPos]), chunk)
      read.inc(chunk)
      socket.currPos.inc(chunk)

    if SocketFlag.Peek in flags:
      # Restore old buffer cursor position.
      socket.currPos = originalBufPos
    result.setLen(read)
  else:
    result = newString(size)
    let read = readInto(addr result[0], size, socket, flags)
    result.setLen(read)

proc send*(socket: AsyncSocket, data: string,
           flags = {SocketFlag.SafeDisconn}) {.async.} =
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

proc acceptAddr*(socket: AsyncSocket, flags = {SocketFlag.SafeDisconn}):
      Future[tuple[address: string, client: AsyncSocket]] =
  ## Accepts a new connection. Returns a future containing the client socket
  ## corresponding to that connection and the remote address of the client.
  ## The future will complete when the connection is successfully accepted.
  var retFuture = newFuture[tuple[address: string, client: AsyncSocket]]("asyncnet.acceptAddr")
  var fut = acceptAddr(socket.fd.TAsyncFD, flags)
  fut.callback =
    proc (future: Future[tuple[address: string, client: TAsyncFD]]) =
      assert future.finished
      if future.failed:
        retFuture.fail(future.readError)
      else:
        let resultTup = (future.read.address,
                         newAsyncSocket(future.read.client, socket.isBuffered))
        retFuture.complete(resultTup)
  return retFuture

proc accept*(socket: AsyncSocket,
    flags = {SocketFlag.SafeDisconn}): Future[AsyncSocket] =
  ## Accepts a new connection. Returns a future containing the client socket
  ## corresponding to that connection.
  ## The future will complete when the connection is successfully accepted.
  var retFut = newFuture[AsyncSocket]("asyncnet.accept")
  var fut = acceptAddr(socket, flags)
  fut.callback =
    proc (future: Future[tuple[address: string, client: AsyncSocket]]) =
      assert future.finished
      if future.failed:
        retFut.fail(future.readError)
      else:
        retFut.complete(future.read.client)
  return retFut

template recvLineInto*(socket: AsyncSocket, resString: var string,
    flags = {SocketFlag.SafeDisconn}) =
  ## Reads a line of data from ``socket`` into ``resString``.
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
  ## 
  ## **Warning**: ``recvLineInto`` on unbuffered sockets assumes that the
  ## protocol uses ``\r\L`` to delimit a new line.
  assert SocketFlag.Peek notin flags ## TODO:

  template addNLIfEmpty(): stmt =
    if resString.len == 0:
      resString.add("\c\L")

  block recvLineInto:
    if socket.isBuffered:
      if socket.bufLen == 0:
        let res = socket.readIntoBuf(flags)
        if res == 0:
          break recvLineInto

      var lastR = false
      while true:
        if socket.currPos >= socket.bufLen:
          let res = socket.readIntoBuf(flags)
          if res == 0:
            resString.setLen(0)
            break recvLineInto

        case socket.buffer[socket.currPos]
        of '\r':
          lastR = true
          addNLIfEmpty()
        of '\L':
          addNLIfEmpty()
          socket.currPos.inc()
          break recvLineInto
        else:
          if lastR:
            socket.currPos.inc()
            break recvLineInto
          else:
            resString.add socket.buffer[socket.currPos]
        socket.currPos.inc()
    else:
      var c = ""
      while true:
        let recvFut = recv(socket, 1, flags)
        yield recvFut
        c = recvFut.read()
        if c.len == 0:
          resString.setLen(0)
          break recvLineInto
        if c == "\r":
          let recvFut = recv(socket, 1, flags) # Skip \L
          yield recvFut
          c = recvFut.read()
          assert c == "\L"
          addNLIfEmpty()
          break recvLineInto
        elif c == "\L":
          addNLIfEmpty()
          break recvLineInto
        add(resString, c)

proc recvLine*(socket: AsyncSocket,
    flags = {SocketFlag.SafeDisconn}): Future[string] {.async.} =
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
  ## 
  ## **Warning**: ``recvLine`` on unbuffered sockets assumes that the protocol
  ## uses ``\r\L`` to delimit a new line.
  template addNLIfEmpty(): stmt =
    if result.len == 0:
      result.add("\c\L")
  assert SocketFlag.Peek notin flags ## TODO:

  result = ""
  socket.recvLineInto(result, flags)

proc listen*(socket: AsyncSocket, backlog = SOMAXCONN) {.tags: [ReadIOEffect].} =
  ## Marks ``socket`` as accepting connections.
  ## ``Backlog`` specifies the maximum length of the
  ## queue of pending connections.
  ##
  ## Raises an EOS error upon failure.
  if listen(socket.fd, backlog) < 0'i32: raiseOSError(osLastError())

proc bindAddr*(socket: AsyncSocket, port = Port(0), address = "") {.
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

proc close*(socket: AsyncSocket) =
  ## Closes the socket.
  defer:
    socket.fd.TAsyncFD.closeSocket()
  when defined(ssl):
    if socket.isSSL:
      let res = SslShutdown(socket.sslHandle)
      if res == 0:
        discard
      elif res != 1:
        raiseSslError()
  socket.closed = true # TODO: Add extra debugging checks for this.

when defined(ssl):
  proc wrapSocket*(ctx: SslContext, socket: AsyncSocket) =
    ## Wraps a socket in an SSL context. This function effectively turns
    ## ``socket`` into an SSL socket.
    ##
    ## **Disclaimer**: This code is not well tested, may be very unsafe and
    ## prone to security vulnerabilities.
    socket.isSsl = true
    socket.sslContext = ctx
    socket.sslHandle = SSLNew(SSLCTX(socket.sslContext))
    if socket.sslHandle == nil:
      raiseSslError()

    socket.bioIn = bioNew(bio_s_mem())
    socket.bioOut = bioNew(bio_s_mem())
    sslSetBio(socket.sslHandle, socket.bioIn, socket.bioOut)

proc getSockOpt*(socket: AsyncSocket, opt: SOBool, level = SOL_SOCKET): bool {.
  tags: [ReadIOEffect].} =
  ## Retrieves option ``opt`` as a boolean value.
  var res = getSockOptInt(socket.fd, cint(level), toCInt(opt))
  result = res != 0

proc setSockOpt*(socket: AsyncSocket, opt: SOBool, value: bool,
    level = SOL_SOCKET) {.tags: [WriteIOEffect].} =
  ## Sets option ``opt`` to a boolean value specified by ``value``.
  var valuei = cint(if value: 1 else: 0)
  setSockOptInt(socket.fd, cint(level), toCInt(opt), valuei)

proc isSsl*(socket: AsyncSocket): bool =
  ## Determines whether ``socket`` is a SSL socket.
  socket.isSsl

proc getFd*(socket: AsyncSocket): SocketHandle =
  ## Returns the socket's file descriptor.
  return socket.fd

proc isClosed*(socket: AsyncSocket): bool =
  ## Determines whether the socket has been closed.
  return socket.closed

when isMainModule:
  type
    TestCases = enum
      HighClient, LowClient, LowServer

  const test = HighClient

  when test == HighClient:
    proc main() {.async.} =
      var sock = newAsyncSocket()
      await sock.connect("irc.freenode.net", Port(6667))
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
    var f = connect(sock, "irc.freenode.net", Port(6667))
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
    sock.bindAddr(Port(6667))
    sock.listen()
    proc onAccept(future: Future[AsyncSocket]) =
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
    
