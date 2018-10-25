#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf, Dominik Picheta
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

include "system/inclrtl"

import sockets, os

##
## **Warning:** This module is deprecated since version 0.10.2.
## Use the brand new `asyncdispatch <asyncdispatch.html>`_ module together
## with the `asyncnet <asyncnet.html>`_ module.

## This module implements an asynchronous event loop together with asynchronous
## sockets which use this event loop.
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
## ``RootObj``!
##
## **Note:** If you want to provide async ability to your module please do not
## use the ``Delegate`` object, instead use ``AsyncSocket``. It is possible
## that in the future this type's fields will not be exported therefore breaking
## your code.
##
## **Warning:** The API of this module is unstable, and therefore is subject
## to change.
##
## Asynchronous sockets
## ====================
##
## For most purposes you do not need to worry about the ``Delegate`` type. The
## ``AsyncSocket`` is what you are after. It's a reference to
## the ``AsyncSocketObj`` object. This object defines events which you should
## overwrite by your own procedures.
##
## For server sockets the only event you need to worry about is the ``handleAccept``
## event, in your handleAccept proc you should call ``accept`` on the server
## socket which will give you the client which is connecting. You should then
## set any events that you want to use on that client and add it to your dispatcher
## using the ``register`` procedure.
##
## An example ``handleAccept`` follows:
##
## .. code-block:: nim
##
##    var disp = newDispatcher()
##    ...
##    proc handleAccept(s: AsyncSocket) =
##      echo("Accepted client.")
##      var client: AsyncSocket
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
## Getting a blocking client from an AsyncSocket
## =============================================
##
## If you need a asynchronous server socket but you wish to process the clients
## synchronously then you can use the ``getSocket`` converter to get
## a ``Socket`` from the ``AsyncSocket`` object, this can then be combined
## with ``accept`` like so:
##
## .. code-block:: nim
##
##    proc handleAccept(s: AsyncSocket) =
##      var client: Socket
##      getSocket(s).accept(client)

{.deprecated.}

when defined(windows):
  from winlean import TimeVal, SocketHandle, FD_SET, FD_ZERO, TFdSet,
    FD_ISSET, select
else:
  from posix import TimeVal, Time, Suseconds, SocketHandle, FD_SET, FD_ZERO,
    TFdSet, FD_ISSET, select

type
  DelegateObj* = object
    fd*: SocketHandle
    deleVal*: RootRef

    handleRead*: proc (h: RootRef) {.nimcall, gcsafe.}
    handleWrite*: proc (h: RootRef) {.nimcall, gcsafe.}
    handleError*: proc (h: RootRef) {.nimcall, gcsafe.}
    hasDataBuffered*: proc (h: RootRef): bool {.nimcall, gcsafe.}

    open*: bool
    task*: proc (h: RootRef) {.nimcall, gcsafe.}
    mode*: FileMode

  Delegate* = ref DelegateObj

  Dispatcher* = ref DispatcherObj
  DispatcherObj = object
    delegates: seq[Delegate]

  AsyncSocket* = ref AsyncSocketObj
  AsyncSocketObj* = object of RootObj
    socket: Socket
    info: SocketStatus

    handleRead*: proc (s: AsyncSocket) {.closure, gcsafe.}
    handleWrite: proc (s: AsyncSocket) {.closure, gcsafe.}
    handleConnect*: proc (s:  AsyncSocket) {.closure, gcsafe.}

    handleAccept*: proc (s:  AsyncSocket) {.closure, gcsafe.}

    handleTask*: proc (s: AsyncSocket) {.closure, gcsafe.}

    lineBuffer: TaintedString ## Temporary storage for ``readLine``
    sendBuffer: string ## Temporary storage for ``send``
    sslNeedAccept: bool
    proto: Protocol
    deleg: Delegate

  SocketStatus* = enum
    SockIdle, SockConnecting, SockConnected, SockListening, SockClosed,
    SockUDPBound

{.deprecated: [TDelegate: DelegateObj, PDelegate: Delegate,
  TInfo: SocketStatus, PAsyncSocket: AsyncSocket, TAsyncSocket: AsyncSocketObj,
  TDispatcher: DispatcherObj, PDispatcher: Dispatcher,
  ].}


proc newDelegate*(): Delegate =
  ## Creates a new delegate.
  new(result)
  result.handleRead = (proc (h: RootRef) = discard)
  result.handleWrite = (proc (h: RootRef) = discard)
  result.handleError = (proc (h: RootRef) = discard)
  result.hasDataBuffered = (proc (h: RootRef): bool = return false)
  result.task = (proc (h: RootRef) = discard)
  result.mode = fmRead

