#
#
#            Nim's Runtime Library
#        (c) Copyright 2014 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

include "system/inclrtl"

import os, oids, tables, strutils, macros, times

import rawsockets, net

export Port, SocketFlag

#{.injectStmt: newGcInvariant().}

## AsyncDispatch
## -------------
##
## This module implements a brand new dispatcher based on Futures.
## On Windows IOCP is used and on other operating systems the ``selectors``
## module is used instead.
##
## **Note:** This module is still largely experimental.


# TODO: ``except`` statement (without `try`) does not work.
# TODO: Multiple exception names in a ``except`` don't work.
# TODO: The effect system (raises: []) has trouble with my try transformation.
# TODO: Can't await in a 'except' body
# TODO: getCurrentException(Msg) don't work
# TODO: Check if yielded future is nil and throw a more meaningful exception

# -- Futures

type
  FutureBase* = ref object of RootObj
    cb: proc () {.closure,gcsafe.}
    finished: bool
    error*: ref Exception
    errorStackTrace*: string
    when not defined(release):
      stackTrace: string ## For debugging purposes only.
      id: int
      fromProc: string

  Future*[T] = ref object of FutureBase
    value: T

{.deprecated: [PFutureBase: FutureBase, PFuture: Future].}


var currentID* = 0
proc newFuture*[T](fromProc: string = "unspecified"): Future[T] =
  ## Creates a new future.
  ##
  ## Specifying ``fromProc``, which is a string specifying the name of the proc
  ## that this future belongs to, is a good habit as it helps with debugging.
  new(result)
  result.finished = false
  when not defined(release):
    result.stackTrace = getStackTrace()
    result.id = currentID
    result.fromProc = fromProc
    currentID.inc()

proc checkFinished[T](future: Future[T]) =
  when not defined(release):
    if future.finished:
      echo("<-----> ", future.id, " ", future.fromProc)
      echo(future.stackTrace)
      echo("-----")
      when T is string:
        echo("Contents: ", future.value.repr)
      echo("<----->")
      echo("Future already finished, cannot finish twice.")
      echo getStackTrace()
      assert false

proc complete*[T](future: Future[T], val: T) =
  ## Completes ``future`` with value ``val``.
  #assert(not future.finished, "Future already finished, cannot finish twice.")
  checkFinished(future)
  assert(future.error == nil)
  future.value = val
  future.finished = true
  if future.cb != nil:
    future.cb()

proc complete*(future: Future[void]) =
  ## Completes a void ``future``.
  #assert(not future.finished, "Future already finished, cannot finish twice.")
  checkFinished(future)
  assert(future.error == nil)
  future.finished = true
  if future.cb != nil:
    future.cb()

proc fail*[T](future: Future[T], error: ref Exception) =
  ## Completes ``future`` with ``error``.
  #assert(not future.finished, "Future already finished, cannot finish twice.")
  checkFinished(future)
  future.finished = true
  future.error = error
  future.errorStackTrace =
    if getStackTrace(error) == "": getStackTrace() else: getStackTrace(error)
  if future.cb != nil:
    future.cb()
  else:
    # This is to prevent exceptions from being silently ignored when a future
    # is discarded.
    # TODO: This may turn out to be a bad idea.
    # Turns out this is a bad idea.
    #raise error
    discard

proc `callback=`*(future: FutureBase, cb: proc () {.closure,gcsafe.}) =
  ## Sets the callback proc to be called when the future completes.
  ##
  ## If future has already completed then ``cb`` will be called immediately.
  ##
  ## **Note**: You most likely want the other ``callback`` setter which
  ## passes ``future`` as a param to the callback.
  future.cb = cb
  if future.finished:
    future.cb()

proc `callback=`*[T](future: Future[T],
    cb: proc (future: Future[T]) {.closure,gcsafe.}) =
  ## Sets the callback proc to be called when the future completes.
  ##
  ## If future has already completed then ``cb`` will be called immediately.
  future.callback = proc () = cb(future)

proc echoOriginalStackTrace[T](future: Future[T]) =
  # TODO: Come up with something better.
  when not defined(release):
    echo("Original stack trace in ", future.fromProc, ":")
    if not future.errorStackTrace.isNil and future.errorStackTrace != "":
      echo(future.errorStackTrace)
    else:
      echo("Empty or nil stack trace.")

proc read*[T](future: Future[T]): T =
  ## Retrieves the value of ``future``. Future must be finished otherwise
  ## this function will fail with a ``EInvalidValue`` exception.
  ##
  ## If the result of the future is an error then that error will be raised.
  if future.finished:
    if future.error != nil:
      echoOriginalStackTrace(future)
      raise future.error
    when T isnot void:
      return future.value
  else:
    # TODO: Make a custom exception type for this?
    raise newException(ValueError, "Future still in progress.")

proc readError*[T](future: Future[T]): ref Exception =
  if future.error != nil: return future.error
  else:
    raise newException(ValueError, "No error in future.")

proc finished*[T](future: Future[T]): bool =
  ## Determines whether ``future`` has completed.
  ##
  ## ``True`` may indicate an error or a value. Use ``failed`` to distinguish.
  future.finished

proc failed*(future: FutureBase): bool =
  ## Determines whether ``future`` completed with an error.
  future.error != nil

proc asyncCheck*[T](future: Future[T]) =
  ## Sets a callback on ``future`` which raises an exception if the future
  ## finished with an error.
  ##
  ## This should be used instead of ``discard`` to discard void futures.
  future.callback =
    proc () =
      if future.failed:
        echoOriginalStackTrace(future)
        raise future.error

proc `and`*[T, Y](fut1: Future[T], fut2: Future[Y]): Future[void] =
  ## Returns a future which will complete once both ``fut1`` and ``fut2``
  ## complete.
  var retFuture = newFuture[void]("asyncdispatch.`and`")
  fut1.callback =
    proc () =
      if fut2.finished: retFuture.complete()
  fut2.callback =
    proc () =
      if fut1.finished: retFuture.complete()
  return retFuture

