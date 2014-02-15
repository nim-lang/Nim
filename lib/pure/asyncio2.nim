#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2014 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import os, oids, tables, strutils, macros

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

when defined(windows):
  type
    TCompletionKey = dword

    TCompletionData* = object
      sock: TSocketHandle
      cb: proc (sock: TSocketHandle, bytesTransferred: DWORD,
                errcode: TOSErrorCode) {.closure.}

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
    ## all of the requested data is read.

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
  case node.kind
  of nnkReturnStmt:
    result = newNimNode(nnkStmtList)
    result.add newCall(newIdentNode("complete"), retFutureSym,
      if node[0].kind == nnkEmpty: newIdentNode("result") else: node[0])
    result.add newNimNode(nnkYieldStmt).add(newNilLit())
  of nnkCommand:
    result = node
    echo(treeRepr(node))
    if node[0].ident == !"await":
      case node[1].kind
      of nnkIdent, nnkCall:
        # await x
        # await foo(p, x)
        result = newNimNode(nnkYieldStmt).add(node[1]) # -> yield x
      else:
        error("Invalid node kind in 'await', got: " & $node[1].kind)
    elif node[1].kind == nnkIdent and node[1][0].ident == !"await":
      # foo await x
      var newCommand = node
      createVar("future" & $node[0].ident, node[1][0], newCommand[1])
      result.add newCommand
  of nnkVarSection, nnkLetSection:
    result = node
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
    result = node
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
  else:
    result = node
    for i in 0 .. <node.len:
      result[i] = processBody(node[i], retFutureSym)

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
    c = await p.recv(socket, 1)
    if c.len == 0:
      return
    if c == "\r":
      c = await p.recv(socket, 1, MSG_PEEK)
      if c.len > 0 and c == "\L":
        discard await p.recv(socket, 1)
      addNLIfEmpty()
      return
    elif c == "\L":
      addNLIfEmpty()
      return
    add(result.string, c)

when isMainModule:
  
  var p = newDispatcher()
  var sock = socket()
  #sock.setBlocking false
  p.register(sock)


  when true:
    # Await tests
    proc main(p: PDispatcher): PFuture[int] {.async.} =
      discard await p.connect(sock, "irc.freenode.net", TPort(6667))
      while true:
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





  

  