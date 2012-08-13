#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf, Dominik Picheta
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import sockets, os

## This module implements an asynchronous event loop for sockets. 
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
##    proc handleAccept(s: PAsyncSocket, arg: Pobject) {.nimcall.} =
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



type

  TDelegate = object
    deleVal*: PObject

    handleRead*: proc (h: PObject) {.nimcall.}
    handleWrite*: proc (h: PObject) {.nimcall.}
    handleConnect*: proc (h: PObject) {.nimcall.}

    handleAccept*: proc (h: PObject) {.nimcall.}
    getSocket*: proc (h: PObject): tuple[info: TInfo, sock: TSocket] {.nimcall.}

    task*: proc (h: PObject) {.nimcall.}
    mode*: TMode
    
  PDelegate* = ref TDelegate

  PDispatcher* = ref TDispatcher
  TDispatcher = object
    delegates: seq[PDelegate]

  PAsyncSocket* = ref TAsyncSocket
  TAsyncSocket* = object of TObject
    socket: TSocket
    info: TInfo

    handleRead*: proc (s: PAsyncSocket) {.closure.}
    handleConnect*: proc (s:  PAsyncSocket) {.closure.}

    handleAccept*: proc (s:  PAsyncSocket) {.closure.}

    lineBuffer: TaintedString ## Temporary storage for ``recvLine``
    sslNeedAccept: bool
    proto: TProtocol

  TInfo* = enum
    SockIdle, SockConnecting, SockConnected, SockListening, SockClosed, SockUDPBound
  
  TMode* = enum
    MReadable, MWriteable, MReadWrite

proc newDelegate*(): PDelegate =
  ## Creates a new delegate.
  new(result)
  result.handleRead = (proc (h: PObject) = nil)
  result.handleWrite = (proc (h: PObject) = nil)
  result.handleConnect = (proc (h: PObject) = nil)
  result.handleAccept = (proc (h: PObject) = nil)
  result.getSocket = (proc (h: PObject): tuple[info: TInfo, sock: TSocket] =
                        doAssert(false))
  result.task = (proc (h: PObject) = nil)
  result.mode = MReadable

proc newAsyncSocket(): PAsyncSocket =
  new(result)
  result.info = SockIdle

  result.handleRead = (proc (s: PAsyncSocket) = nil)
  result.handleConnect = (proc (s: PAsyncSocket) = nil)
  result.handleAccept = (proc (s: PAsyncSocket) = nil)

  result.lineBuffer = "".TaintedString

proc AsyncSocket*(domain: TDomain = AF_INET, typ: TType = SOCK_STREAM, 
                  protocol: TProtocol = IPPROTO_TCP, 
                  buffered = true): PAsyncSocket =
  result = newAsyncSocket()
  result.socket = socket(domain, typ, protocol, buffered)
  result.proto = protocol
  if result.socket == InvalidSocket: OSError()
  result.socket.setBlocking(false)

proc asyncSockHandleConnect(h: PObject) =
  when defined(ssl):
    if PAsyncSocket(h).socket.isSSL and not
         PAsyncSocket(h).socket.gotHandshake:
      return  
      
  PAsyncSocket(h).info = SockConnected
  PAsyncSocket(h).handleConnect(PAsyncSocket(h))

proc asyncSockHandleRead(h: PObject) =
  when defined(ssl):
    if PAsyncSocket(h).socket.isSSL and not
         PAsyncSocket(h).socket.gotHandshake:
      return
  PAsyncSocket(h).handleRead(PAsyncSocket(h))

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

proc toDelegate(sock: PAsyncSocket): PDelegate =
  result = newDelegate()
  result.deleVal = sock
  result.getSocket = (proc (h: PObject): tuple[info: TInfo, sock: TSocket] =
                        return (PAsyncSocket(h).info, PAsyncSocket(h).socket))

  result.handleConnect = asyncSockHandleConnect
  
  result.handleRead = asyncSockHandleRead
  
  result.handleAccept = (proc (h: PObject) =
                           PAsyncSocket(h).handleAccept(PAsyncSocket(h)))

  when defined(ssl):
    result.task = asyncSockDoHandshake

proc connect*(sock: PAsyncSocket, name: string, port = TPort(0),
                   af: TDomain = AF_INET) =
  ## Begins connecting ``sock`` to ``name``:``port``.
  sock.socket.connectAsync(name, port, af)
  sock.info = SockConnecting

proc close*(sock: PAsyncSocket) =
  ## Closes ``sock``. Terminates any current connections.
  sock.info = SockClosed
  sock.socket.close()

proc bindAddr*(sock: PAsyncSocket, port = TPort(0), address = "") =
  ## Equivalent to ``sockets.bindAddr``.
  sock.socket.bindAddr(port, address)
  if sock.proto == IPPROTO_UDP:
    sock.info = SockUDPBound

