#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2014 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import os, oids, tables, strutils, macros

import sockets2, net

## Asyncio2 
## --------
##
## This module implements a brand new asyncio module based on Futures.
## IOCP is used under the hood on Windows and the selectors module is used for
## other operating systems.

# -- Futures

type
  PFutureBase* = ref object of PObject
    cb: proc () {.closure.}
    finished: bool

  PFuture*[T] = ref object of PFutureBase
    value: T
    error: ref EBase

proc newFuture*[T](): PFuture[T] =
  ## Creates a new future.
  new(result)
  result.finished = false

proc complete*[T](future: PFuture[T], val: T) =
  ## Completes ``future`` with value ``val``.
  assert(not future.finished, "Future already finished, cannot finish twice.")
  assert(future.error == nil)
  future.value = val
  future.finished = true
  if future.cb != nil:
    future.cb()

proc fail*[T](future: PFuture[T], error: ref EBase) =
  ## Completes ``future`` with ``error``.
  assert(not future.finished, "Future already finished, cannot finish twice.")
  future.finished = true
  future.error = error
  if future.cb != nil:
    future.cb()

proc `callback=`*(future: PFutureBase, cb: proc () {.closure.}) =
  ## Sets the callback proc to be called when the future completes.
  ##
  ## If future has already completed then ``cb`` will be called immediately.
  ##
  ## **Note**: You most likely want the other ``callback`` setter which
  ## passes ``future`` as a param to the callback.
  future.cb = cb
  if future.finished:
    future.cb()

proc `callback=`*[T](future: PFuture[T],
    cb: proc (future: PFuture[T]) {.closure.}) =
  ## Sets the callback proc to be called when the future completes.
  ##
  ## If future has already completed then ``cb`` will be called immediately.
  future.callback = proc () = cb(future)

proc read*[T](future: PFuture[T]): T =
  ## Retrieves the value of ``future``. Future must be finished otherwise
  ## this function will fail with a ``EInvalidValue`` exception.
  ##
  ## If the result of the future is an error then that error will be raised.
  if future.finished:
    if future.error != nil: raise future.error
    return future.value
  else:
    # TODO: Make a custom exception type for this?
    raise newException(EInvalidValue, "Future still in progress.")

proc finished*[T](future: PFuture[T]): bool =
  ## Determines whether ``future`` has completed.
  ##
  ## ``True`` may indicate an error or a value. Use ``hasError`` to distinguish.
  future.finished

proc failed*[T](future: PFuture[T]): bool =
  ## Determines whether ``future`` completed with an error.
  future.error != nil

# TODO: Get rid of register. Do it implicitly.

