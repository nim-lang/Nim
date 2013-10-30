#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf, Dominik Picheta
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import sockets, os

## This module implements an asynchronous event loop together with asynchronous sockets
## which use this event loop.
## It is akin to Python's asyncore module. Many modules that use sockets
## have an implementation for this module, those modules should all have a
## ``register`` function which you should use to add the desired objects to a
## dispatcher which you created so
## that you can receive the events associated with that module's object.
##
## Once everything is registered in a dispatcher, you need to call the ``poll``
## function in a while loop.
##
## **Note:** Most modules have tasks which need to be ran regularly, this is
## why you should not call ``poll`` with a infinite timeout, or even a
## very long one. In most cases the default timeout is fine.
##
## **Note:** This module currently only supports select(), this is limited by
## FD_SETSIZE, which is usually 1024. So you may only be able to use 1024
## sockets at a time.
##
## Most (if not all) modules that use asyncio provide a userArg which is passed
## on with the events. The type that you set userArg to must be inheriting from
## TObject!
##
## **Note:** If you want to provide async ability to your module please do not
## use the ``TDelegate`` object, instead use ``PAsyncSocket``. It is possible
## that in the future this type's fields will not be exported therefore breaking
## your code.
##
## **Warning:** The API of this module is unstable, and therefore is subject
## to change.
##
## Asynchronous sockets
## ====================
##
## For most purposes you do not need to worry about the ``TDelegate`` type. The
## ``PAsyncSocket`` is what you are after. It's a reference to the ``TAsyncSocket``
## object. This object defines events which you should overwrite by your own
## procedures.
##
## For server sockets the only event you need to worry about is the ``handleAccept``
## event, in your handleAccept proc you should call ``accept`` on the server
## socket which will give you the client which is connecting. You should then
## set any events that you want to use on that client and add it to your dispatcher
## using the ``register`` procedure.
##
## An example ``handleAccept`` follows:
##
## .. code-block:: nimrod
##
##    var disp: PDispatcher = newDispatcher()
##    ...
##    proc handleAccept(s: PAsyncSocket) =
##      echo("Accepted client.")
##      var client: PAsyncSocket
##      new(client)
##      s.accept(client)
##      client.handleRead = ...
##      disp.register(client)
##    ...
##
## For client sockets you should only be interested in the ``handleRead`` and
## ``handleConnect`` events. The former gets called whenever the socket has
## received messages and can be read from and the latter gets called whenever
## the socket has established a connection to a server socket; from that point
## it can be safely written to.
##
## Getting a blocking client from a PAsyncSocket
## =============================================
##
## If you need a asynchronous server socket but you wish to process the clients
## synchronously then you can use the ``getSocket`` converter to get a TSocket
## object from the PAsyncSocket object, this can then be combined with ``accept``
## like so:
##
## .. code-block:: nimrod
##
##    proc handleAccept(s: PAsyncSocket) =
##      var client: TSocket
##      getSocket(s).accept(client)

when defined(windows):
  from winlean import TTimeVal, TSocketHandle, TFdSet, FD_ZERO, FD_SET, FD_ISSET, select
else:
  from posix import TTimeVal, TSocketHandle, TFdSet, FD_ZERO, FD_SET, FD_ISSET, select

type
  TDelegate* = object
    fd*: TSocketHandle
    deleVal*: PObject

    handleRead*: proc (h: PObject) {.nimcall.}
    handleWrite*: proc (h: PObject) {.nimcall.}
    handleError*: proc (h: PObject) {.nimcall.}
    hasDataBuffered*: proc (h: PObject): bool {.nimcall.}

    open*: bool
    task*: proc (h: PObject) {.nimcall.}
    mode*: TFileMode

  PDelegate* = ref TDelegate

  PDispatcher* = ref TDispatcher
  TDispatcher = object
    delegates: seq[PDelegate]

  PAsyncSocket* = ref TAsyncSocket
  TAsyncSocket* = object of TObject
    socket: TSocket
    info: TInfo

    handleRead*: proc (s: PAsyncSocket) {.closure.}
    handleWrite: proc (s: PAsyncSocket) {.closure.}
    handleConnect*: proc (s:  PAsyncSocket) {.closure.}

    handleAccept*: proc (s:  PAsyncSocket) {.closure.}

    handleTask*: proc (s: PAsyncSocket) {.closure.}

    lineBuffer: TaintedString ## Temporary storage for ``readLine``
    sendBuffer: string ## Temporary storage for ``send``
    sslNeedAccept: bool
    proto: TProtocol
    deleg: PDelegate

  TInfo* = enum
    SockIdle, SockConnecting, SockConnected, SockListening, SockClosed,
    SockUDPBound