proc `or`*[T, Y](fut1: Future[T], fut2: Future[Y]): Future[void] =
  ## Returns a future which will complete once either ``fut1`` or ``fut2``
  ## complete.
  var retFuture = newFuture[void]("asyncdispatch.`or`")
  proc cb() =
    if not retFuture.finished: retFuture.complete()
  fut1.callback = cb
  fut2.callback = cb
  return retFuture

type
  PDispatcherBase = ref object of RootRef
    timers: seq[tuple[finishAt: float, fut: Future[void]]]

proc processTimers(p: PDispatcherBase) =
  var oldTimers = p.timers
  p.timers = @[]
  for t in oldTimers:
    if epochTime() >= t.finishAt:
      t.fut.complete()
    else:
      p.timers.add(t)

when defined(windows) or defined(nimdoc):
  import winlean, sets, hashes
  type
    TCompletionKey = Dword

    TCompletionData* = object
      sock*: TAsyncFD # TODO: Rename this.
      cb*: proc (sock: TAsyncFD, bytesTransferred: Dword,
                errcode: OSErrorCode) {.closure,gcsafe.}

    PDispatcher* = ref object of PDispatcherBase
      ioPort: THandle
      handles: HashSet[TAsyncFD]

    TCustomOverlapped = object of TOVERLAPPED
      data*: TCompletionData

    PCustomOverlapped* = ref TCustomOverlapped

    TAsyncFD* = distinct int

  proc hash(x: TAsyncFD): THash {.borrow.}
  proc `==`*(x: TAsyncFD, y: TAsyncFD): bool {.borrow.}

  proc newDispatcher*(): PDispatcher =
    ## Creates a new Dispatcher instance.
    new result
    result.ioPort = createIoCompletionPort(INVALID_HANDLE_VALUE, 0, 0, 1)
    result.handles = initSet[TAsyncFD]()
    result.timers = @[]

  var gDisp{.threadvar.}: PDispatcher ## Global dispatcher
  proc getGlobalDispatcher*(): PDispatcher =
    ## Retrieves the global thread-local dispatcher.
    if gDisp.isNil: gDisp = newDispatcher()
    result = gDisp

  proc register*(sock: TAsyncFD) =
    ## Registers ``sock`` with the dispatcher.
    let p = getGlobalDispatcher()
    if createIoCompletionPort(sock.THandle, p.ioPort,
                              cast[TCompletionKey](sock), 1) == 0:
      raiseOSError(osLastError())
    p.handles.incl(sock)

  proc verifyPresence(sock: TAsyncFD) =
    ## Ensures that socket has been registered with the dispatcher.
    let p = getGlobalDispatcher()
    if sock notin p.handles:
      raise newException(ValueError,
        "Operation performed on a socket which has not been registered with" &
        " the dispatcher yet.")

  proc poll*(timeout = 500) =
    ## Waits for completion events and processes them.
    let p = getGlobalDispatcher()
    if p.handles.len == 0 and p.timers.len == 0:
      raise newException(ValueError,
        "No handles or timers registered in dispatcher.")
    
    let llTimeout =
      if timeout ==  -1: winlean.INFINITE
      else: timeout.int32
    var lpNumberOfBytesTransferred: Dword
    var lpCompletionKey: ULONG
    var customOverlapped: PCustomOverlapped
    let res = getQueuedCompletionStatus(p.ioPort,
        addr lpNumberOfBytesTransferred, addr lpCompletionKey,
        cast[ptr POVERLAPPED](addr customOverlapped), llTimeout).bool

    # http://stackoverflow.com/a/12277264/492186
    # TODO: http://www.serverframework.com/handling-multiple-pending-socket-read-and-write-operations.html
    if res:
      # This is useful for ensuring the reliability of the overlapped struct.
      assert customOverlapped.data.sock == lpCompletionKey.TAsyncFD

      customOverlapped.data.cb(customOverlapped.data.sock,
          lpNumberOfBytesTransferred, OSErrorCode(-1))
      GC_unref(customOverlapped)
    else:
      let errCode = osLastError()
      if customOverlapped != nil:
        assert customOverlapped.data.sock == lpCompletionKey.TAsyncFD
        customOverlapped.data.cb(customOverlapped.data.sock,
            lpNumberOfBytesTransferred, errCode)
        GC_unref(customOverlapped)
      else:
        if errCode.int32 == WAIT_TIMEOUT:
          # Timed out
          discard
        else: raiseOSError(errCode)

    # Timer processing.
    processTimers(p)

  var connectExPtr: pointer = nil
  var acceptExPtr: pointer = nil
  var getAcceptExSockAddrsPtr: pointer = nil

  proc initPointer(s: SocketHandle, func: var pointer, guid: var TGUID): bool =
    # Ref: https://github.com/powdahound/twisted/blob/master/twisted/internet/iocpreactor/iocpsupport/winsock_pointers.c
    var bytesRet: Dword
    func = nil
    result = WSAIoctl(s, SIO_GET_EXTENSION_FUNCTION_POINTER, addr guid,
                      sizeof(TGUID).Dword, addr func, sizeof(pointer).Dword,
                      addr bytesRet, nil, nil) == 0

  proc initAll() =
    let dummySock = newRawSocket()
    if not initPointer(dummySock, connectExPtr, WSAID_CONNECTEX):
      raiseOSError(osLastError())
    if not initPointer(dummySock, acceptExPtr, WSAID_ACCEPTEX):
      raiseOSError(osLastError())
    if not initPointer(dummySock, getAcceptExSockAddrsPtr, WSAID_GETACCEPTEXSOCKADDRS):
      raiseOSError(osLastError())

  proc connectEx(s: SocketHandle, name: ptr TSockAddr, namelen: cint, 
                  lpSendBuffer: pointer, dwSendDataLength: Dword,
                  lpdwBytesSent: PDword, lpOverlapped: POVERLAPPED): bool =
    if connectExPtr.isNil: raise newException(ValueError, "Need to initialise ConnectEx().")
    let func =
      cast[proc (s: SocketHandle, name: ptr TSockAddr, namelen: cint, 
         lpSendBuffer: pointer, dwSendDataLength: Dword,
         lpdwBytesSent: PDword, lpOverlapped: POVERLAPPED): bool {.stdcall,gcsafe.}](connectExPtr)

    result = func(s, name, namelen, lpSendBuffer, dwSendDataLength, lpdwBytesSent,
         lpOverlapped)

  proc acceptEx(listenSock, acceptSock: SocketHandle, lpOutputBuffer: pointer,
                 dwReceiveDataLength, dwLocalAddressLength,
                 dwRemoteAddressLength: Dword, lpdwBytesReceived: PDword,
                 lpOverlapped: POVERLAPPED): bool =
    if acceptExPtr.isNil: raise newException(ValueError, "Need to initialise AcceptEx().")
    let func =
      cast[proc (listenSock, acceptSock: SocketHandle, lpOutputBuffer: pointer,
                 dwReceiveDataLength, dwLocalAddressLength,
                 dwRemoteAddressLength: Dword, lpdwBytesReceived: PDword,
                 lpOverlapped: POVERLAPPED): bool {.stdcall,gcsafe.}](acceptExPtr)
    result = func(listenSock, acceptSock, lpOutputBuffer, dwReceiveDataLength,
        dwLocalAddressLength, dwRemoteAddressLength, lpdwBytesReceived,
        lpOverlapped)

  proc getAcceptExSockaddrs(lpOutputBuffer: pointer,
      dwReceiveDataLength, dwLocalAddressLength, dwRemoteAddressLength: Dword,
      LocalSockaddr: ptr ptr TSockAddr, LocalSockaddrLength: LPInt,
      RemoteSockaddr: ptr ptr TSockAddr, RemoteSockaddrLength: LPInt) =
    if getAcceptExSockAddrsPtr.isNil:
      raise newException(ValueError, "Need to initialise getAcceptExSockAddrs().")

    let func =
      cast[proc (lpOutputBuffer: pointer,
                 dwReceiveDataLength, dwLocalAddressLength,
                 dwRemoteAddressLength: Dword, LocalSockaddr: ptr ptr TSockAddr,
                 LocalSockaddrLength: LPInt, RemoteSockaddr: ptr ptr TSockAddr,
                RemoteSockaddrLength: LPInt) {.stdcall,gcsafe.}](getAcceptExSockAddrsPtr)
    
    func(lpOutputBuffer, dwReceiveDataLength, dwLocalAddressLength,
                  dwRemoteAddressLength, LocalSockaddr, LocalSockaddrLength,
                  RemoteSockaddr, RemoteSockaddrLength)

  proc connect*(socket: TAsyncFD, address: string, port: Port,
    af = AF_INET): Future[void] =
    ## Connects ``socket`` to server at ``address:port``.
    ##
    ## Returns a ``Future`` which will complete when the connection succeeds
    ## or an error occurs.
    verifyPresence(socket)
    var retFuture = newFuture[void]("connect")
    # Apparently ``ConnectEx`` expects the socket to be initially bound:
    var saddr: Tsockaddr_in
    saddr.sin_family = int16(toInt(af))
    saddr.sin_port = 0
    saddr.sin_addr.s_addr = INADDR_ANY
    if bindAddr(socket.SocketHandle, cast[ptr TSockAddr](addr(saddr)),
                  sizeof(saddr).TSockLen) < 0'i32:
      raiseOSError(osLastError())

    var aiList = getAddrInfo(address, port, af)
    var success = false
    var lastError: OSErrorCode
    var it = aiList
    while it != nil:
      # "the OVERLAPPED structure must remain valid until the I/O completes"
      # http://blogs.msdn.com/b/oldnewthing/archive/2011/02/02/10123392.aspx
      var ol = PCustomOverlapped()
      GC_ref(ol)
      ol.data = TCompletionData(sock: socket, cb:
        proc (sock: TAsyncFD, bytesCount: Dword, errcode: OSErrorCode) =
          if not retFuture.finished:
            if errcode == OSErrorCode(-1):
              retFuture.complete()
            else:
              retFuture.fail(newException(OSError, osErrorMsg(errcode)))
      )
      
      var ret = connectEx(socket.SocketHandle, it.ai_addr,
                          sizeof(Tsockaddr_in).cint, nil, 0, nil,
                          cast[POVERLAPPED](ol))
      if ret:
        # Request to connect completed immediately.
        success = true
        retFuture.complete()
        # We don't deallocate ``ol`` here because even though this completed
        # immediately poll will still be notified about its completion and it will
        # free ``ol``.
        break
      else:
        lastError = osLastError()
        if lastError.int32 == ERROR_IO_PENDING:
          # In this case ``ol`` will be deallocated in ``poll``.
          success = true
          break
        else:
          GC_unref(ol)
          success = false
      it = it.ai_next

    dealloc(aiList)
    if not success:
      retFuture.fail(newException(OSError, osErrorMsg(lastError)))
    return retFuture

  proc recv*(socket: TAsyncFD, size: int,
             flags = {SocketFlag.SafeDisconn}): Future[string] =
    ## Reads **up to** ``size`` bytes from ``socket``. Returned future will
    ## complete once all the data requested is read, a part of the data has been
    ## read, or the socket has disconnected in which case the future will
    ## complete with a value of ``""``.


    # Things to note:
    #   * When WSARecv completes immediately then ``bytesReceived`` is very
    #     unreliable.
    #   * Still need to implement message-oriented socket disconnection,
    #     '\0' in the message currently signifies a socket disconnect. Who
    #     knows what will happen when someone sends that to our socket.
    verifyPresence(socket)
    var retFuture = newFuture[string]("recv")
    var dataBuf: TWSABuf
    dataBuf.buf = cast[cstring](alloc0(size))
    dataBuf.len = size
    
    var bytesReceived: Dword
    var flagsio = flags.toOSFlags().Dword
    var ol = PCustomOverlapped()
    GC_ref(ol)
    ol.data = TCompletionData(sock: socket, cb:
      proc (sock: TAsyncFD, bytesCount: Dword, errcode: OSErrorCode) =
        if not retFuture.finished:
          if errcode == OSErrorCode(-1):
            if bytesCount == 0 and dataBuf.buf[0] == '\0':
              retFuture.complete("")
            else:
              var data = newString(bytesCount)
              assert bytesCount <= size
              copyMem(addr data[0], addr dataBuf.buf[0], bytesCount)
              retFuture.complete($data)
          else:
            if flags.isDisconnectionError(errcode):
              retFuture.complete("")
            else:
              retFuture.fail(newException(OSError, osErrorMsg(errcode)))
        if dataBuf.buf != nil:
          dealloc dataBuf.buf
          dataBuf.buf = nil
    )

    let ret = WSARecv(socket.SocketHandle, addr dataBuf, 1, addr bytesReceived,
                      addr flagsio, cast[POVERLAPPED](ol), nil)
    if ret == -1:
      let err = osLastError()
      if err.int32 != ERROR_IO_PENDING:
        if dataBuf.buf != nil:
          dealloc dataBuf.buf
          dataBuf.buf = nil
        GC_unref(ol)
        if flags.isDisconnectionError(err):
          retFuture.complete("")
        else:
          retFuture.fail(newException(OSError, osErrorMsg(err)))
    elif ret == 0 and bytesReceived == 0 and dataBuf.buf[0] == '\0':
      # We have to ensure that the buffer is empty because WSARecv will tell
      # us immediatelly when it was disconnected, even when there is still
      # data in the buffer.
      # We want to give the user as much data as we can. So we only return
      # the empty string (which signals a disconnection) when there is
      # nothing left to read.
      retFuture.complete("")
      # TODO: "For message-oriented sockets, where a zero byte message is often 
      # allowable, a failure with an error code of WSAEDISCON is used to 
      # indicate graceful closure." 
      # ~ http://msdn.microsoft.com/en-us/library/ms741688%28v=vs.85%29.aspx
    else:
      # Request to read completed immediately.
      # From my tests bytesReceived isn't reliable.
      let realSize =
        if bytesReceived == 0:
          size
        else:
          bytesReceived
      var data = newString(realSize)
      assert realSize <= size
      copyMem(addr data[0], addr dataBuf.buf[0], realSize)
      #dealloc dataBuf.buf
      retFuture.complete($data)
      # We don't deallocate ``ol`` here because even though this completed
      # immediately poll will still be notified about its completion and it will
      # free ``ol``.
    return retFuture

  proc send*(socket: TAsyncFD, data: string,
             flags = {SocketFlag.SafeDisconn}): Future[void] =
    ## Sends ``data`` to ``socket``. The returned future will complete once all
    ## data has been sent.
    verifyPresence(socket)
    var retFuture = newFuture[void]("send")

    var dataBuf: TWSABuf
    dataBuf.buf = data # since this is not used in a callback, this is fine
    dataBuf.len = data.len

    var bytesReceived, lowFlags: Dword
    var ol = PCustomOverlapped()
    GC_ref(ol)
    ol.data = TCompletionData(sock: socket, cb:
      proc (sock: TAsyncFD, bytesCount: Dword, errcode: OSErrorCode) =
        if not retFuture.finished:
          if errcode == OSErrorCode(-1):
            retFuture.complete()
          else:
            if flags.isDisconnectionError(errcode):
              retFuture.complete()
            else:
              retFuture.fail(newException(OSError, osErrorMsg(errcode)))
    )

    let ret = WSASend(socket.SocketHandle, addr dataBuf, 1, addr bytesReceived,
                      lowFlags, cast[POVERLAPPED](ol), nil)
    if ret == -1:
      let err = osLastError()
      if err.int32 != ERROR_IO_PENDING:
        GC_unref(ol)
        if flags.isDisconnectionError(err):
          retFuture.complete()
        else:
          retFuture.fail(newException(OSError, osErrorMsg(err)))
    else:
      retFuture.complete()
      # We don't deallocate ``ol`` here because even though this completed
      # immediately poll will still be notified about its completion and it will
      # free ``ol``.
    return retFuture

  proc acceptAddr*(socket: TAsyncFD, flags = {SocketFlag.SafeDisconn}):
      Future[tuple[address: string, client: TAsyncFD]] =
    ## Accepts a new connection. Returns a future containing the client socket
    ## corresponding to that connection and the remote address of the client.
    ## The future will complete when the connection is successfully accepted.
    ##
    ## The resulting client socket is automatically registered to the
    ## dispatcher.
    ##
    ## The ``accept`` call may result in an error if the connecting socket
    ## disconnects during the duration of the ``accept``. If the ``SafeDisconn``
    ## flag is specified then this error will not be raised and instead
    ## accept will be called again.
    verifyPresence(socket)
    var retFuture = newFuture[tuple[address: string, client: TAsyncFD]]("acceptAddr")

    var clientSock = newRawSocket()
    if clientSock == osInvalidSocket: raiseOSError(osLastError())

    const lpOutputLen = 1024
    var lpOutputBuf = newString(lpOutputLen)
    var dwBytesReceived: Dword
    let dwReceiveDataLength = 0.Dword # We don't want any data to be read.
    let dwLocalAddressLength = Dword(sizeof (Tsockaddr_in) + 16)
    let dwRemoteAddressLength = Dword(sizeof(Tsockaddr_in) + 16)

    template completeAccept(): stmt {.immediate, dirty.} =
      var listenSock = socket
      let setoptRet = setsockopt(clientSock, SOL_SOCKET,
          SO_UPDATE_ACCEPT_CONTEXT, addr listenSock,
          sizeof(listenSock).TSockLen)
      if setoptRet != 0: raiseOSError(osLastError())

      var localSockaddr, remoteSockaddr: ptr TSockAddr
      var localLen, remoteLen: int32
      getAcceptExSockaddrs(addr lpOutputBuf[0], dwReceiveDataLength,
                           dwLocalAddressLength, dwRemoteAddressLength,
                           addr localSockaddr, addr localLen,
                           addr remoteSockaddr, addr remoteLen)
      register(clientSock.TAsyncFD)
      # TODO: IPv6. Check ``sa_family``. http://stackoverflow.com/a/9212542/492186
      retFuture.complete(
        (address: $inet_ntoa(cast[ptr Tsockaddr_in](remoteSockAddr).sin_addr),
         client: clientSock.TAsyncFD)
      )

    template failAccept(errcode): stmt =
      if flags.isDisconnectionError(errcode):
        var newAcceptFut = acceptAddr(socket, flags)
        newAcceptFut.callback =
          proc () =
            if newAcceptFut.failed:
              retFuture.fail(newAcceptFut.readError)
            else:
              retFuture.complete(newAcceptFut.read)
      else:
        retFuture.fail(newException(OSError, osErrorMsg(errcode)))

    var ol = PCustomOverlapped()
    GC_ref(ol)
    ol.data = TCompletionData(sock: socket, cb:
      proc (sock: TAsyncFD, bytesCount: Dword, errcode: OSErrorCode) =
        if not retFuture.finished:
          if errcode == OSErrorCode(-1):
            completeAccept()
          else:
            failAccept(errcode)
    )

    # http://msdn.microsoft.com/en-us/library/windows/desktop/ms737524%28v=vs.85%29.aspx
    let ret = acceptEx(socket.SocketHandle, clientSock, addr lpOutputBuf[0],
                       dwReceiveDataLength, 
                       dwLocalAddressLength,
                       dwRemoteAddressLength,
                       addr dwBytesReceived, cast[POVERLAPPED](ol))

    if not ret:
      let err = osLastError()
      if err.int32 != ERROR_IO_PENDING:
        failAccept(err)
        GC_unref(ol)
    else:
      completeAccept()
      # We don't deallocate ``ol`` here because even though this completed
      # immediately poll will still be notified about its completion and it will
      # free ``ol``.

    return retFuture

  proc newAsyncRawSocket*(domain: Domain = AF_INET,
               typ: SockType = SOCK_STREAM,
               protocol: Protocol = IPPROTO_TCP): TAsyncFD =
    ## Creates a new socket and registers it with the dispatcher implicitly.
    result = newRawSocket(domain, typ, protocol).TAsyncFD
    result.SocketHandle.setBlocking(false)
    register(result)

  proc closeSocket*(socket: TAsyncFD) =
    ## Closes a socket and ensures that it is unregistered.
    socket.SocketHandle.close()
    getGlobalDispatcher().handles.excl(socket)

  proc unregister*(fd: TAsyncFD) =
    ## Unregisters ``fd``.
    getGlobalDispatcher().handles.excl(fd)

  initAll()