proc newAsyncSocket(): AsyncSocket =
  new(result)
  result.info = SockIdle

  result.handleRead = (proc (s: AsyncSocket) = discard)
  result.handleWrite = nil
  result.handleConnect = (proc (s: AsyncSocket) = discard)
  result.handleAccept = (proc (s: AsyncSocket) = discard)
  result.handleTask = (proc (s: AsyncSocket) = discard)

  result.lineBuffer = "".TaintedString
  result.sendBuffer = ""

proc asyncSocket*(domain: Domain = AF_INET, typ: SockType = SOCK_STREAM,
                  protocol: Protocol = IPPROTO_TCP,
                  buffered = true): AsyncSocket =
  ## Initialises an AsyncSocket object. If a socket cannot be initialised
  ## OSError is raised.
  result = newAsyncSocket()
  result.socket = socket(domain, typ, protocol, buffered)
  result.proto = protocol
  if result.socket == invalidSocket: raiseOSError(osLastError())
  result.socket.setBlocking(false)

proc toAsyncSocket*(sock: Socket, state: SocketStatus = SockConnected): AsyncSocket =
  ## Wraps an already initialized ``Socket`` into a AsyncSocket.
  ## This is useful if you want to use an already connected Socket as an
  ## asynchronous AsyncSocket in asyncio's event loop.
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
  ## **Warning**: If ``state`` is set incorrectly the resulting ``AsyncSocket``
  ## object may not work properly.
  ##
  ## **Note**: This will set ``sock`` to be non-blocking.
  result = newAsyncSocket()
  result.socket = sock
  result.proto = if state == SockUDPBound: IPPROTO_UDP else: IPPROTO_TCP
  result.socket.setBlocking(false)
  result.info = state

proc asyncSockHandleRead(h: RootRef) =
  when defined(ssl):
    if AsyncSocket(h).socket.isSSL and not
         AsyncSocket(h).socket.gotHandshake:
      return

  if AsyncSocket(h).info != SockListening:
    if AsyncSocket(h).info != SockConnecting:
      AsyncSocket(h).handleRead(AsyncSocket(h))
  else:
    AsyncSocket(h).handleAccept(AsyncSocket(h))

proc close*(sock: AsyncSocket) {.gcsafe.}
proc asyncSockHandleWrite(h: RootRef) =
  when defined(ssl):
    if AsyncSocket(h).socket.isSSL and not
         AsyncSocket(h).socket.gotHandshake:
      return

  if AsyncSocket(h).info == SockConnecting:
    AsyncSocket(h).handleConnect(AsyncSocket(h))
    AsyncSocket(h).info = SockConnected
    # Stop receiving write events if there is no handleWrite event.
    if AsyncSocket(h).handleWrite == nil:
      AsyncSocket(h).deleg.mode = fmRead
    else:
      AsyncSocket(h).deleg.mode = fmReadWrite
  else:
    if AsyncSocket(h).sendBuffer != "":
      let sock = AsyncSocket(h)
      try:
        let bytesSent = sock.socket.sendAsync(sock.sendBuffer)
        if bytesSent == 0:
          # Apparently the socket cannot be written to. Even though select
          # just told us that it can be... This used to be an assert. Just
          # do nothing instead.
          discard
        elif bytesSent != sock.sendBuffer.len:
          sock.sendBuffer = sock.sendBuffer[bytesSent .. ^1]
        elif bytesSent == sock.sendBuffer.len:
          sock.sendBuffer = ""

        if AsyncSocket(h).handleWrite != nil:
          AsyncSocket(h).handleWrite(AsyncSocket(h))
      except OSError:
        # Most likely the socket closed before the full buffer could be sent to it.
        sock.close() # TODO: Provide a handleError for users?
    else:
      if AsyncSocket(h).handleWrite != nil:
        AsyncSocket(h).handleWrite(AsyncSocket(h))
      else:
        AsyncSocket(h).deleg.mode = fmRead

when defined(ssl):
  proc asyncSockDoHandshake(h: RootRef) {.gcsafe.} =
    if AsyncSocket(h).socket.isSSL and not
         AsyncSocket(h).socket.gotHandshake:
      if AsyncSocket(h).sslNeedAccept:
        var d = ""
        let ret = AsyncSocket(h).socket.acceptAddrSSL(AsyncSocket(h).socket, d)
        assert ret != AcceptNoClient
        if ret == AcceptSuccess:
          AsyncSocket(h).info = SockConnected
      else:
        # handshake will set socket's ``sslNoHandshake`` field.
        discard AsyncSocket(h).socket.handshake()


proc asyncSockTask(h: RootRef) =
  when defined(ssl):
    h.asyncSockDoHandshake()

  AsyncSocket(h).handleTask(AsyncSocket(h))

proc toDelegate(sock: AsyncSocket): Delegate =
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
    proc (h: RootRef): bool {.nimcall.} =
      return AsyncSocket(h).socket.hasDataBuffered()

  sock.deleg = result
  if sock.info notin {SockIdle, SockClosed}:
    sock.deleg.open = true
  else:
    sock.deleg.open = false