proc newDelegate*(): PDelegate =
  ## Creates a new delegate.
  new(result)
  result.handleRead = (proc (h: PObject) = nil)
  result.handleWrite = (proc (h: PObject) = nil)
  result.handleError = (proc (h: PObject) = nil)
  result.hasDataBuffered = (proc (h: PObject): bool = return false)
  result.task = (proc (h: PObject) = nil)
  result.mode = fmRead

proc newAsyncSocket(): PAsyncSocket =
  new(result)
  result.info = SockIdle

  result.handleRead = (proc (s: PAsyncSocket) = nil)
  result.handleWrite = nil
  result.handleConnect = (proc (s: PAsyncSocket) = nil)
  result.handleAccept = (proc (s: PAsyncSocket) = nil)
  result.handleTask = (proc (s: PAsyncSocket) = nil)

  result.lineBuffer = "".TaintedString
  result.sendBuffer = ""

proc AsyncSocket*(domain: TDomain = AF_INET, typ: TType = SOCK_STREAM,
                  protocol: TProtocol = IPPROTO_TCP,
                  buffered = true): PAsyncSocket =
  ## Initialises an AsyncSocket object. If a socket cannot be initialised
  ## EOS is raised.
  result = newAsyncSocket()
  result.socket = socket(domain, typ, protocol, buffered)
  result.proto = protocol
  if result.socket == InvalidSocket: OSError(OSLastError())
  result.socket.setBlocking(false)

proc toAsyncSocket*(sock: TSocket, state: TInfo = SockConnected): PAsyncSocket =
  ## Wraps an already initialized ``TSocket`` into a PAsyncSocket.
  ## This is useful if you want to use an already connected TSocket as an
  ## asynchronous PAsyncSocket in asyncio's event loop.
  ##
  ## ``state`` may be overriden, i.e. if ``sock`` is not connected it should be
  ## adjusted properly. By default it will be assumed that the socket is
  ## connected. Please note this is only applicable to TCP client sockets, if
  ## ``sock`` is a different type of socket ``state`` needs to be adjusted!!!
  ##
  ## ================  ================================================================
  ## Value             Meaning
  ## ================  ================================================================
  ##  SockIdle          Socket has only just been initialised, not connected or closed.
  ##  SockConnected     Socket is connected to a server.
  ##  SockConnecting    Socket is in the process of connecting to a server.
  ##  SockListening     Socket is a server socket and is listening for connections.
  ##  SockClosed        Socket has been closed.
  ##  SockUDPBound      Socket is a UDP socket which is listening for data.
  ## ================  ================================================================
  ##
  ## **Warning**: If ``state`` is set incorrectly the resulting ``PAsyncSocket``
  ## object may not work properly.
  ##
  ## **Note**: This will set ``sock`` to be non-blocking.
  result = newAsyncSocket()
  result.socket = sock
  result.proto = if state == SockUDPBound: IPPROTO_UDP else: IPPROTO_TCP
  result.socket.setBlocking(false)
  result.info = state

proc asyncSockHandleRead(h: PObject) =
  when defined(ssl):
    if PAsyncSocket(h).socket.isSSL and not
         PAsyncSocket(h).socket.gotHandshake:
      return

  if PAsyncSocket(h).info != SockListening:
    if PAsyncSocket(h).info != SockConnecting:
      PAsyncSocket(h).handleRead(PAsyncSocket(h))
  else:
    PAsyncSocket(h).handleAccept(PAsyncSocket(h))