else:
  import selectors
  when defined(windows):
    import winlean
    const
      EINTR = WSAEINPROGRESS
      EINPROGRESS = WSAEINPROGRESS
      EWOULDBLOCK = WSAEWOULDBLOCK
      EAGAIN = EINPROGRESS
      MSG_NOSIGNAL = 0
  else:
    from posix import EINTR, EAGAIN, EINPROGRESS, EWOULDBLOCK, MSG_PEEK,
                      MSG_NOSIGNAL
  
  type
    TAsyncFD* = distinct cint
    TCallback = proc (sock: TAsyncFD): bool {.closure,gcsafe.}

    PData* = ref object of PObject
      sock: TAsyncFD
      readCBs: seq[TCallback]
      writeCBs: seq[TCallback]

    PDispatcher* = ref object of PDispatcherBase
      selector: PSelector

  proc `==`*(x, y: TAsyncFD): bool {.borrow.}

  proc newDispatcher*(): PDispatcher =
    new result
    result.selector = newSelector()
    result.timers = @[]

  var gDisp{.threadvar.}: PDispatcher ## Global dispatcher
  proc getGlobalDispatcher*(): PDispatcher =
    if gDisp.isNil: gDisp = newDispatcher()
    result = gDisp

  proc update(sock: TAsyncFD, events: set[TEvent]) =
    let p = getGlobalDispatcher()
    assert sock.SocketHandle in p.selector
    discard p.selector.update(sock.SocketHandle, events)

  proc register(sock: TAsyncFD) =
    let p = getGlobalDispatcher()
    var data = PData(sock: sock, readCBs: @[], writeCBs: @[])
    p.selector.register(sock.SocketHandle, {}, data.PObject)

  proc newAsyncRawSocket*(domain: TDomain = AF_INET,
               typ: TType = SOCK_STREAM,
               protocol: TProtocol = IPPROTO_TCP): TAsyncFD =
    result = newRawSocket(domain, typ, protocol).TAsyncFD
    result.SocketHandle.setBlocking(false)
    register(result)
  
  proc closeSocket*(sock: TAsyncFD) =
    let disp = getGlobalDispatcher()
    sock.SocketHandle.close()
    disp.selector.unregister(sock.SocketHandle)

  proc unregister*(fd: TAsyncFD) =
    getGlobalDispatcher().selector.unregister(fd.SocketHandle)

  proc addRead(sock: TAsyncFD, cb: TCallback) =
    let p = getGlobalDispatcher()
    if sock.SocketHandle notin p.selector:
      raise newException(EInvalidValue, "File descriptor not registered.")
    p.selector[sock.SocketHandle].data.PData.readCBs.add(cb)
    update(sock, p.selector[sock.SocketHandle].events + {EvRead})
  
  proc addWrite(sock: TAsyncFD, cb: TCallback) =
    let p = getGlobalDispatcher()
    if sock.SocketHandle notin p.selector:
      raise newException(EInvalidValue, "File descriptor not registered.")
    p.selector[sock.SocketHandle].data.PData.writeCBs.add(cb)
    update(sock, p.selector[sock.SocketHandle].events + {EvWrite})
  
  proc poll*(timeout = 500) =
    let p = getGlobalDispatcher()
    for info in p.selector.select(timeout):
      let data = PData(info.key.data)
      assert data.sock == info.key.fd.TAsyncFD
      #echo("In poll ", data.sock.cint)
      if EvRead in info.events:
        # Callback may add items to ``data.readCBs`` which causes issues if
        # we are iterating over ``data.readCBs`` at the same time. We therefore
        # make a copy to iterate over.
        let currentCBs = data.readCBs
        data.readCBs = @[]
        for cb in currentCBs:
          if not cb(data.sock):
            # Callback wants to be called again.
            data.readCBs.add(cb)
      
      if EvWrite in info.events:
        let currentCBs = data.writeCBs
        data.writeCBs = @[]
        for cb in currentCBs:
          if not cb(data.sock):
            # Callback wants to be called again.
            data.writeCBs.add(cb)
      
      if info.key in p.selector:
        var newEvents: set[TEvent]
        if data.readCBs.len != 0: newEvents = {EvRead}
        if data.writeCBs.len != 0: newEvents = newEvents + {EvWrite}
        if newEvents != info.key.events:
          update(data.sock, newEvents)
      else:
        # FD no longer a part of the selector. Likely been closed
        # (e.g. socket disconnected).

    processTimers(p)
  
  proc connect*(socket: TAsyncFD, address: string, port: TPort,
    af = AF_INET): Future[void] =
    var retFuture = newFuture[void]("connect")
    
    proc cb(sock: TAsyncFD): bool =
      # We have connected.
      retFuture.complete()
      return true
    
    var aiList = getAddrInfo(address, port, af)
    var success = false
    var lastError: TOSErrorCode
    var it = aiList
    while it != nil:
      var ret = connect(socket.SocketHandle, it.ai_addr, it.ai_addrlen.Socklen)
      if ret == 0:
        # Request to connect completed immediately.
        success = true
        retFuture.complete()
        break
      else:
        lastError = osLastError()
        if lastError.int32 == EINTR or lastError.int32 == EINPROGRESS:
          success = true
          addWrite(socket, cb)
          break
        else:
          success = false
      it = it.ai_next

    dealloc(aiList)
    if not success:
      retFuture.fail(newException(EOS, osErrorMsg(lastError)))
    return retFuture

  proc recv*(socket: TAsyncFD, size: int,
             flags = {TSocketFlags.SafeDisconn}): Future[string] =
    var retFuture = newFuture[string]("recv")
    
    var readBuffer = newString(size)

    proc cb(sock: TAsyncFD): bool =
      result = true
      let res = recv(sock.SocketHandle, addr readBuffer[0], size.cint,
                     flags.toOSFlags())
      #echo("recv cb res: ", res)
      if res < 0:
        let lastError = osLastError()
        if lastError.int32 notin {EINTR, EWOULDBLOCK, EAGAIN}:
          if flags.isDisconnectionError(lastError):
            retFuture.complete("")
          else:
            retFuture.fail(newException(EOS, osErrorMsg(lastError)))
        else:
          result = false # We still want this callback to be called.
      elif res == 0:
        # Disconnected
        retFuture.complete("")
      else:
        readBuffer.setLen(res)
        retFuture.complete(readBuffer)
    # TODO: The following causes a massive slowdown.
    #if not cb(socket):
    addRead(socket, cb)
    return retFuture

  proc send*(socket: TAsyncFD, data: string,
             flags = {TSocketFlags.SafeDisconn}): Future[void] =
    var retFuture = newFuture[void]("send")
    
    var written = 0
    
    proc cb(sock: TAsyncFD): bool =
      result = true
      let netSize = data.len-written
      var d = data.cstring
      let res = send(sock.SocketHandle, addr d[written], netSize.cint,
                     MSG_NOSIGNAL)
      if res < 0:
        let lastError = osLastError()
        if lastError.int32 notin {EINTR, EWOULDBLOCK, EAGAIN}:
          if flags.isDisconnectionError(lastError):
            retFuture.complete()
          else:
            retFuture.fail(newException(EOS, osErrorMsg(lastError)))
        else:
          result = false # We still want this callback to be called.
      else:
        written.inc(res)
        if res != netSize:
          result = false # We still have data to send.
        else:
          retFuture.complete()
    # TODO: The following causes crashes.
    #if not cb(socket):
    addWrite(socket, cb)
    return retFuture

  proc acceptAddr*(socket: TAsyncFD, flags = {TSocketFlags.SafeDisconn}):
      Future[tuple[address: string, client: TAsyncFD]] =
    var retFuture = newFuture[tuple[address: string,
        client: TAsyncFD]]("acceptAddr")
    proc cb(sock: TAsyncFD): bool =
      result = true
      var sockAddress: SockAddr_in
      var addrLen = sizeof(sockAddress).Socklen
      var client = accept(sock.SocketHandle,
                          cast[ptr SockAddr](addr(sockAddress)), addr(addrLen))
      if client == osInvalidSocket:
        let lastError = osLastError()
        assert lastError.int32 notin {EWOULDBLOCK, EAGAIN}
        if lastError.int32 == EINTR:
          return false
        else:
          if flags.isDisconnectionError(lastError):
            return false
          else:
            retFuture.fail(newException(EOS, osErrorMsg(lastError)))
      else:
        register(client.TAsyncFD)
        retFuture.complete(($inet_ntoa(sockAddress.sin_addr), client.TAsyncFD))
    addRead(socket, cb)
    return retFuture