when defined(windows) or defined(nimdoc):
  import winlean, sets, hashes
  #from hashes import THash
  type
    TCompletionKey = dword

    TCompletionData* = object
      sock: TSocketHandle
      cb: proc (sock: TSocketHandle, bytesTransferred: DWORD,
                errcode: TOSErrorCode) {.closure.}

    PDispatcher* = ref object
      ioPort: THandle
      handles: TSet[TSocketHandle]

    TCustomOverlapped = object
      Internal*: DWORD
      InternalHigh*: DWORD
      Offset*: DWORD
      OffsetHigh*: DWORD
      hEvent*: THANDLE
      data*: TCompletionData

    PCustomOverlapped = ptr TCustomOverlapped

  proc hash(x: TSocketHandle): THash {.borrow.}

  proc newDispatcher*(): PDispatcher =
    ## Creates a new Dispatcher instance.
    new result
    result.ioPort = CreateIOCompletionPort(INVALID_HANDLE_VALUE, 0, 0, 1)
    result.handles = initSet[TSocketHandle]()

  proc register*(p: PDispatcher, sock: TSocketHandle) =
    ## Registers ``sock`` with the dispatcher ``p``.
    if CreateIOCompletionPort(sock.THandle, p.ioPort,
                              cast[TCompletionKey](sock), 1) == 0:
      OSError(OSLastError())
    p.handles.incl(sock)
    # TODO: fd closure detection, we need to remove the fd from handles set

  proc verifyPresence(p: PDispatcher, sock: TSocketHandle) =
    ## Ensures that socket has been registered with the dispatcher.
    if sock notin p.handles:
      raise newException(EInvalidValue,
        "Operation performed on a socket which has not been registered with" &
        " the dispatcher yet.")

  proc poll*(p: PDispatcher, timeout = 500) =
    ## Waits for completion events and processes them.
    if p.handles.len == 0:
      raise newException(EInvalidValue, "No handles registered in dispatcher.")
    
    let llTimeout =
      if timeout ==  -1: winlean.INFINITE
      else: timeout.int32
    var lpNumberOfBytesTransferred: DWORD
    var lpCompletionKey: ULONG
    var lpOverlapped: POverlapped
    let res = GetQueuedCompletionStatus(p.ioPort, addr lpNumberOfBytesTransferred,
        addr lpCompletionKey, addr lpOverlapped, llTimeout).bool

    # http://stackoverflow.com/a/12277264/492186
    # TODO: http://www.serverframework.com/handling-multiple-pending-socket-read-and-write-operations.html
    var customOverlapped = cast[PCustomOverlapped](lpOverlapped)
    if res:
      # This is useful for ensuring the reliability of the overlapped struct.
      assert customOverlapped.data.sock == lpCompletionKey.TSocketHandle

      customOverlapped.data.cb(customOverlapped.data.sock,
          lpNumberOfBytesTransferred, TOSErrorCode(-1))
      dealloc(customOverlapped)
    else:
      let errCode = OSLastError()
      if lpOverlapped != nil:
        assert customOverlapped.data.sock == lpCompletionKey.TSocketHandle
        customOverlapped.data.cb(customOverlapped.data.sock,
            lpNumberOfBytesTransferred, errCode)
        dealloc(customOverlapped)
      else:
        if errCode.int32 == WAIT_TIMEOUT:
          # Timed out
          discard
        else: OSError(errCode)

  var connectExPtr: pointer = nil
  var acceptExPtr: pointer = nil
  var getAcceptExSockAddrsPtr: pointer = nil

  proc initPointer(s: TSocketHandle, func: var pointer, guid: var TGUID): bool =
    # Ref: https://github.com/powdahound/twisted/blob/master/twisted/internet/iocpreactor/iocpsupport/winsock_pointers.c
    var bytesRet: DWord
    func = nil
    result = WSAIoctl(s, SIO_GET_EXTENSION_FUNCTION_POINTER, addr guid,
                      sizeof(TGUID).dword, addr func, sizeof(pointer).DWORD,
                      addr bytesRet, nil, nil) == 0

  proc initAll() =
    let dummySock = socket()
    if not initPointer(dummySock, connectExPtr, WSAID_CONNECTEX):
      OSError(OSLastError())
    if not initPointer(dummySock, acceptExPtr, WSAID_ACCEPTEX):
      OSError(OSLastError())
    if not initPointer(dummySock, getAcceptExSockAddrsPtr, WSAID_GETACCEPTEXSOCKADDRS):
      OSError(OSLastError())

  proc connectEx(s: TSocketHandle, name: ptr TSockAddr, namelen: cint, 
                  lpSendBuffer: pointer, dwSendDataLength: dword,
                  lpdwBytesSent: PDWORD, lpOverlapped: POverlapped): bool =
    if connectExPtr.isNil: raise newException(EInvalidValue, "Need to initialise ConnectEx().")
    let func =
      cast[proc (s: TSocketHandle, name: ptr TSockAddr, namelen: cint, 
         lpSendBuffer: pointer, dwSendDataLength: dword,
         lpdwBytesSent: PDWORD, lpOverlapped: POverlapped): bool {.stdcall.}](connectExPtr)

    result = func(s, name, namelen, lpSendBuffer, dwSendDataLength, lpdwBytesSent,
         lpOverlapped)

  proc acceptEx(listenSock, acceptSock: TSocketHandle, lpOutputBuffer: pointer,
                 dwReceiveDataLength, dwLocalAddressLength,
                 dwRemoteAddressLength: DWORD, lpdwBytesReceived: PDWORD,
                 lpOverlapped: POverlapped): bool =
    if acceptExPtr.isNil: raise newException(EInvalidValue, "Need to initialise AcceptEx().")
    let func =
      cast[proc (listenSock, acceptSock: TSocketHandle, lpOutputBuffer: pointer,
                 dwReceiveDataLength, dwLocalAddressLength,
                 dwRemoteAddressLength: DWORD, lpdwBytesReceived: PDWORD,
                 lpOverlapped: POverlapped): bool {.stdcall.}](acceptExPtr)
    result = func(listenSock, acceptSock, lpOutputBuffer, dwReceiveDataLength,
        dwLocalAddressLength, dwRemoteAddressLength, lpdwBytesReceived,
        lpOverlapped)

  proc getAcceptExSockaddrs(lpOutputBuffer: pointer,
      dwReceiveDataLength, dwLocalAddressLength, dwRemoteAddressLength: DWORD,
      LocalSockaddr: ptr ptr TSockAddr, LocalSockaddrLength: lpint,
      RemoteSockaddr: ptr ptr TSockAddr, RemoteSockaddrLength: lpint) =
    if getAcceptExSockAddrsPtr.isNil:
      raise newException(EInvalidValue, "Need to initialise getAcceptExSockAddrs().")

    let func =
      cast[proc (lpOutputBuffer: pointer,
                 dwReceiveDataLength, dwLocalAddressLength,
                 dwRemoteAddressLength: DWORD, LocalSockaddr: ptr ptr TSockAddr,
                 LocalSockaddrLength: lpint, RemoteSockaddr: ptr ptr TSockAddr,
                RemoteSockaddrLength: lpint) {.stdcall.}](getAcceptExSockAddrsPtr)
    
    func(lpOutputBuffer, dwReceiveDataLength, dwLocalAddressLength,
                  dwRemoteAddressLength, LocalSockaddr, LocalSockaddrLength,
                  RemoteSockaddr, RemoteSockaddrLength)

  proc connect*(p: PDispatcher, socket: TSocketHandle, address: string, port: TPort,
    af = AF_INET): PFuture[int] =
    ## Connects ``socket`` to server at ``address:port``.
    ##
    ## Returns a ``PFuture`` which will complete when the connection succeeds
    ## or an error occurs.
    verifyPresence(p, socket)
    var retFuture = newFuture[int]()# TODO: Change to void when that regression is fixed.
    # Apparently ``ConnectEx`` expects the socket to be initially bound:
    var saddr: Tsockaddr_in
    saddr.sin_family = int16(toInt(af))
    saddr.sin_port = 0
    saddr.sin_addr.s_addr = INADDR_ANY
    if bindAddr(socket, cast[ptr TSockAddr](addr(saddr)),
                  sizeof(saddr).TSockLen) < 0'i32:
      OSError(OSLastError())

    var aiList = getAddrInfo(address, port, af)
    var success = false
    var lastError: TOSErrorCode
    var it = aiList
    while it != nil:
      # "the OVERLAPPED structure must remain valid until the I/O completes"
      # http://blogs.msdn.com/b/oldnewthing/archive/2011/02/02/10123392.aspx
      var ol = cast[PCustomOverlapped](alloc0(sizeof(TCustomOverlapped)))
      ol.data = TCompletionData(sock: socket, cb:
        proc (sock: TSocketHandle, bytesCount: DWord, errcode: TOSErrorCode) =
          if not retFuture.finished:
            if errcode == TOSErrorCode(-1):
              retFuture.complete(0)
            else:
              retFuture.fail(newException(EOS, osErrorMsg(errcode)))
      )
      
      var ret = connectEx(socket, it.ai_addr, sizeof(TSockAddrIn).cint,
                          nil, 0, nil, cast[POverlapped](ol))
      if ret:
        # Request to connect completed immediately.
        success = true
        retFuture.complete(0)
        # We don't deallocate ``ol`` here because even though this completed
        # immediately poll will still be notified about its completion and it will
        # free ``ol``.
        break
      else:
        lastError = OSLastError()
        if lastError.int32 == ERROR_IO_PENDING:
          # In this case ``ol`` will be deallocated in ``poll``.
          success = true
          break
        else:
          dealloc(ol)
          success = false
      it = it.ai_next

    dealloc(aiList)
    if not success:
      retFuture.fail(newException(EOS, osErrorMsg(lastError)))
    return retFuture

  proc recv*(p: PDispatcher, socket: TSocketHandle, size: int,
             flags: int = 0): PFuture[string] =
    ## Reads ``size`` bytes from ``socket``. Returned future will complete once
    ## all of the requested data is read. If socket is disconnected during the
    ## recv operation then the future may complete with only a part of the
    ## requested data read. If socket is disconnected and no data is available
    ## to be read then the future will complete with a value of ``""``.
    verifyPresence(p, socket)
    var retFuture = newFuture[string]()
    
    var dataBuf: TWSABuf
    dataBuf.buf = newString(size)
    dataBuf.len = size
    
    var bytesReceived: DWord
    var flagsio = flags.dword
    var ol = cast[PCustomOverlapped](alloc0(sizeof(TCustomOverlapped)))
    ol.data = TCompletionData(sock: socket, cb:
      proc (sock: TSocketHandle, bytesCount: DWord, errcode: TOSErrorCode) =
        if not retFuture.finished:
          if errcode == TOSErrorCode(-1):
            if bytesCount == 0 and dataBuf.buf[0] == '\0':
              retFuture.complete("")
            else:
              var data = newString(size)
              copyMem(addr data[0], addr dataBuf.buf[0], size)
              retFuture.complete($data)
          else:
            retFuture.fail(newException(EOS, osErrorMsg(errcode)))
    )

    let ret = WSARecv(socket, addr dataBuf, 1, addr bytesReceived,
                      addr flagsio, cast[POverlapped](ol), nil)
    if ret == -1:
      let err = OSLastError()
      if err.int32 != ERROR_IO_PENDING:
        retFuture.fail(newException(EOS, osErrorMsg(err)))
        dealloc(ol)
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
      var data = newString(size)
      copyMem(addr data[0], addr dataBuf.buf[0], size)
      retFuture.complete($data)
      # We don't deallocate ``ol`` here because even though this completed
      # immediately poll will still be notified about its completion and it will
      # free ``ol``.
    return retFuture

  proc send*(p: PDispatcher, socket: TSocketHandle, data: string): PFuture[int] =
    ## Sends ``data`` to ``socket``. The returned future will complete once all
    ## data has been sent.
    verifyPresence(p, socket)
    var retFuture = newFuture[int]()

    var dataBuf: TWSABuf
    dataBuf.buf = data
    dataBuf.len = data.len

    var bytesReceived, flags: DWord
    var ol = cast[PCustomOverlapped](alloc0(sizeof(TCustomOverlapped)))
    ol.data = TCompletionData(sock: socket, cb:
      proc (sock: TSocketHandle, bytesCount: DWord, errcode: TOSErrorCode) =
        if not retFuture.finished:
          if errcode == TOSErrorCode(-1):
            retFuture.complete(0)
          else:
            retFuture.fail(newException(EOS, osErrorMsg(errcode)))
    )

    let ret = WSASend(socket, addr dataBuf, 1, addr bytesReceived,
                      flags, cast[POverlapped](ol), nil)
    if ret == -1:
      let err = osLastError()
      if err.int32 != ERROR_IO_PENDING:
        retFuture.fail(newException(EOS, osErrorMsg(err)))
        dealloc(ol)
    else:
      retFuture.complete(0)
      # We don't deallocate ``ol`` here because even though this completed
      # immediately poll will still be notified about its completion and it will
      # free ``ol``.
    return retFuture

  proc acceptAddr*(p: PDispatcher, socket: TSocketHandle): 
      PFuture[tuple[address: string, client: TSocketHandle]] =
    ## Accepts a new connection. Returns a future containing the client socket
    ## corresponding to that connection and the remote address of the client.
    ## The future will complete when the connection is successfully accepted.
    ##
    ## The resulting client socket is automatically registered to dispatcher.
    verifyPresence(p, socket)
    var retFuture = newFuture[tuple[address: string, client: TSocketHandle]]()

    var clientSock = socket()
    if clientSock == OSInvalidSocket: osError(osLastError())

    const lpOutputLen = 1024
    var lpOutputBuf = newString(lpOutputLen)
    var dwBytesReceived: DWORD
    let dwReceiveDataLength = 0.DWORD # We don't want any data to be read.
    let dwLocalAddressLength = DWORD(sizeof (TSockaddr_in) + 16)
    let dwRemoteAddressLength = DWORD(sizeof(TSockaddr_in) + 16)

    template completeAccept(): stmt {.immediate, dirty.} =
      var listenSock = socket
      let setoptRet = setsockopt(clientSock, SOL_SOCKET,
          SO_UPDATE_ACCEPT_CONTEXT, addr listenSock,
          sizeof(listenSock).TSockLen)
      if setoptRet != 0: osError(osLastError())

      var LocalSockaddr, RemoteSockaddr: ptr TSockAddr
      var localLen, remoteLen: int32
      getAcceptExSockaddrs(addr lpOutputBuf[0], dwReceiveDataLength,
                           dwLocalAddressLength, dwRemoteAddressLength,
                           addr LocalSockaddr, addr localLen,
                           addr RemoteSockaddr, addr remoteLen)
      p.register(clientSock)
      # TODO: IPv6. Check ``sa_family``. http://stackoverflow.com/a/9212542/492186
      retFuture.complete(
        (address: $inet_ntoa(cast[ptr Tsockaddr_in](remoteSockAddr).sin_addr),
         client: clientSock)
      )

    var ol = cast[PCustomOverlapped](alloc0(sizeof(TCustomOverlapped)))
    ol.data = TCompletionData(sock: socket, cb:
      proc (sock: TSocketHandle, bytesCount: DWord, errcode: TOSErrorCode) =
        if not retFuture.finished:
          if errcode == TOSErrorCode(-1):
            completeAccept()
          else:
            retFuture.fail(newException(EOS, osErrorMsg(errcode)))
    )

    # http://msdn.microsoft.com/en-us/library/windows/desktop/ms737524%28v=vs.85%29.aspx
    let ret = acceptEx(socket, clientSock, addr lpOutputBuf[0],
                       dwReceiveDataLength, 
                       dwLocalAddressLength,
                       dwRemoteAddressLength,
                       addr dwBytesReceived, cast[POverlapped](ol))

    if not ret:
      let err = osLastError()
      if err.int32 != ERROR_IO_PENDING:
        retFuture.fail(newException(EOS, osErrorMsg(err)))
        dealloc(ol)
    else:
      completeAccept()
      # We don't deallocate ``ol`` here because even though this completed
      # immediately poll will still be notified about its completion and it will
      # free ``ol``.

    return retFuture

  proc socket*(disp: PDispatcher, domain: TDomain = AF_INET,
               typ: TType = SOCK_STREAM,
               protocol: TProtocol = IPPROTO_TCP): TSocketHandle =
    ## Creates a new socket and registers it with the dispatcher implicitly.
    result = socket(domain, typ, protocol)
    disp.register(result)

  initAll()