proc listen*(sock: PAsyncSocket) =
  ## Equivalent to ``sockets.listen``.
  sock.socket.listen()
  sock.info = SockListening

proc acceptAddr*(server: PAsyncSocket, client: var PAsyncSocket,
                 address: var string) =
  ## Equivalent to ``sockets.acceptAddr``. This procedure should be called in
  ## a ``handleAccept`` event handler **only** once.
  ##
  ## **Note**: ``client`` needs to be initialised.
  assert(client != nil)
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

  if c == InvalidSocket: OSError()
  c.setBlocking(false) # TODO: Needs to be tested.
  
  client.socket = c
  client.lineBuffer = ""

proc accept*(server: PAsyncSocket, client: var PAsyncSocket) =
  ## Equivalent to ``sockets.accept``.
  var dummyAddr = ""
  server.acceptAddr(client, dummyAddr)

proc acceptAddr*(server: PAsyncSocket): tuple[sock: PAsyncSocket,
                                              address: string] {.deprecated.} =
  ## Equivalent to ``sockets.acceptAddr``.
  ## 
  ## **Warning**: This is deprecated in favour of the above.
  var client = newAsyncSocket()
  var address: string = ""
  acceptAddr(server, client, address)
  return (client, address)

proc accept*(server: PAsyncSocket): PAsyncSocket {.deprecated.} =
  ## Equivalent to ``sockets.accept``.
  ##
  ## **Warning**: This is deprecated.
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

proc `userArg=`*(s: PAsyncSocket, val: PObject) =
  s.userArg = val

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

proc recvLine*(s: PAsyncSocket, line: var TaintedString): bool =
  ## Behaves similar to ``sockets.recvLine``, however it handles non-blocking
  ## sockets properly. This function guarantees that ``line`` is a full line,
  ## if this function can only retrieve some data; it will save this data and
  ## add it to the result when a full line is retrieved.
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
    result = false

proc poll*(d: PDispatcher, timeout: int = 500): bool =
  ## This function checks for events on all the sockets in the `PDispatcher`.
  ## It then proceeds to call the correct event handler.
  ## 
  ## **Note:** There is no event which signifes when you have been disconnected,
  ## it is your job to check whether what you get from ``recv`` is ``""``.
  ## If you have been disconnected, `d`'s ``getSocket`` function should report
  ## this appropriately.
  ##
  ## This function returns ``True`` if there are sockets that are still 
  ## connected (or connecting), otherwise ``False``. Sockets that have been
  ## closed are immediately removed from the dispatcher automatically.
  ##
  ## **Note:** Each delegate has a task associated with it. This gets called
  ## after each select() call, if you make timeout ``-1`` the tasks will
  ## only be executed after one or more sockets becomes readable or writeable.
  
  result = true
  var readSocks, writeSocks: seq[TSocket] = @[]
  
  var L = d.delegates.len
  var dc = 0
  while dc < L:
    template deleg: expr = d.delegates[dc]
    let aSock = deleg.getSocket(deleg.deleVal)
    if (deleg.mode != MWriteable and aSock.info == SockConnected) or
          aSock.info == SockListening or aSock.info == SockUDPBound:
      readSocks.add(aSock.sock)
    if aSock.info == SockConnecting or
        (aSock.info == SockConnected and deleg.mode != MReadable):
      writeSocks.add(aSock.sock)
    if aSock.info == SockClosed:
      # Socket has been closed remove it from the dispatcher.
      d.delegates[dc] = d.delegates[L-1]
      
      dec L
    else: inc dc
  d.delegates.setLen(L)
  
  if readSocks.len() == 0 and writeSocks.len() == 0:
    return False

  if select(readSocks, writeSocks, timeout) != 0:
    for i in 0..len(d.delegates)-1:
      if i > len(d.delegates)-1: break # One delegate might've been removed.
      let deleg = d.delegates[i]
      let sock = deleg.getSocket(deleg.deleVal)
      if sock.info == SockConnected or 
         sock.info == SockUDPBound:
        if deleg.mode != MWriteable and sock.sock notin readSocks:
          if not (sock.info == SockConnecting):
            assert(not (sock.info == SockListening))
            deleg.handleRead(deleg.deleVal)
          else:
            assert(false)
        if deleg.mode != MReadable and sock.sock notin writeSocks:
          deleg.handleWrite(deleg.deleVal)
      
      if sock.info == SockListening:
        if sock.sock notin readSocks:
          # This is a server socket, that had listen() called on it.
          # This socket should have a client waiting now.
          deleg.handleAccept(deleg.deleVal)
      
      if sock.info == SockConnecting:
        # Checking whether the socket has connected this way should work on
        # Windows and Posix. I've checked. 
        if sock.sock notin writeSocks:
          deleg.handleConnect(deleg.deleVal)
  
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
    var data = s.getSocket.recv()
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
    