proc sleepAsync*(ms: int): Future[void] =
  ## Suspends the execution of the current async procedure for the next
  ## ``ms`` miliseconds.
  var retFuture = newFuture[void]("sleepAsync")
  let p = getGlobalDispatcher()
  p.timers.add((epochTime() + (ms / 1000), retFuture))
  return retFuture

proc accept*(socket: TAsyncFD,
    flags = {SocketFlag.SafeDisconn}): Future[TAsyncFD] =
  ## Accepts a new connection. Returns a future containing the client socket
  ## corresponding to that connection.
  ## The future will complete when the connection is successfully accepted.
  var retFut = newFuture[TAsyncFD]("accept")
  var fut = acceptAddr(socket, flags)
  fut.callback =
    proc (future: Future[tuple[address: string, client: TAsyncFD]]) =
      assert future.finished
      if future.failed:
        retFut.fail(future.error)
      else:
        retFut.complete(future.read.client)
  return retFut

# -- Await Macro

template createCb*(retFutureSym, iteratorNameSym,
                   name: expr): stmt {.immediate.} =
  var nameIterVar = iteratorNameSym
  #{.push stackTrace: off.}
  proc cb {.closure,gcsafe.} =
    try:
      if not nameIterVar.finished:
        var next = nameIterVar()
        if next == nil:
          assert retFutureSym.finished, "Async procedure's (" &
                 name & ") return Future was not finished."
        else:
          next.callback = cb
    except:
      if retFutureSym.finished:
        # Take a look at tasyncexceptions for the bug which this fixes.
        # That test explains it better than I can here.
        raise
      else:
        retFutureSym.fail(getCurrentException())
  cb()
  #{.pop.}
