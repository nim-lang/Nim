#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2014 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
import asyncdispatch
import rawsockets
import net

when defined(ssl):
  import openssl

type
  TAsyncSocket = object ## socket type
    fd: TAsyncFD
    case isBuffered: bool # determines whether this socket is buffered.
    of true:
      buffer: array[0..BufferSize, char]
      currPos: int # current index in buffer
      bufLen: int # current length of buffer
    of false: nil
    when defined(ssl):
      case isSsl: bool
      of true:
        sslHandle: PSSL
        sslContext: PSSLContext
        sslNoHandshake: bool # True if needs handshake.
        sslHasPeekChar: bool
        sslPeekChar: char
      of false: nil

  PAsyncSocket* = ref TAsyncSocket

# TODO: Save AF, domain etc info and reuse it in procs which need it like connect.

proc newSocket(fd: TAsyncFD, isBuff: bool): PAsyncSocket =
  assert fd != osInvalidSocket.TAsyncFD
  new(result)
  result.fd = fd
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
  result = connect(socket.fd, address, port, af)

proc recv*(socket: PAsyncSocket, size: int,
           flags: int = 0): PFuture[string] =
  ## Reads ``size`` bytes from ``socket``. Returned future will complete once
  ## all of the requested data is read. If socket is disconnected during the
  ## recv operation then the future may complete with only a part of the
  ## requested data read. If socket is disconnected and no data is available
  ## to be read then the future will complete with a value of ``""``.
  result = recv(socket.fd, size, flags)

proc send*(socket: PAsyncSocket, data: string): PFuture[void] =
  ## Sends ``data`` to ``socket``. The returned future will complete once all
  ## data has been sent.
  result = send(socket.fd, data)

proc acceptAddr*(socket: PAsyncSocket): 
      PFuture[tuple[address: string, client: PAsyncSocket]] =
  ## Accepts a new connection. Returns a future containing the client socket
  ## corresponding to that connection and the remote address of the client.
  ## The future will complete when the connection is successfully accepted.
  var retFuture = newFuture[tuple[address: string, client: PAsyncSocket]]()
  var fut = acceptAddr(socket.fd)
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

proc accept*(socket: PAsyncSocket): PFuture[PAsyncSocket] =
  ## Accepts a new connection. Returns a future containing the client socket
  ## corresponding to that connection.
  ## The future will complete when the connection is successfully accepted.
  var retFut = newFuture[PAsyncSocket]()
  var fut = acceptAddr(socket)
  fut.callback =
    proc (future: PFuture[tuple[address: string, client: PAsyncSocket]]) =
      assert future.finished
      if future.failed:
        retFut.fail(future.readError)
      else:
        retFut.complete(future.read.client)
  return retFut

proc recvLine*(socket: PAsyncSocket): PFuture[string] {.async.} =
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
  
  template addNLIfEmpty(): stmt =
    if result.len == 0:
      result.add("\c\L")

  result = ""
  var c = ""
  while true:
    c = await recv(socket, 1)
    if c.len == 0:
      return ""
    if c == "\r":
      c = await recv(socket, 1, MSG_PEEK)
      if c.len > 0 and c == "\L":
        discard await recv(socket, 1)
      addNLIfEmpty()
      return
    elif c == "\L":
      addNLIfEmpty()
      return
    add(result.string, c)

when isMainModule:
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
  main()
  runForever()
    