else:
  import selectors
  from posix import EINTR, EAGAIN, EINPROGRESS, EWOULDBLOCK, MSG_PEEK
  type
    TCallback = proc (sock: TSocketHandle): bool {.closure.}

    PData* = ref object of PObject
      sock: TSocketHandle
      readCBs: seq[TCallback]
      writeCBs: seq[TCallback]

    PDispatcher* = ref object
      selector: PSelector

  proc newDispatcher*(): PDispatcher =
    new result
    result.selector = newSelector()

  proc update(p: PDispatcher, sock: TSocketHandle, events: set[TEvent]) =
    assert sock in p.selector
    discard p.selector.update(sock, events)

  proc register(p: PDispatcher, sock: TSocketHandle) =
    var data = PData(sock: sock, readCBs: @[], writeCBs: @[])
    p.selector.register(sock, {}, data.PObject)

  proc socket*(disp: PDispatcher, domain: TDomain = AF_INET,
               typ: TType = SOCK_STREAM,
               protocol: TProtocol = IPPROTO_TCP): TSocketHandle =
    result = socket(domain, typ, protocol)
    disp.register(result)
  
  proc addRead(p: PDispatcher, sock: TSocketHandle, cb: TCallback) =
    if sock notin p.selector:
      raise newException(EInvalidValue, "File descriptor not registered.")
    p.selector[sock].data.PData.readCBs.add(cb)
    p.update(sock, p.selector[sock].events + {EvRead})
  
  proc addWrite(p: PDispatcher, sock: TSocketHandle, cb: TCallback) =
    if sock notin p.selector:
      raise newException(EInvalidValue, "File descriptor not registered.")
    p.selector[sock].data.PData.writeCBs.add(cb)
    p.update(sock, p.selector[sock].events + {EvWrite})
  
  proc poll*(p: PDispatcher, timeout = 500) =
    for info in p.selector.select(timeout):
      let data = PData(info.key.data)
      assert data.sock == info.key.fd
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
          echo(info.key.events, " -> ", newEvents)
          p.update(data.sock, newEvents)
      else:
        # FD no longer a part of the selector. Likely been closed
        # (e.g. socket disconnected).
  
  proc connect*(p: PDispatcher, socket: TSocketHandle, address: string, port: TPort,
    af = AF_INET): PFuture[int] =
    var retFuture = newFuture[int]()
    
    proc cb(sock: TSocketHandle): bool =
      # We have connected.
      retFuture.complete(0)
      return true
    
    var aiList = getAddrInfo(address, port, af)
    var success = false
    var lastError: TOSErrorCode
    var it = aiList
    while it != nil:
      var ret = connect(socket, it.ai_addr, it.ai_addrlen.TSocklen)
      if ret == 0:
        # Request to connect completed immediately.
        success = true
        retFuture.complete(0)
        break
      else:
        lastError = osLastError()
        if lastError.int32 == EINTR or lastError.int32 == EINPROGRESS:
          success = true
          addWrite(p, socket, cb)
          break
        else:
          success = false
      it = it.ai_next

    dealloc(aiList)
    if not success:
      retFuture.fail(newException(EOS, osErrorMsg(lastError)))
    return retFuture

  proc recv*(p: PDispatcher, socket: TSocketHandle, size: int,
             flags: int = 0): PFuture[string] =
    var retFuture = newFuture[string]()
    
    var readBuffer = newString(size)
    var sizeRead = 0
    
    proc cb(sock: TSocketHandle): bool =
      result = true
      let netSize = size - sizeRead
      let res = recv(sock, addr readBuffer[sizeRead], netSize, flags.cint)
      #echo("recv cb res: ", res)
      if res < 0:
        let lastError = osLastError()
        if lastError.int32 notin {EINTR, EWOULDBLOCK, EAGAIN}: 
          retFuture.fail(newException(EOS, osErrorMsg(lastError)))
        else:
          result = false # We still want this callback to be called.
      elif res == 0:
        #echo("Disconnected recv: ", sizeRead)
        # Disconnected
        if sizeRead == 0:
          retFuture.complete("")
        else:
          readBuffer.setLen(sizeRead)
          retFuture.complete(readBuffer)
      else:
        sizeRead.inc(res)
        if res != netSize:
          result = false # We want to read all the data requested.
        else:
          retFuture.complete(readBuffer)
      #echo("Recv cb result: ", result)
  
    addRead(p, socket, cb)
    return retFuture

  proc send*(p: PDispatcher, socket: TSocketHandle, data: string): PFuture[int] =
    var retFuture = newFuture[int]()
    
    var written = 0
    
    proc cb(sock: TSocketHandle): bool =
      result = true
      let netSize = data.len-written
      var d = data.cstring
      let res = send(sock, addr d[written], netSize, 0.cint)
      if res < 0:
        let lastError = osLastError()
        if lastError.int32 notin {EINTR, EWOULDBLOCK, EAGAIN}:
          retFuture.fail(newException(EOS, osErrorMsg(lastError)))
        else:
          result = false # We still want this callback to be called.
      else:
        written.inc(res)
        if res != netSize:
          result = false # We still have data to send.
        else:
          retFuture.complete(0)
    addWrite(p, socket, cb)
    return retFuture

  proc acceptAddr*(p: PDispatcher, socket: TSocketHandle): 
      PFuture[tuple[address: string, client: TSocketHandle]] =
    var retFuture = newFuture[tuple[address: string, client: TSocketHandle]]()
    proc cb(sock: TSocketHandle): bool =
      result = true
      var sockAddress: Tsockaddr_in
      var addrLen = sizeof(sockAddress).TSocklen
      var client = accept(sock, cast[ptr TSockAddr](addr(sockAddress)),
                          addr(addrLen))
      if client == osInvalidSocket:
        let lastError = osLastError()
        assert lastError.int32 notin {EWOULDBLOCK, EAGAIN}
        if lastError.int32 == EINTR:
          return false
        else:
          retFuture.fail(newException(EOS, osErrorMsg(lastError)))
      else:
        p.register(client)
        retFuture.complete(($inet_ntoa(sockAddress.sin_addr), client))
    addRead(p, socket, cb)
    return retFuture