proc generateExceptionCheck(futSym,
    exceptBranch, rootReceiver, fromNode: PNimrodNode): PNimrodNode {.compileTime.} =
  if exceptBranch == nil:
    result = rootReceiver
  else:
    if exceptBranch[0].kind == nnkStmtList:
      result = newIfStmt(
        (newDotExpr(futSym, newIdentNode("failed")),
           exceptBranch[0]
         )
      )
    else:
      expectKind(exceptBranch[1], nnkStmtList)
      result = newIfStmt(
        (newDotExpr(futSym, newIdentNode("failed")),
           newIfStmt(
             (infix(newDotExpr(futSym, newIdentNode("error")), "of", exceptBranch[0]),
              exceptBranch[1])
           )
         )
      )
    let elseNode = newNimNode(nnkElse, fromNode)
    elseNode.add newNimNode(nnkStmtList, fromNode)
    elseNode[0].add rootReceiver
    result.add elseNode

template createVar(result: var PNimrodNode, futSymName: string,
                   asyncProc: PNimrodNode,
                   valueReceiver, rootReceiver: expr,
                   fromNode: PNimrodNode) =
  result = newNimNode(nnkStmtList, fromNode)
  var futSym = genSym(nskVar, "future")
  result.add newVarStmt(futSym, asyncProc) # -> var future<x> = y
  result.add newNimNode(nnkYieldStmt, fromNode).add(futSym) # -> yield future<x>
  valueReceiver = newDotExpr(futSym, newIdentNode("read")) # -> future<x>.read
  result.add generateExceptionCheck(futSym, exceptBranch, rootReceiver, fromNode)

