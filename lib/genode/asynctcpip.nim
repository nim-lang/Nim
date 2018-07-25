#
#
#            Nim's Runtime Library
#        (c) Copyright 2018 Emery Hemingway
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Genode asynchronous TCP+UDP/IP stack

import asyncdispatch, asyncfutures, asyncfile
  # IP stacks are exposed from the file-system

include asyncmacro

type
  Port* = range[0..0xffff]
  Protocol* = enum IPPROTO_TCP, IPPROTO_UDP
  SocketFlag* = enum SafeDisconn

  AsyncSocketObj* = object of RootObj
    ## An object containing handles on socket control files
    allocFile, acceptCtx, bindCtx, connF, dataF,
      listenCtx, localCtx, peekF, remoteCtx: AsyncFile
    dir: string
    proto: Protocol

  AsyncSocket* = ref AsyncSocketObj

  SslContext* = void

  Domain* = enum AF_UNSPEC, AF_INET, AF_INET6
  SockType* = enum SOCK_STREAM, SOCK_DGRAM
    ## Provided for backwards compatiblity with the 1980s

const
  BufferSize* = 4096 ## recommend size of a socket buffer
  MaxLineLength* = 4096
  osInvalidSocket* = nil
  SocketDirBad = "/socket"
  maxPathLen = 64

iterator controlFiles(sock: AsyncSocket): AsyncFile =
  if not sock.allocFile.isNil: yield sock.allocFile
  if not sock.acceptCtx.isNil: yield sock.acceptCtx
  if not sock.bindCtx.isNil: yield sock.bindCtx
  if not sock.connF.isNil: yield sock.connF
  if not sock.dataF.isNil: yield sock.dataF
  if not sock.listenCtx.isNil: yield sock.listenCtx
  if not sock.localCtx.isNil: yield sock.localCtx
  if not sock.peekF.isNil: yield sock.peekF
  if not sock.remoteCtx.isNil: yield sock.remoteCtx

proc newAsyncSocket*(domain: Domain = AF_INET, sockType: SockType = SOCK_STREAM,
    protocol: Protocol = IPPROTO_TCP, buffered = true): AsyncSocket =
  AsyncSocket(proto: protocol, dir: "")

proc close*(sock: AsyncSocket) =
  # When all files referencing a socket are closed
  # the socket is freed at the backend
  for f in sock.controlFiles:
    asyncfile.close f
  sock.dir = ""

proc alloc(sock: AsyncSocket): Future[void] =
  assert sock.dir == ""
  let
    newSocketPath = case sock.proto
      of IPPROTO_TCP: SocketDirBad & "/tcp/new_socket"
      of IPPROTO_UDP: SocketDirBad & "/udp/new_socket"
  sock.allocFile = openAsync(newSocketPath)
  let
    retFut = newFuture[void]("dial")
    readFut = sock.allocFile.read(maxPathLen)
  readFut.addCallback do ():
    if readFut.failed:
      close sock
      retFut.fail(readFut.readError)
    else:
      sock.dir = strip(SocketDirBad & "/" & readFut.read())
      retFut.complete()
  result = retFut

proc connect*(sock: AsyncSocket, address: string, port: Port): Future[void] =
  assert(sock.dir != "")
  if sock.connF.isNil:
    let filename = sock.dir & "/connect"
    sock.connF = openAsync(filename, fmAppend)
  result = sock.connF.write(address & ":" & $port)

proc dial*(address: string, port: Port, protocol = IPPROTO_TCP,
           buffered = true): Future[AsyncSocket] =
  let
    sock = newAsyncSocket(protocol=protocol)
    allocFut = sock.alloc()
    dialFut = newFuture[AsyncSocket]("asynctcpip.dial")
  allocFut.addCallback(
    proc () {.gcsafe.} =
      let connFut = sock.connect(address, port)
      connFut.addCallback(
        proc () {.gcsafe.} =
          dialFut.complete(sock)
        )
    )
  result = dialFut