proc accept*(p: PDispatcher, socket: TSocketHandle): PFuture[TSocketHandle] =
  ## Accepts a new connection. Returns a future containing the client socket
  ## corresponding to that connection.
  ## The future will complete when the connection is successfully accepted.
  var retFut = newFuture[TSocketHandle]()
  var fut = p.acceptAddr(socket)
  fut.callback =
    proc (future: PFuture[tuple[address: string, client: TSocketHandle]]) =
      assert future.finished
      if future.failed:
        retFut.fail(future.error)
      else:
        retFut.complete(future.read.client)
  return retFut

# -- Await Macro

template createCb*(cbName, varNameIterSym, retFutureSym: expr): stmt {.immediate, dirty.} =
  proc cbName {.closure.} =
    if not varNameIterSym.finished:
      var next = varNameIterSym()
      if next == nil:
        assert retFutureSym.finished, "Async procedure's return Future was not finished."
      else:
        next.callback = cbName

template createVar(futSymName: string, asyncProc: PNimrodNode,
                   valueReceiver: expr) {.immediate, dirty.} =
  # TODO: Used template here due to bug #926
  result = newNimNode(nnkStmtList)
  var futSym = newIdentNode(futSymName) #genSym(nskVar, "future")
  result.add newVarStmt(futSym, asyncProc) # -> var future<x> = y
  result.add newNimNode(nnkYieldStmt).add(futSym) # -> yield future<x>
  valueReceiver = newDotExpr(futSym, newIdentNode("read")) # -> future<x>.read