proc processBody(node, retFutureSym: PNimrodNode,
                 subTypeIsVoid: bool,
                 exceptBranch: PNimrodNode): PNimrodNode {.compileTime.} =
  #echo(node.treeRepr)
  result = node
  case node.kind
  of nnkReturnStmt:
    result = newNimNode(nnkStmtList, node)
    if node[0].kind == nnkEmpty:
      if not subTypeIsVoid:
        result.add newCall(newIdentNode("complete"), retFutureSym,
            newIdentNode("result"))
      else:
        result.add newCall(newIdentNode("complete"), retFutureSym)
    else:
      result.add newCall(newIdentNode("complete"), retFutureSym,
        node[0].processBody(retFutureSym, subTypeIsVoid, exceptBranch))

    result.add newNimNode(nnkReturnStmt, node).add(newNilLit())
    return # Don't process the children of this return stmt
  of nnkCommand, nnkCall:
    if node[0].kind == nnkIdent and node[0].ident == !"await":
      case node[1].kind
      of nnkIdent, nnkInfix:
        # await x
        result = newNimNode(nnkYieldStmt, node).add(node[1]) # -> yield x
      of nnkCall, nnkCommand:
        # await foo(p, x)
        var futureValue: PNimrodNode
        result.createVar("future" & $node[1][0].toStrLit, node[1], futureValue,
                  futureValue, node)
      else:
        error("Invalid node kind in 'await', got: " & $node[1].kind)
    elif node.len > 1 and node[1].kind == nnkCommand and
         node[1][0].kind == nnkIdent and node[1][0].ident == !"await":
      # foo await x
      var newCommand = node
      result.createVar("future" & $node[0].toStrLit, node[1][1], newCommand[1],
                newCommand, node)

  of nnkVarSection, nnkLetSection:
    case node[0][2].kind
    of nnkCommand:
      if node[0][2][0].kind == nnkIdent and node[0][2][0].ident == !"await":
        # var x = await y
        var newVarSection = node # TODO: Should this use copyNimNode?
        result.createVar("future" & $node[0][0].ident, node[0][2][1],
          newVarSection[0][2], newVarSection, node)
    else: discard
  of nnkAsgn:
    case node[1].kind
    of nnkCommand:
      if node[1][0].ident == !"await":
        # x = await y
        var newAsgn = node
        result.createVar("future" & $node[0].toStrLit, node[1][1], newAsgn[1], newAsgn, node)
    else: discard
  of nnkDiscardStmt:
    # discard await x
    if node[0].kind != nnkEmpty and node[0][0].kind == nnkIdent and
          node[0][0].ident == !"await":
      var newDiscard = node
      result.createVar("futureDiscard_" & $toStrLit(node[0][1]), node[0][1],
                newDiscard[0], newDiscard, node)
  of nnkTryStmt:
    # try: await x; except: ...
    result = newNimNode(nnkStmtList, node)
    proc processForTry(n: PNimrodNode, i: var int,
                       res: PNimrodNode): bool {.compileTime.} =
      result = false
      while i < n[0].len:
        var processed = processBody(n[0][i], retFutureSym, subTypeIsVoid, n[1])
        if processed.kind != n[0][i].kind or processed.len != n[0][i].len:
          expectKind(processed, nnkStmtList)
          expectKind(processed[2][1], nnkElse)
          i.inc
          discard processForTry(n, i, processed[2][1][0])
          res.add processed
          result = true
        else:
          res.add n[0][i]
          i.inc
    var i = 0
    if not processForTry(node, i, result):
      var temp = node
      temp[0] = result
      result = temp
    return
  else: discard

  for i in 0 .. <result.len:
    result[i] = processBody(result[i], retFutureSym, subTypeIsVoid, exceptBranch)