proc close*(sock: PAsyncSocket)
proc asyncSockHandleWrite(h: PObject) =
  when defined(ssl):
    if PAsyncSocket(h).socket.isSSL and not
         PAsyncSocket(h).socket.gotHandshake:
      return

  if PAsyncSocket(h).info == SockConnecting:
    PAsyncSocket(h).handleConnect(PAsyncSocket(h))
    PAsyncSocket(h).info = SockConnected
    # Stop receiving write events if there is no handleWrite event.
    if PAsyncSocket(h).handleWrite == nil:
      PAsyncSocket(h).deleg.mode = fmRead
    else:
      PAsyncSocket(h).deleg.mode = fmReadWrite
  else:
    if PAsyncSocket(h).sendBuffer != "":
      let sock = PAsyncSocket(h)
      try:
        let bytesSent = sock.socket.sendAsync(sock.sendBuffer)
        assert bytesSent > 0
        if bytesSent != sock.sendBuffer.len:
          sock.sendBuffer = sock.sendBuffer[bytesSent .. -1]
        elif bytesSent == sock.sendBuffer.len:
          sock.sendBuffer = ""

        if PAsyncSocket(h).handleWrite != nil:
          PAsyncSocket(h).handleWrite(PAsyncSocket(h))
      except EOS:
        # Most likely the socket closed before the full buffer could be sent to it.
        sock.close() # TODO: Provide a handleError for users?
    else:
      if PAsyncSocket(h).handleWrite != nil:
        PAsyncSocket(h).handleWrite(PAsyncSocket(h))
      else:
        PAsyncSocket(h).deleg.mode = fmRead

when defined(ssl):
  proc asyncSockDoHandshake(h: PObject) =
    if PAsyncSocket(h).socket.isSSL and not
         PAsyncSocket(h).socket.gotHandshake:
      if PAsyncSocket(h).sslNeedAccept:
        var d = ""
        let ret = PAsyncSocket(h).socket.acceptAddrSSL(PAsyncSocket(h).socket, d)
        assert ret != AcceptNoClient
        if ret == AcceptSuccess:
          PAsyncSocket(h).info = SockConnected
      else:
        # handshake will set socket's ``sslNoHandshake`` field.
        discard PAsyncSocket(h).socket.handshake()


proc asyncSockTask(h: PObject) =
  when defined(ssl):
    h.asyncSockDoHandshake()

  PAsyncSocket(h).handleTask(PAsyncSocket(h))

proc toDelegate(sock: PAsyncSocket): PDelegate =
  result = newDelegate()
  result.deleVal = sock
  result.fd = getFD(sock.socket)
  # We need this to get write events, just to know when the socket connects.
  result.mode = fmReadWrite
  result.handleRead = asyncSockHandleRead
  result.handleWrite = asyncSockHandleWrite
  result.task = asyncSockTask
  # TODO: Errors?
  #result.handleError = (proc (h: PObject) = assert(false))

  result.hasDataBuffered =
    proc (h: PObject): bool {.nimcall.} =
      return PAsyncSocket(h).socket.hasDataBuffered()

  sock.deleg = result
  if sock.info notin {SockIdle, SockClosed}:
    sock.deleg.open = true
  else:
    sock.deleg.open = false

proc connect*(sock: PAsyncSocket, name: string, port = TPort(0),
                   af: TDomain = AF_INET) =
  ## Begins connecting ``sock`` to ``name``:``port``.
  sock.socket.connectAsync(name, port, af)
  sock.info = SockConnecting
  if sock.deleg != nil:
    sock.deleg.open = true

proc close*(sock: PAsyncSocket) =
  ## Closes ``sock``. Terminates any current connections.
  sock.socket.close()
  sock.info = SockClosed
  if sock.deleg != nil:
    sock.deleg.open = false

proc bindAddr*(sock: PAsyncSocket, port = TPort(0), address = "") =
  ## Equivalent to ``sockets.bindAddr``.
  sock.socket.bindAddr(port, address)
  if sock.proto == IPPROTO_UDP:
    sock.info = SockUDPBound
    if sock.deleg != nil:
      sock.deleg.open = true

proc listen*(sock: PAsyncSocket) =
  ## Equivalent to ``sockets.listen``.
  sock.socket.listen()
  sock.info = SockListening
  if sock.deleg != nil:
    sock.deleg.open = true