proc processBody(node, retFutureSym: PNimrodNode): PNimrodNode {.compileTime.} =
  result = node
  case node.kind
  of nnkReturnStmt:
    result = newNimNode(nnkStmtList)
    result.add newCall(newIdentNode("complete"), retFutureSym,
      if node[0].kind == nnkEmpty: newIdentNode("result") else: node[0])
    result.add newNimNode(nnkYieldStmt).add(newNilLit())
  of nnkCommand:
    if node[0].ident == !"await":
      case node[1].kind
      of nnkIdent:
        # await x
        result = newNimNode(nnkYieldStmt).add(node[1]) # -> yield x
      of nnkCall:
        # await foo(p, x)
        var futureValue: PNimrodNode
        createVar("future" & $node[1][0].toStrLit, node[1], futureValue)
        result.add futureValue
      else:
        error("Invalid node kind in 'await', got: " & $node[1].kind)
    elif node[1].kind == nnkCommand and node[1][0].kind == nnkIdent and
         node[1][0].ident == !"await":
      # foo await x
      var newCommand = node
      createVar("future" & $node[0].ident, node[1][0], newCommand[1])
      result.add newCommand

  of nnkVarSection, nnkLetSection:
    case node[0][2].kind
    of nnkCommand:
      if node[0][2][0].ident == !"await":
        # var x = await y
        var newVarSection = node # TODO: Should this use copyNimNode?
        createVar("future" & $node[0][0].ident, node[0][2][1],
          newVarSection[0][2])
        result.add newVarSection
    else: discard
  of nnkAsgn:
    case node[1].kind
    of nnkCommand:
      if node[1][0].ident == !"await":
        # x = await y
        var newAsgn = node
        createVar("future" & $node[0].ident, node[1][1], newAsgn[1])
        result.add newAsgn
    else: discard
  of nnkDiscardStmt:
    # discard await x
    if node[0][0].ident == !"await":
      var dummy = newNimNode(nnkStmtList)
      createVar("futureDiscard_" & $toStrLit(node[0][1]), node[0][1], dummy)
  else: discard
  
  for i in 0 .. <result.len:
    result[i] = processBody(result[i], retFutureSym)
  #echo(treeRepr(result))