proc connect*(sock: AsyncSocket, name: string, port = Port(0),
                   af: Domain = AF_INET) =
  ## Begins connecting ``sock`` to ``name``:``port``.
  sock.socket.connectAsync(name, port, af)
  sock.info = SockConnecting
  if sock.deleg != nil:
    sock.deleg.open = true

proc close*(sock: AsyncSocket) =
  ## Closes ``sock``. Terminates any current connections.
  sock.socket.close()
  sock.info = SockClosed
  if sock.deleg != nil:
    sock.deleg.open = false

proc bindAddr*(sock: AsyncSocket, port = Port(0), address = "") =
  ## Equivalent to ``sockets.bindAddr``.
  sock.socket.bindAddr(port, address)
  if sock.proto == IPPROTO_UDP:
    sock.info = SockUDPBound
    if sock.deleg != nil:
      sock.deleg.open = true

proc listen*(sock: AsyncSocket) =
  ## Equivalent to ``sockets.listen``.
  sock.socket.listen()
  sock.info = SockListening
  if sock.deleg != nil:
    sock.deleg.open = true

proc acceptAddr*(server: AsyncSocket, client: var AsyncSocket,
                 address: var string) =
  ## Equivalent to ``sockets.acceptAddr``. This procedure should be called in
  ## a ``handleAccept`` event handler **only** once.
  ##
  ## **Note**: ``client`` needs to be initialised.
  assert(client != nil)
  client = newAsyncSocket()
  var c: Socket
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

  if c == invalidSocket: raiseSocketError(server.socket)
  c.setBlocking(false) # TODO: Needs to be tested.

  # deleg.open is set in ``toDelegate``.

  client.socket = c
  client.lineBuffer = "".TaintedString
  client.sendBuffer = ""
  client.info = SockConnected

proc accept*(server: AsyncSocket, client: var AsyncSocket) =
  ## Equivalent to ``sockets.accept``.
  var dummyAddr = ""
  server.acceptAddr(client, dummyAddr)

proc acceptAddr*(server: AsyncSocket): tuple[sock: AsyncSocket,
                                              address: string] {.deprecated.} =
  ## Equivalent to ``sockets.acceptAddr``.
  ##
  ## **Deprecated since version 0.9.0:** Please use the function above.
  var client = newAsyncSocket()
  var address: string = ""
  acceptAddr(server, client, address)
  return (client, address)

proc accept*(server: AsyncSocket): AsyncSocket {.deprecated.} =
  ## Equivalent to ``sockets.accept``.
  ##
  ## **Deprecated since version 0.9.0:** Please use the function above.
  new(result)
  var address = ""
  server.acceptAddr(result, address)

proc newDispatcher*(): Dispatcher =
  new(result)
  result.delegates = @[]

proc register*(d: Dispatcher, deleg: Delegate) =
  ## Registers delegate ``deleg`` with dispatcher ``d``.
  d.delegates.add(deleg)

proc register*(d: Dispatcher, sock: AsyncSocket): Delegate {.discardable.} =
  ## Registers async socket ``sock`` with dispatcher ``d``.
  result = sock.toDelegate()
  d.register(result)

proc unregister*(d: Dispatcher, deleg: Delegate) =
  ## Unregisters deleg ``deleg`` from dispatcher ``d``.
  for i in 0..len(d.delegates)-1:
    if d.delegates[i] == deleg:
      d.delegates.del(i)
      return
  raise newException(IndexError, "Could not find delegate.")

proc isWriteable*(s: AsyncSocket): bool =
  ## Determines whether socket ``s`` is ready to be written to.
  var writeSock = @[s.socket]
  return selectWrite(writeSock, 1) != 0 and s.socket notin writeSock

converter getSocket*(s: AsyncSocket): Socket =
  return s.socket

proc isConnected*(s: AsyncSocket): bool =
  ## Determines whether ``s`` is connected.
  return s.info == SockConnected
proc isListening*(s: AsyncSocket): bool =
  ## Determines whether ``s`` is listening for incoming connections.
  return s.info == SockListening
proc isConnecting*(s: AsyncSocket): bool =
  ## Determines whether ``s`` is connecting.
  return s.info == SockConnecting
proc isClosed*(s: AsyncSocket): bool =
  ## Determines whether ``s`` has been closed.
  return s.info == SockClosed
proc isSendDataBuffered*(s: AsyncSocket): bool =
  ## Determines whether ``s`` has data waiting to be sent, i.e. whether this
  ## socket's sendBuffer contains data.
  return s.sendBuffer.len != 0