proc acceptAddr*(server: PAsyncSocket, client: var PAsyncSocket,
                 address: var string) =
  ## Equivalent to ``sockets.acceptAddr``. This procedure should be called in
  ## a ``handleAccept`` event handler **only** once.
  ##
  ## **Note**: ``client`` needs to be initialised.
  assert(client != nil)
  client = newAsyncSocket()
  var c: TSocket
  new(c)
  when defined(ssl):
    if server.socket.isSSL:
      var ret = server.socket.acceptAddrSSL(c, address)
      # The following shouldn't happen because when this function is called
      # it is guaranteed that there is a client waiting.
      # (This should be called in handleAccept)
      assert(ret != AcceptNoClient)
      if ret == AcceptNoHandshake:
        client.sslNeedAccept = true
      else:
        client.sslNeedAccept = false
        client.info = SockConnected
    else:
      server.socket.acceptAddr(c, address)
      client.sslNeedAccept = false
      client.info = SockConnected
  else:
    server.socket.acceptAddr(c, address)
    client.sslNeedAccept = false
    client.info = SockConnected

  if c == InvalidSocket: SocketError(server.socket)
  c.setBlocking(false) # TODO: Needs to be tested.

  # deleg.open is set in ``toDelegate``.

  client.socket = c
  client.lineBuffer = "".TaintedString
  client.sendBuffer = ""
  client.info = SockConnected

proc accept*(server: PAsyncSocket, client: var PAsyncSocket) =
  ## Equivalent to ``sockets.accept``.
  var dummyAddr = ""
  server.acceptAddr(client, dummyAddr)

proc acceptAddr*(server: PAsyncSocket): tuple[sock: PAsyncSocket,
                                              address: string] {.deprecated.} =
  ## Equivalent to ``sockets.acceptAddr``.
  ##
  ## **Deprecated since version 0.9.0:** Please use the function above.
  var client = newAsyncSocket()
  var address: string = ""
  acceptAddr(server, client, address)
  return (client, address)

proc accept*(server: PAsyncSocket): PAsyncSocket {.deprecated.} =
  ## Equivalent to ``sockets.accept``.
  ##
  ## **Deprecated since version 0.9.0:** Please use the function above.
  new(result)
  var address = ""
  server.acceptAddr(result, address)

proc newDispatcher*(): PDispatcher =
  new(result)
  result.delegates = @[]

proc register*(d: PDispatcher, deleg: PDelegate) =
  ## Registers delegate ``deleg`` with dispatcher ``d``.
  d.delegates.add(deleg)

proc register*(d: PDispatcher, sock: PAsyncSocket): PDelegate {.discardable.} =
  ## Registers async socket ``sock`` with dispatcher ``d``.
  result = sock.toDelegate()
  d.register(result)

proc unregister*(d: PDispatcher, deleg: PDelegate) =
  ## Unregisters deleg ``deleg`` from dispatcher ``d``.
  for i in 0..len(d.delegates)-1:
    if d.delegates[i] == deleg:
      d.delegates.del(i)
      return
  raise newException(EInvalidIndex, "Could not find delegate.")

proc isWriteable*(s: PAsyncSocket): bool =
  ## Determines whether socket ``s`` is ready to be written to.
  var writeSock = @[s.socket]
  return selectWrite(writeSock, 1) != 0 and s.socket notin writeSock

converter getSocket*(s: PAsyncSocket): TSocket =
  return s.socket

proc isConnected*(s: PAsyncSocket): bool =
  ## Determines whether ``s`` is connected.
  return s.info == SockConnected
proc isListening*(s: PAsyncSocket): bool =
  ## Determines whether ``s`` is listening for incoming connections.
  return s.info == SockListening
proc isConnecting*(s: PAsyncSocket): bool =
  ## Determines whether ``s`` is connecting.
  return s.info == SockConnecting
proc isClosed*(s: PAsyncSocket): bool =
  ## Determines whether ``s`` has been closed.
  return s.info == SockClosed
proc isSendDataBuffered*(s: PAsyncSocket): bool =
  ## Determines whether ``s`` has data waiting to be sent, i.e. whether this
  ## socket's sendBuffer contains data.
  return s.sendBuffer.len != 0

proc setHandleWrite*(s: PAsyncSocket,
    handleWrite: proc (s: PAsyncSocket) {.closure.}) =
  ## Setter for the ``handleWrite`` event.
  ##
  ## To remove this event you should use the ``delHandleWrite`` function.
  ## It is advised to use that function instead of just setting the event to
  ## ``proc (s: PAsyncSocket) = nil`` as that would mean that that function
  ## would be called constantly.
  s.deleg.mode = fmReadWrite
  s.handleWrite = handleWrite

proc delHandleWrite*(s: PAsyncSocket) =
  ## Removes the ``handleWrite`` event handler on ``s``.
  s.handleWrite = nil

