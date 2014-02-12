#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2014 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import os, oids, tables, strutils

import winlean

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
  assert(not future.finished)
  assert(future.error == nil)
  future.value = val
  future.finished = true
  if future.cb != nil:
    future.cb()

proc fail*[T](future: PFuture[T], error: ref EBase) =
  ## Completes ``future`` with ``error``.
  assert(not future.finished)
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

when defined(windows):
  type
    TCompletionKey = dword

    TCompletionData* = object
      sock: TSocketHandle
      cb: proc (sock: TSocketHandle, errcode: TOSErrorCode) {.closure.}

    PDispatcher* = ref object
      ioPort: THandle

    TCustomOverlapped = object
      Internal*: DWORD
      InternalHigh*: DWORD
      Offset*: DWORD
      OffsetHigh*: DWORD
      hEvent*: THANDLE
      data*: TCompletionData

    PCustomOverlapped = ptr TCustomOverlapped

  proc newDispatcher*(): PDispatcher =
    ## Creates a new Dispatcher instance.
    new result
    result.ioPort = CreateIOCompletionPort(INVALID_HANDLE_VALUE, 0, 0, 1)

  proc register*(p: PDispatcher, sock: TSocketHandle) =
    ## Registers ``sock`` with the dispatcher ``p``.
    if CreateIOCompletionPort(sock.THandle, p.ioPort,
                              cast[TCompletionKey](sock), 1) == 0:
      OSError(OSLastError())

  proc poll*(p: PDispatcher, timeout = 500) =
    ## Waits for completion events and processes them.
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
      assert customOverlapped.data.sock == lpCompletionKey.TSocketHandle

      customOverlapped.data.cb(customOverlapped.data.sock, TOSErrorCode(-1))
      dealloc(customOverlapped)
    else:
      let errCode = OSLastError()
      if lpOverlapped != nil:
        assert customOverlapped.data.sock == lpCompletionKey.TSocketHandle
        dealloc(customOverlapped)
        customOverlapped.data.cb(customOverlapped.data.sock, errCode)
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
        proc (sock: TSocketHandle, errcode: TOSErrorCode) =
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
        dealloc(ol)
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

  proc recv*(p: PDispatcher, socket: TSocketHandle, size: int): PFuture[string] =
    ## Reads ``size`` bytes from ``socket``. Returned future will complete once
    ## all of the requested data is read.

    var retFuture = newFuture[string]()
    
    var dataBuf: TWSABuf
    dataBuf.buf = newString(size)
    dataBuf.len = size
    
    var bytesReceived, flags: DWord
    var ol = cast[PCustomOverlapped](alloc0(sizeof(TCustomOverlapped)))
    ol.data = TCompletionData(sock: socket, cb:
      proc (sock: TSocketHandle, errcode: TOSErrorCode) =
        if errcode == TOSErrorCode(-1):
          var data = newString(size)
          copyMem(addr data[0], addr dataBuf.buf[0], size)
          retFuture.complete($data)
        else:
          retFuture.fail(newException(EOS, osErrorMsg(errcode)))
    )
    
    let ret = WSARecv(socket, addr dataBuf, 1, addr bytesReceived,
                      addr flags, cast[POverlapped](ol), nil)
    if ret == -1:
      let err = OSLastError()
      if err.int32 != ERROR_IO_PENDING:
        retFuture.fail(newException(EOS, osErrorMsg(err)))
        dealloc(ol)
    else:
      # Request to read completed immediately.
      var data = newString(size)
      copyMem(addr data[0], addr dataBuf.buf[0], size)
      retFuture.complete($data)
      dealloc(ol)
    return retFuture

  proc send*(p: PDispatcher, socket: TSocketHandle, data: string): PFuture[int] =
    ## Sends ``data`` to ``socket``. The returned future will complete once all
    ## data has been sent.
    var retFuture = newFuture[int]()

    var dataBuf: TWSABuf
    dataBuf.buf = data
    dataBuf.len = data.len

    var bytesReceived, flags: DWord
    var ol = cast[PCustomOverlapped](alloc0(sizeof(TCustomOverlapped)))
    ol.data = TCompletionData(sock: socket, cb:
      proc (sock: TSocketHandle, errcode: TOSErrorCode) =
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
      dealloc(ol)
    return retFuture

  proc acceptAddr*(p: PDispatcher, socket: TSocketHandle): 
      PFuture[tuple[address: string, client: TSocketHandle]] =
    ## Accepts a new connection. Returns a future containing the client socket
    ## corresponding to that connection and the remote address of the client.
    ## The future will complete when the connection is successfully accepted.
    
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
      # TODO: IPv6. Check ``sa_family``. http://stackoverflow.com/a/9212542/492186
      retFuture.complete(
        (address: $inet_ntoa(cast[ptr Tsockaddr_in](remoteSockAddr).sin_addr),
         client: clientSock)
      )

    var ol = cast[PCustomOverlapped](alloc0(sizeof(TCustomOverlapped)))
    ol.data = TCompletionData(sock: socket, cb:
      proc (sock: TSocketHandle, errcode: TOSErrorCode) =
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
      dealloc(ol)

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

  initAll()
else:
  # TODO: Selectors.


when isMainModule:
  
  var p = newDispatcher()
  var sock = socket()
  #sock.setBlocking false
  p.register(sock)

  when true:

    var f = p.connect(sock, "irc.freenode.org", TPort(6667))
    f.callback =
      proc (future: PFuture[int]) =
        echo("Connected in future!")
        echo(future.read)
        for i in 0 .. 50:
          var recvF = p.recv(sock, 10)
          recvF.callback =
            proc (future: PFuture[string]) =
              echo("Read: ", future.read)

  else:

    sock.bindAddr(TPort(6667))
    sock.listen()
    proc onAccept(future: PFuture[TSocketHandle]) =
      echo "Accepted"
      var t = p.send(future.read, "test\c\L")
      t.callback =
        proc (future: PFuture[int]) =
          echo(future.read)
      
      var f = p.accept(sock)
      f.callback = onAccept
      
    var f = p.accept(sock)
    f.callback = onAccept
  
  while true:
    p.poll()
    echo "polled"





  

  