proc setHandleWrite*(s: AsyncSocket,
    handleWrite: proc (s: AsyncSocket) {.closure, gcsafe.}) =
  ## Setter for the ``handleWrite`` event.
  ##
  ## To remove this event you should use the ``delHandleWrite`` function.
  ## It is advised to use that function instead of just setting the event to
  ## ``proc (s: AsyncSocket) = nil`` as that would mean that that function
  ## would be called constantly.
  s.deleg.mode = fmReadWrite
  s.handleWrite = handleWrite

proc delHandleWrite*(s: AsyncSocket) =
  ## Removes the ``handleWrite`` event handler on ``s``.
  s.handleWrite = nil

{.push warning[deprecated]: off.}
proc recvLine*(s: AsyncSocket, line: var TaintedString): bool {.deprecated.} =
  ## Behaves similar to ``sockets.recvLine``, however it handles non-blocking
  ## sockets properly. This function guarantees that ``line`` is a full line,
  ## if this function can only retrieve some data; it will save this data and
  ## add it to the result when a full line is retrieved.
  ##
  ## Unlike ``sockets.recvLine`` this function will raise an OSError or SslError
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
    s.raiseSocketError(async = true)
    result = false
{.pop.}

proc readLine*(s: AsyncSocket, line: var TaintedString): bool =
  ## Behaves similar to ``sockets.readLine``, however it handles non-blocking
  ## sockets properly. This function guarantees that ``line`` is a full line,
  ## if this function can only retrieve some data; it will save this data and
  ## add it to the result when a full line is retrieved, when this happens
  ## False will be returned. True will only be returned if a full line has been
  ## retrieved or the socket has been disconnected in which case ``line`` will
  ## be set to "".
  ##
  ## This function will raise an OSError exception when a socket error occurs.
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

proc send*(sock: AsyncSocket, data: string) =
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
    sock.sendBuffer.add(data[bytesSent .. ^1])
    sock.deleg.mode = fmReadWrite

proc timeValFromMilliseconds(timeout = 500): Timeval =
  if timeout != -1:
    var seconds = timeout div 1000
    when defined(posix):
      result.tv_sec = seconds.Time
      result.tv_usec = ((timeout - seconds * 1000) * 1000).Suseconds
    else:
      result.tv_sec = seconds.int32
      result.tv_usec = ((timeout - seconds * 1000) * 1000).int32

proc createFdSet(fd: var TFdSet, s: seq[Delegate], m: var int) =
  FD_ZERO(fd)
  for i in items(s):
    m = max(m, int(i.fd))
    FD_SET(i.fd, fd)

proc pruneSocketSet(s: var seq[Delegate], fd: var TFdSet) =
  var i = 0
  var L = s.len
  while i < L:
    if FD_ISSET(s[i].fd, fd) != 0'i32:
      s[i] = s[L-1]
      dec(L)
    else:
      inc(i)
  setLen(s, L)

proc select(readfds, writefds, exceptfds: var seq[Delegate],
             timeout = 500): int =
  var tv {.noInit.}: Timeval = timeValFromMilliseconds(timeout)

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

proc poll*(d: Dispatcher, timeout: int = 500): bool =
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
  var readDg, writeDg, errorDg: seq[Delegate] = @[]
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
  if hasDataBufferedCount > 0: return true

  if readDg.len() == 0 and writeDg.len() == 0:
    ## TODO: Perhaps this shouldn't return if errorDg has something?
    return false

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

proc len*(disp: Dispatcher): int =
  ## Retrieves the amount of delegates in ``disp``.
  return disp.delegates.len

when not defined(testing) and isMainModule:

  proc testConnect(s: AsyncSocket, no: int) =
    echo("Connected! " & $no)

  proc testRead(s: AsyncSocket, no: int) =
    echo("Reading! " & $no)
    var data = ""
    if not s.readLine(data): return
    if data == "":
      echo("Closing connection. " & $no)
      s.close()
    echo(data)
    echo("Finished reading! " & $no)

  proc testAccept(s: AsyncSocket, disp: Dispatcher, no: int) =
    echo("Accepting client! " & $no)
    var client: AsyncSocket
    new(client)
    var address = ""
    s.acceptAddr(client, address)
    echo("Accepted ", address)
    client.handleRead =
      proc (s: AsyncSocket) =
        testRead(s, 2)
    disp.register(client)

  proc main =
    var d = newDispatcher()

    var s = asyncSocket()
    s.connect("amber.tenthbit.net", Port(6667))
    s.handleConnect =
      proc (s: AsyncSocket) =
        testConnect(s, 1)
    s.handleRead =
      proc (s: AsyncSocket) =
        testRead(s, 1)
    d.register(s)

    var server = asyncSocket()
    server.handleAccept =
      proc (s: AsyncSocket) =
        testAccept(s, d, 78)
    server.bindAddr(Port(5555))
    server.listen()
    d.register(server)

    while d.poll(-1): discard
  main()