{.push warning[deprecated]: off.}
proc recvLine*(s: PAsyncSocket, line: var TaintedString): bool {.deprecated.} =
  ## Behaves similar to ``sockets.recvLine``, however it handles non-blocking
  ## sockets properly. This function guarantees that ``line`` is a full line,
  ## if this function can only retrieve some data; it will save this data and
  ## add it to the result when a full line is retrieved.
  ##
  ## Unlike ``sockets.recvLine`` this function will raise an EOS or ESSL
  ## exception if an error occurs.
  ##
  ## **Deprecated since version 0.9.2**: This function has been deprecated in
  ## favour of readLine.
  setLen(line.string, 0)
  var dataReceived = "".TaintedString
  var ret = s.socket.recvLineAsync(dataReceived)
  case ret
  of RecvFullLine:
    if s.lineBuffer.len > 0:
      string(line).add(s.lineBuffer.string)
      setLen(s.lineBuffer.string, 0)
    string(line).add(dataReceived.string)
    if string(line) == "":
      line = "\c\L".TaintedString
    result = true
  of RecvPartialLine:
    string(s.lineBuffer).add(dataReceived.string)
    result = false
  of RecvDisconnected:
    result = true
  of RecvFail:
    s.SocketError(async = true)
    result = false
{.pop.}

proc readLine*(s: PAsyncSocket, line: var TaintedString): bool =
  ## Behaves similar to ``sockets.readLine``, however it handles non-blocking
  ## sockets properly. This function guarantees that ``line`` is a full line,
  ## if this function can only retrieve some data; it will save this data and
  ## add it to the result when a full line is retrieved, when this happens
  ## False will be returned. True will only be returned if a full line has been
  ## retrieved or the socket has been disconnected in which case ``line`` will
  ## be set to "".
  ##
  ## This function will raise an EOS exception when a socket error occurs.
  setLen(line.string, 0)
  var dataReceived = "".TaintedString
  var ret = s.socket.readLineAsync(dataReceived)
  case ret
  of ReadFullLine:
    if s.lineBuffer.len > 0:
      string(line).add(s.lineBuffer.string)
      setLen(s.lineBuffer.string, 0)
    string(line).add(dataReceived.string)
    if string(line) == "":
      line = "\c\L".TaintedString
    result = true
  of ReadPartialLine:
    string(s.lineBuffer).add(dataReceived.string)
    result = false
  of ReadNone:
    result = false
  of ReadDisconnected:
    result = true

proc send*(sock: PAsyncSocket, data: string) =
  ## Sends ``data`` to socket ``sock``. This is basically a nicer implementation
  ## of ``sockets.sendAsync``.
  ##
  ## If ``data`` cannot be sent immediately it will be buffered and sent
  ## when ``sock`` becomes writeable (during the ``handleWrite`` event).
  ## It's possible that only a part of ``data`` will be sent immediately, while
  ## the rest of it will be buffered and sent later.
  if sock.sendBuffer.len != 0:
    sock.sendBuffer.add(data)
    return
  let bytesSent = sock.socket.sendAsync(data)
  assert bytesSent >= 0
  if bytesSent == 0:
    sock.sendBuffer.add(data)
    sock.deleg.mode = fmReadWrite
  elif bytesSent != data.len:
    sock.sendBuffer.add(data[bytesSent .. -1])
    sock.deleg.mode = fmReadWrite

proc timeValFromMilliseconds(timeout = 500): TTimeVal =
  if timeout != -1:
    var seconds = timeout div 1000
    result.tv_sec = seconds.int32
    result.tv_usec = ((timeout - seconds * 1000) * 1000).int32

proc createFdSet(fd: var TFdSet, s: seq[PDelegate], m: var int) =
  FD_ZERO(fd)
  for i in items(s):
    m = max(m, int(i.fd))
    FD_SET(i.fd, fd)

proc pruneSocketSet(s: var seq[PDelegate], fd: var TFdSet) =
  var i = 0
  var L = s.len
  while i < L:
    if FD_ISSET(s[i].fd, fd) != 0'i32:
      s[i] = s[L-1]
      dec(L)
    else:
      inc(i)
  setLen(s, L)