proc getName(node: PNimrodNode): string {.compileTime.} =
  case node.kind
  of nnkPostfix:
    return $node[1].ident
  of nnkIdent:
    return $node.ident
  of nnkEmpty:
    return "anonymous"
  else:
    error("Unknown name.")

macro async*(prc: stmt): stmt {.immediate.} =
  ## Macro which processes async procedures into the appropriate
  ## iterators and yield statements.
  if prc.kind notin {nnkProcDef, nnkLambda}:
    error("Cannot transform this node kind into an async proc." &
          " Proc definition or lambda node expected.")

  hint("Processing " & prc[0].getName & " as an async proc.")

  let returnType = prc[3][0]
  # Verify that the return type is a Future[T]
  if returnType.kind == nnkIdent:
    error("Expected return type of 'Future' got '" & $returnType & "'")
  elif returnType.kind == nnkBracketExpr:
    if $returnType[0] != "Future":
      error("Expected return type of 'Future' got '" & $returnType[0] & "'")

  let subtypeIsVoid = returnType.kind == nnkEmpty or
        (returnType.kind == nnkBracketExpr and
         returnType[1].kind == nnkIdent and returnType[1].ident == !"void")

  var outerProcBody = newNimNode(nnkStmtList, prc[6])

  # -> var retFuture = newFuture[T]()
  var retFutureSym = genSym(nskVar, "retFuture")
  var subRetType =
    if returnType.kind == nnkEmpty: newIdentNode("void")
    else: returnType[1]
  outerProcBody.add(
    newVarStmt(retFutureSym, 
      newCall(
        newNimNode(nnkBracketExpr, prc[6]).add(
          newIdentNode(!"newFuture"), # TODO: Strange bug here? Remove the `!`.
          subRetType),
      newLit(prc[0].getName)))) # Get type from return type of this proc
  
  # -> iterator nameIter(): FutureBase {.closure.} = 
  # ->   var result: T
  # ->   <proc_body>
  # ->   complete(retFuture, result)
  var iteratorNameSym = genSym(nskIterator, $prc[0].getName & "Iter")
  var procBody = prc[6].processBody(retFutureSym, subtypeIsVoid, nil)
  if not subtypeIsVoid:
    procBody.insert(0, newNimNode(nnkVarSection, prc[6]).add(
      newIdentDefs(newIdentNode("result"), returnType[1]))) # -> var result: T
    procBody.add(
      newCall(newIdentNode("complete"),
        retFutureSym, newIdentNode("result"))) # -> complete(retFuture, result)
  else:
    # -> complete(retFuture)
    procBody.add(newCall(newIdentNode("complete"), retFutureSym))
  
  var closureIterator = newProc(iteratorNameSym, [newIdentNode("FutureBase")],
                                procBody, nnkIteratorDef)
  closureIterator[4] = newNimNode(nnkPragma, prc[6]).add(newIdentNode("closure"))
  outerProcBody.add(closureIterator)

  # -> createCb(retFuture)
  var cbName = newIdentNode("cb")
  var procCb = newCall("createCb", retFutureSym, iteratorNameSym,
                       newStrLitNode(prc[0].getName))
  outerProcBody.add procCb

  # -> return retFuture
  outerProcBody.add newNimNode(nnkReturnStmt, prc[6][prc[6].len-1]).add(retFutureSym)
  
  result = prc

  # Remove the 'async' pragma.
  for i in 0 .. <result[4].len:
    if result[4][i].kind == nnkIdent and result[4][i].ident == !"async":
      result[4].del(i)
  if subtypeIsVoid:
    # Add discardable pragma.
    if returnType.kind == nnkEmpty:
      # Add Future[void]
      result[3][0] = parseExpr("Future[void]")

  result[6] = outerProcBody

  #echo(treeRepr(result))
  #if prc[0].getName == "getFile":
  #  echo(toStrLit(result))

proc recvLine*(socket: TAsyncFD): Future[string] {.async.} =
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
      c = await recv(socket, 1, {SocketFlag.SafeDisconn, SocketFlag.Peek})
      if c.len > 0 and c == "\L":
        discard await recv(socket, 1)
      addNLIfEmpty()
      return
    elif c == "\L":
      addNLIfEmpty()
      return
    add(result, c)

proc runForever*() =
  ## Begins a never ending global dispatcher poll loop.
  while true:
    poll()

proc waitFor*[T](fut: PFuture[T]): T =
  ## **Blocks** the current thread until the specified future completes.
  while not fut.finished:
    poll()

  fut.read