proc getName(node: PNimrodNode): string {.compileTime.} =
  case node.kind
  of nnkPostfix:
    return $node[1].ident
  of nnkIdent:
    return $node.ident
  else:
    assert false

macro async*(prc: stmt): stmt {.immediate.} =
  expectKind(prc, nnkProcDef)

  hint("Processing " & prc[0].getName & " as an async proc.")

  # Verify that the return type is a PFuture[T]
  if prc[3][0].kind == nnkIdent:
    error("Expected return type of 'PFuture' got '" & $prc[3][0] & "'")
  elif prc[3][0].kind == nnkBracketExpr:
    if $prc[3][0][0] != "PFuture":
      error("Expected return type of 'PFuture' got '" & $prc[3][0][0] & "'")
  
  # TODO: Why can't I use genSym? I get illegal capture errors for Syms.
  # TODO: It seems genSym is broken. Change all usages back to genSym when fixed

  var outerProcBody = newNimNode(nnkStmtList)

  # -> var retFuture = newFuture[T]()
  var retFutureSym = newIdentNode("retFuture") #genSym(nskVar, "retFuture")
  outerProcBody.add(
    newVarStmt(retFutureSym, 
      newCall(
        newNimNode(nnkBracketExpr).add(
          newIdentNode("newFuture"),
          prc[3][0][1])))) # Get type from return type of this proc.

  # -> iterator nameIter(): PFutureBase {.closure.} = 
  # ->   var result: T
  # ->   <proc_body>
  # ->   complete(retFuture, result)
  var iteratorNameSym = newIdentNode($prc[0].getName & "Iter") #genSym(nskIterator, $prc[0].ident & "Iter")
  var procBody = prc[6].processBody(retFutureSym)
  procBody.insert(0, newNimNode(nnkVarSection).add(
    newIdentDefs(newIdentNode("result"), prc[3][0][1]))) # -> var result: T
  procBody.add(
    newCall(newIdentNode("complete"),
      retFutureSym, newIdentNode("result"))) # -> complete(retFuture, result)
  
  var closureIterator = newProc(iteratorNameSym, [newIdentNode("PFutureBase")],
                                procBody, nnkIteratorDef)
  closureIterator[4] = newNimNode(nnkPragma).add(newIdentNode("closure"))
  outerProcBody.add(closureIterator)

  # -> var nameIterVar = nameIter
  # -> var first = nameIterVar()
  var varNameIterSym = newIdentNode($prc[0].getName & "IterVar") #genSym(nskVar, $prc[0].ident & "IterVar")
  var varNameIter = newVarStmt(varNameIterSym, iteratorNameSym)
  outerProcBody.add varNameIter
  var varFirstSym = genSym(nskVar, "first")
  var varFirst = newVarStmt(varFirstSym, newCall(varNameIterSym))
  outerProcBody.add varFirst

  # -> createCb(cb, nameIter, retFuture)
  var cbName = newIdentNode("cb")
  var procCb = newCall("createCb", cbName, varNameIterSym, retFutureSym)
  outerProcBody.add procCb

  # -> first.callback = cb
  outerProcBody.add newAssignment(
    newDotExpr(varFirstSym, newIdentNode("callback")),
    cbName)

  # -> return retFuture
  outerProcBody.add newNimNode(nnkReturnStmt).add(retFutureSym)
  
  result = prc

  # Remove the 'async' pragma.
  for i in 0 .. <result[4].len:
    if result[4][i].ident == !"async":
      result[4].del(i)

  result[6] = outerProcBody

  echo(toStrLit(result))

