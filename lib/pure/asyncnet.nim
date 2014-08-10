#
#
#            Nimrod's Runtime Library
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
## .. code-block::nimrod
##
##   import asyncnet, asyncdispatch
##
##   var clients: seq[PAsyncSocket] = @[]
##
##   proc processClient(client: PAsyncSocket) {.async.} =
##     while true:
##       let line = await client.recvLine()
##       for c in clients:
##         await c.send(line & "\c\L")
##
##   proc serve() {.async.} =
##     var server = newAsyncSocket()
##     server.bindAddr(TPort(12345))
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

when defined(ssl):
  import openssl

type
  # TODO: I would prefer to just do:
  # PAsyncSocket* {.borrow: `.`.} = distinct PSocket. But that doesn't work.
  TAsyncSocket {.borrow: `.`.} = distinct TSocketImpl
  PAsyncSocket* = ref TAsyncSocket

# TODO: Save AF, domain etc info and reuse it in procs which need it like connect.

proc newSocket(fd: TAsyncFD, isBuff: bool): PAsyncSocket =
  assert fd != osInvalidSocket.TAsyncFD
  new(result.PSocket)
  result.fd = fd.TSocketHandle
  result.isBuffered = isBuff
  if isBuff:
    result.currPos = 0

proc newAsyncSocket*(domain: TDomain = AF_INET, typ: TType = SOCK_STREAM,
    protocol: TProtocol = IPPROTO_TCP, buffered = true): PAsyncSocket =
  ## Creates a new asynchronous socket.
  result = newSocket(newAsyncRawSocket(domain, typ, protocol), buffered)

proc connect*(socket: PAsyncSocket, address: string, port: TPort,
    af = AF_INET): PFuture[void] =
  ## Connects ``socket`` to server at ``address:port``.
  ##
  ## Returns a ``PFuture`` which will complete when the connection succeeds
  ## or an error occurs.
  result = connect(socket.fd.TAsyncFD, address, port, af)

proc readIntoBuf(socket: PAsyncSocket,
    flags: set[TSocketFlags]): PFuture[int] {.async.} =
  var data = await recv(socket.fd.TAsyncFD, BufferSize, flags)
  if data.len != 0:
    copyMem(addr socket.buffer[0], addr data[0], data.len)
  socket.bufLen = data.len
  socket.currPos = 0
  result = data.len

proc recv*(socket: PAsyncSocket, size: int,
           flags = {TSocketFlags.SafeDisconn}): PFuture[string] {.async.} =
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
           flags = {TSocketFlags.SafeDisconn}): PFuture[void] =
  ## Sends ``data`` to ``socket``. The returned future will complete once all
  ## data has been sent.
  assert socket != nil
  result = send(socket.fd.TAsyncFD, data, flags)

proc acceptAddr*(socket: PAsyncSocket, flags = {TSocketFlags.SafeDisconn}):
      PFuture[tuple[address: string, client: PAsyncSocket]] =
  ## Accepts a new connection. Returns a future containing the client socket
  ## corresponding to that connection and the remote address of the client.
  ## The future will complete when the connection is successfully accepted.
  var retFuture = newFuture[tuple[address: string, client: PAsyncSocket]]("asyncnet.acceptAddr")
  var fut = acceptAddr(socket.fd.TAsyncFD, flags)
  fut.callback =
    proc (future: PFuture[tuple[address: string, client: TAsyncFD]]) =
      assert future.finished
      if future.failed:
        retFuture.fail(future.readError)
      else:
        let resultTup = (future.read.address,
                         newSocket(future.read.client, socket.isBuffered))
        retFuture.complete(resultTup)
  return retFuture

proc accept*(socket: PAsyncSocket,
    flags = {TSocketFlags.SafeDisconn}): PFuture[PAsyncSocket] =
  ## Accepts a new connection. Returns a future containing the client socket
  ## corresponding to that connection.
  ## The future will complete when the connection is successfully accepted.
  var retFut = newFuture[PAsyncSocket]("asyncnet.accept")
  var fut = acceptAddr(socket, flags)
  fut.callback =
    proc (future: PFuture[tuple[address: string, client: PAsyncSocket]]) =
      assert future.finished
      if future.failed:
        retFut.fail(future.readError)
      else:
        retFut.complete(future.read.client)
  return retFut

proc recvLine*(socket: PAsyncSocket,
    flags = {TSocketFlags.SafeDisconn}): PFuture[string] {.async.} =
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

proc bindAddr*(socket: PAsyncSocket, port = TPort(0), address = "") =
  ## Binds ``address``:``port`` to the socket.
  ##
  ## If ``address`` is "" then ADDR_ANY will be bound.
  socket.PSocket.bindAddr(port, address)

proc listen*(socket: PAsyncSocket, backlog = SOMAXCONN) =
  ## Marks ``socket`` as accepting connections.
  ## ``Backlog`` specifies the maximum length of the
  ## queue of pending connections.
  ##
  ## Raises an EOS error upon failure.
  socket.PSocket.listen(backlog)

proc close*(socket: PAsyncSocket) =
  ## Closes the socket.
  socket.fd.TAsyncFD.closeSocket()
  # TODO SSL

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
      proc (future: PFuture[void]) =
        echo("Connected in future!")
        for i in 0 .. 50:
          var recvF = recv(sock, 10)
          recvF.callback =
            proc (future: PFuture[string]) =
              echo("Read ", future.read.len, ": ", future.read.repr)
  elif test == LowServer:
    var sock = newAsyncSocket()
    sock.bindAddr(TPort(6667))
    sock.listen()
    proc onAccept(future: PFuture[PAsyncSocket]) =
      let client = future.read
      echo "Accepted ", client.fd.cint
      var t = send(client, "test\c\L")
      t.callback =
        proc (future: PFuture[void]) =
          echo("Send")
          client.close()
      
      var f = accept(sock)
      f.callback = onAccept
      
    var f = accept(sock)
    f.callback = onAccept
  runForever()
    