proc select(readfds, writefds, exceptfds: var seq[PDelegate],
             timeout = 500): int =
  var tv {.noInit.}: TTimeVal = timeValFromMilliseconds(timeout)

  var rd, wr, ex: TFdSet
  var m = 0
  createFdSet(rd, readfds, m)
  createFdSet(wr, writefds, m)
  createFdSet(ex, exceptfds, m)

  if timeout != -1:
    result = int(select(cint(m+1), addr(rd), addr(wr), addr(ex), addr(tv)))
  else:
    result = int(select(cint(m+1), addr(rd), addr(wr), addr(ex), nil))

  pruneSocketSet(readfds, (rd))
  pruneSocketSet(writefds, (wr))
  pruneSocketSet(exceptfds, (ex))

proc poll*(d: PDispatcher, timeout: int = 500): bool =
  ## This function checks for events on all the delegates in the `PDispatcher`.
  ## It then proceeds to call the correct event handler.
  ##
  ## This function returns ``True`` if there are file descriptors that are still
  ## open, otherwise ``False``. File descriptors that have been
  ## closed are immediately removed from the dispatcher automatically.
  ##
  ## **Note:** Each delegate has a task associated with it. This gets called
  ## after each select() call, if you set timeout to ``-1`` the tasks will
  ## only be executed after one or more file descriptors becomes readable or
  ## writeable.
  result = true
  var readDg, writeDg, errorDg: seq[PDelegate] = @[]
  var len = d.delegates.len
  var dc = 0

  while dc < len:
    let deleg = d.delegates[dc]
    if (deleg.mode != fmWrite or deleg.mode != fmAppend) and deleg.open:
      readDg.add(deleg)
    if (deleg.mode != fmRead) and deleg.open:
      writeDg.add(deleg)
    if deleg.open:
      errorDg.add(deleg)
      inc dc
    else:
      # File/socket has been closed. Remove it from dispatcher.
      d.delegates[dc] = d.delegates[len-1]
      dec len

  d.delegates.setLen(len)

  var hasDataBufferedCount = 0
  for d in d.delegates:
    if d.hasDataBuffered(d.deleVal):
      hasDataBufferedCount.inc()
      d.handleRead(d.deleVal)
  if hasDataBufferedCount > 0: return True

  if readDg.len() == 0 and writeDg.len() == 0:
    ## TODO: Perhaps this shouldn't return if errorDg has something?
    return False

  if select(readDg, writeDg, errorDg, timeout) != 0:
    for i in 0..len(d.delegates)-1:
      if i > len(d.delegates)-1: break # One delegate might've been removed.
      let deleg = d.delegates[i]
      if not deleg.open: continue # This delegate might've been closed.
      if (deleg.mode != fmWrite or deleg.mode != fmAppend) and
          deleg notin readDg:
        deleg.handleRead(deleg.deleVal)
      if (deleg.mode != fmRead) and deleg notin writeDg:
        deleg.handleWrite(deleg.deleVal)
      if deleg notin errorDg:
        deleg.handleError(deleg.deleVal)

  # Execute tasks
  for i in items(d.delegates):
    i.task(i.deleVal)

proc len*(disp: PDispatcher): int =
  ## Retrieves the amount of delegates in ``disp``.
  return disp.delegates.len

when isMainModule:

  proc testConnect(s: PAsyncSocket, no: int) =
    echo("Connected! " & $no)

  proc testRead(s: PAsyncSocket, no: int) =
    echo("Reading! " & $no)
    var data = ""
    if not s.readLine(data): return
    if data == "":
      echo("Closing connection. " & $no)
      s.close()
    echo(data)
    echo("Finished reading! " & $no)

  proc testAccept(s: PAsyncSocket, disp: PDispatcher, no: int) =
    echo("Accepting client! " & $no)
    var client: PAsyncSocket
    new(client)
    var address = ""
    s.acceptAddr(client, address)
    echo("Accepted ", address)
    client.handleRead =
      proc (s: PAsyncSocket) =
        testRead(s, 2)
    disp.register(client)

  var d = newDispatcher()

  var s = AsyncSocket()
  s.connect("amber.tenthbit.net", TPort(6667))
  s.handleConnect =
    proc (s: PAsyncSocket) =
      testConnect(s, 1)
  s.handleRead =
    proc (s: PAsyncSocket) =
      testRead(s, 1)
  d.register(s)

  var server = AsyncSocket()
  server.handleAccept =
    proc (s: PAsyncSocket) =
      testAccept(s, d, 78)
  server.bindAddr(TPort(5555))
  server.listen()
  d.register(server)

  while d.poll(-1): nil