proc recvLine*(p: PDispatcher, socket: TSocketHandle): PFuture[string] {.async.} =
  ## Reads a line of data from ``socket``. Returned future will complete once
  ## a full line is read or an error occurs.
  ##
  ## If a full line is read ``\r\L`` is not
  ## added to ``line``, however if solely ``\r\L`` is read then ``line``
  ## will be set to it.
  ## 
  ## If the socket is disconnected, ``line`` will be set to ``""``.
  
  template addNLIfEmpty(): stmt =
    if result.len == 0:
      result.add("\c\L")

  result = ""
  var c = ""
  while true:
    #echo("1")
    c = await p.recv(socket, 1)
    #echo("Received ", c.len)
    if c.len == 0:
      #echo("returning")
      return
    #echo("2")
    if c == "\r":
      c = await p.recv(socket, 1, MSG_PEEK)
      if c.len > 0 and c == "\L":
        discard await p.recv(socket, 1)
      addNLIfEmpty()
      return
    elif c == "\L":
      addNLIfEmpty()
      return
    #echo("3")
    add(result.string, c)
  #echo("4")

when isMainModule:
  
  var p = newDispatcher()
  var sock = socket()
  sock.setBlocking false


  when false:
    # Await tests
    proc main(p: PDispatcher): PFuture[int] {.async.} =
      discard await p.connect(sock, "irc.freenode.net", TPort(6667))
      while true:
        echo("recvLine")
        var line = await p.recvLine(sock)
        echo("Line is: ", line.repr)
        if line == "":
          echo "Disconnected"
          break

    proc peekTest(p: PDispatcher): PFuture[int] {.async.} =
      discard await p.connect(sock, "localhost", TPort(6667))
      while true:
        var line = await p.recv(sock, 1, MSG_PEEK)
        var line2 = await p.recv(sock, 1)
        echo(line.repr)
        echo(line2.repr)
        echo("---")
        if line2 == "": break
        sleep(500)

    var f = main(p)
    

  else:
    when false:

      var f = p.connect(sock, "irc.poop.nl", TPort(6667))
      f.callback =
        proc (future: PFuture[int]) =
          echo("Connected in future!")
          echo(future.read)
          for i in 0 .. 50:
            var recvF = p.recv(sock, 10)
            recvF.callback =
              proc (future: PFuture[string]) =
                echo("Read ", future.read.len, ": ", future.read.repr)

    else:

      sock.bindAddr(TPort(6667))
      sock.listen()
      proc onAccept(future: PFuture[TSocketHandle]) =
        let client = future.read
        echo "Accepted ", client.cint
        var t = p.send(client, "test\c\L")
        t.callback =
          proc (future: PFuture[int]) =
            echo("Send: ", future.read)
            client.close()
        
        var f = p.accept(sock)
        f.callback = onAccept
        
      var f = p.accept(sock)
      f.callback = onAccept
  
  while true:
    p.poll()





  

  