template checkDataF(sock: AsyncSocket) =
  assert(sock.dir != "")
  if sock.dataF.isNil:
    sock.dataF = openAsync(sock.dir & "/data", fmReadWriteExisting)

proc send*(sock: AsyncSocket, buf: pointer, size: int,
            flags = {SocketFlag.SafeDisconn}): Future[void] =
  checkDataF sock
  let
    retFut = newFuture[void]("asynctcpip.send")
    dataFut = sock.dataF.writeBuffer(buf, size)
  dataFut.addCallback do ():
    if dataFut.failed:
      retFut.fail(dataFut.readError)
    else:
      retFut.complete()
  result = retFut
  # TODO: pass the send Future to the VFS write proc directly?

proc send*(sock: AsyncSocket, data: string,
           flags = {SocketFlag.SafeDisconn}): Future[void] =
  var copy = data
  send(sock, addr copy[0], len copy, flags)

template checkPeekF(sock: AsyncSocket) =
  assert(sock.dir != "")
  if sock.peekF.isNil:
    sock.peekF = openAsync(sock.dir & "/peek", fmRead)

proc peekInto*(sock: AsyncSocket; buf: pointer; size: int): Future[int] =
  ## Peek at buffered socket data.
  checkPeekF sock
  let
    retFut = newFuture[int]("asynctcpip.peek")
    dataFut = sock.peekF.readBuffer(buf, size)
  dataFut.addCallback do ():
    if dataFut.failed:
      retFut.fail(readError dataFut)
    else:
      retFut.complete(read dataFut)
  result = retFut
  # TODO: pass the recv Future to the VFS read proc directly?

proc recvInto*(sock: AsyncSocket, buf: pointer, size: int,
           flags = {SocketFlag.SafeDisconn}): Future[int] =
  checkDataF sock
  let
    retFut = newFuture[int]("asynctcpip.recvInto")
    dataFut = sock.dataF.readBuffer(buf, size)
  dataFut.addCallback do ():
    if dataFut.failed:
      retFut.fail(dataFut.readError)
    else:
      retFut.complete(dataFut.read())
  result = retFut
  # TODO: pass the recv Future to the VFS read proc directly?

proc recv*(sock: AsyncSocket, size: int,
           flags = {SocketFlag.SafeDisconn}): Future[string] =
  let retFut = newFuture[string]("asynctcpip.recv")
  var buf = newString(size)
  let dataFut = sock.recvInto(buf[0].addr, buf.len)
  dataFut.addCallback do ():
    if dataFut.failed:
      retFut.fail(dataFut.readError)
    else:
      buf.setLen(read dataFut)
      retFut.complete(buf)
  result = retFut

proc recvLineInto*(sock: AsyncSocket, resString: FutureVar[string],
    flags = {SocketFlag.SafeDisconn}, maxLength = MaxLineLength) {.async.} =
  assert(not resString.mget.isNil(),
         "String inside resString future needs to be initialised")
  const eol = "\r\L"
  resString.mget.setLen maxLength
  var off = 0
  while (not resString.finished):
    if off >=  resString.mget.len:
      complete resString
      break
    var peekLen = await sock.peekInto(
      resString.mget[off].addr, resString.mget.len - off)
      # peek using the result buffer
    let endL = find(resString.mget, eol, off, off+peekLen)
    if endL > -1:
      peekLen = endL - off
      complete resString
    if peekLen > 0:
      let nr = await sock.recvInto(resString.mget[off].addr, peekLen)
        # read back into the buffer so the line is consumed
    off.inc peekLen
  if off < 1:
    resString.mget() = eol
  else:
    resString.mget.setLen(off)
  
proc recvLine*(sock: AsyncSocket,
    flags = {SocketFlag.SafeDisconn},
    maxLength = MaxLineLength): Future[string] {.async.} =
  var resString = newFutureVar[string]("asynctcpip.recvLine")
  resString.mget() = ""
  await sock.recvLineInto(resString, flags, maxLength)
  result = resString.mget()
