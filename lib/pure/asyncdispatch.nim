#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

include "system/inclrtl"

import os, oids, tables, strutils, macros, times, heapqueue

import nativesockets, net, queues

export Port, SocketFlag

#{.injectStmt: newGcInvariant().}

## AsyncDispatch
## *************
##
## This module implements asynchronous IO. This includes a dispatcher,
## a ``Future`` type implementation, and an ``async`` macro which allows
## asynchronous code to be written in a synchronous style with the ``await``
## keyword.
##
## The dispatcher acts as a kind of event loop. You must call ``poll`` on it
## (or a function which does so for you such as ``waitFor`` or ``runForever``)
## in order to poll for any outstanding events. The underlying implementation
## is based on epoll on Linux, IO Completion Ports on Windows and select on
## other operating systems.
##
## The ``poll`` function will not, on its own, return any events. Instead
## an appropriate ``Future`` object will be completed. A ``Future`` is a
## type which holds a value which is not yet available, but which *may* be
## available in the future. You can check whether a future is finished
## by using the ``finished`` function. When a future is finished it means that
## either the value that it holds is now available or it holds an error instead.
## The latter situation occurs when the operation to complete a future fails
## with an exception. You can distinguish between the two situations with the
## ``failed`` function.
##
## Future objects can also store a callback procedure which will be called
## automatically once the future completes.
##
## Futures therefore can be thought of as an implementation of the proactor
## pattern. In this
## pattern you make a request for an action, and once that action is fulfilled
## a future is completed with the result of that action. Requests can be
## made by calling the appropriate functions. For example: calling the ``recv``
## function will create a request for some data to be read from a socket. The
## future which the ``recv`` function returns will then complete once the
## requested amount of data is read **or** an exception occurs.
##
## Code to read some data from a socket may look something like this:
##
##   .. code-block::nim
##      var future = socket.recv(100)
##      future.callback =
##        proc () =
##          echo(future.read)
##
## All asynchronous functions returning a ``Future`` will not block. They
## will not however return immediately. An asynchronous function will have
## code which will be executed before an asynchronous request is made, in most
## cases this code sets up the request.
##
## In the above example, the ``recv`` function will return a brand new
## ``Future`` instance once the request for data to be read from the socket
## is made. This ``Future`` instance will complete once the requested amount
## of data is read, in this case it is 100 bytes. The second line sets a
## callback on this future which will be called once the future completes.
## All the callback does is write the data stored in the future to ``stdout``.
## The ``read`` function is used for this and it checks whether the future
## completes with an error for you (if it did it will simply raise the
## error), if there is no error however it returns the value of the future.
##
## Asynchronous procedures
## -----------------------
##
## Asynchronous procedures remove the pain of working with callbacks. They do
## this by allowing you to write asynchronous code the same way as you would
## write synchronous code.
##
## An asynchronous procedure is marked using the ``{.async.}`` pragma.
## When marking a procedure with the ``{.async.}`` pragma it must have a
## ``Future[T]`` return type or no return type at all. If you do not specify
## a return type then ``Future[void]`` is assumed.
##
## Inside asynchronous procedures ``await`` can be used to call any
## procedures which return a
## ``Future``; this includes asynchronous procedures. When a procedure is
## "awaited", the asynchronous procedure it is awaited in will
## suspend its execution
## until the awaited procedure's Future completes. At which point the
## asynchronous procedure will resume its execution. During the period
## when an asynchronous procedure is suspended other asynchronous procedures
## will be run by the dispatcher.
##
## The ``await`` call may be used in many contexts. It can be used on the right
## hand side of a variable declaration: ``var data = await socket.recv(100)``,
## in which case the variable will be set to the value of the future
## automatically. It can be used to await a ``Future`` object, and it can
## be used to await a procedure returning a ``Future[void]``:
## ``await socket.send("foobar")``.
##
## Discarding futures
## ------------------
##
## Futures should **never** be discarded. This is because they may contain
## errors. If you do not care for the result of a Future then you should
## use the ``asyncCheck`` procedure instead of the ``discard`` keyword.
##
## Examples
## --------
##
## For examples take a look at the documentation for the modules implementing
## asynchronous IO. A good place to start is the
## `asyncnet module <asyncnet.html>`_.
##
## Limitations/Bugs
## ----------------
##
## * The effect system (``raises: []``) does not work with async procedures.
## * Can't await in a ``except`` body
## * Forward declarations for async procs are broken,
##   link includes workaround: https://github.com/nim-lang/Nim/issues/3182.
## * FutureVar[T] needs to be completed manually.

# TODO: Check if yielded future is nil and throw a more meaningful exception

# -- Futures

type
  FutureBase* = ref object of RootObj ## Untyped future.
    cb: proc () {.closure,gcsafe.}
    finished: bool
    error*: ref Exception ## Stored exception
    errorStackTrace*: string
    when not defined(release):
      stackTrace: string ## For debugging purposes only.
      id: int
      fromProc: string

  Future*[T] = ref object of FutureBase ## Typed future.
    value: T ## Stored value

  FutureVar*[T] = distinct Future[T]

  FutureError* = object of Exception
    cause*: FutureBase

{.deprecated: [PFutureBase: FutureBase, PFuture: Future].}

when not defined(release):
  var currentID = 0

proc callSoon*(cbproc: proc ()) {.gcsafe.}

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

proc newFutureVar*[T](fromProc = "unspecified"): FutureVar[T] =
  ## Create a new ``FutureVar``. This Future type is ideally suited for
  ## situations where you want to avoid unnecessary allocations of Futures.
  ##
  ## Specifying ``fromProc``, which is a string specifying the name of the proc
  ## that this future belongs to, is a good habit as it helps with debugging.
  result = FutureVar[T](newFuture[T](fromProc))

proc clean*[T](future: FutureVar[T]) =
  ## Resets the ``finished`` status of ``future``.
  Future[T](future).finished = false
  Future[T](future).error = nil

proc checkFinished[T](future: Future[T]) =
  ## Checks whether `future` is finished. If it is then raises a
  ## ``FutureError``.
  when not defined(release):
    if future.finished:
      var msg = ""
      msg.add("An attempt was made to complete a Future more than once. ")
      msg.add("Details:")
      msg.add("\n  Future ID: " & $future.id)
      msg.add("\n  Created in proc: " & future.fromProc)
      msg.add("\n  Stack trace to moment of creation:")
      msg.add("\n" & indent(future.stackTrace.strip(), 4))
      when T is string:
        msg.add("\n  Contents (string): ")
        msg.add("\n" & indent(future.value.repr, 4))
      msg.add("\n  Stack trace to moment of secondary completion:")
      msg.add("\n" & indent(getStackTrace().strip(), 4))
      var err = newException(FutureError, msg)
      err.cause = future
      raise err

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

proc complete*[T](future: FutureVar[T]) =
  ## Completes a ``FutureVar``.
  template fut: expr = Future[T](future)
  checkFinished(fut)
  assert(fut.error == nil)
  fut.finished = true
  if fut.cb != nil:
    fut.cb()

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
    callSoon(future.cb)

proc `callback=`*[T](future: Future[T],
    cb: proc (future: Future[T]) {.closure,gcsafe.}) =
  ## Sets the callback proc to be called when the future completes.
  ##
  ## If future has already completed then ``cb`` will be called immediately.
  future.callback = proc () = cb(future)

proc injectStacktrace[T](future: Future[T]) =
  # TODO: Come up with something better.
  when not defined(release):
    var msg = ""
    msg.add("\n  " & future.fromProc & "'s lead up to read of failed Future:")

    if not future.errorStackTrace.isNil and future.errorStackTrace != "":
      msg.add("\n" & indent(future.errorStackTrace.strip(), 4))
    else:
      msg.add("\n    Empty or nil stack trace.")
    future.error.msg.add(msg)

proc read*[T](future: Future[T]): T =
  ## Retrieves the value of ``future``. Future must be finished otherwise
  ## this function will fail with a ``ValueError`` exception.
  ##
  ## If the result of the future is an error then that error will be raised.
  if future.finished:
    if future.error != nil:
      injectStacktrace(future)
      raise future.error
    when T isnot void:
      return future.value
  else:
    # TODO: Make a custom exception type for this?
    raise newException(ValueError, "Future still in progress.")

proc readError*[T](future: Future[T]): ref Exception =
  ## Retrieves the exception stored in ``future``.
  ##
  ## An ``ValueError`` exception will be thrown if no exception exists
  ## in the specified Future.
  if future.error != nil: return future.error
  else:
    raise newException(ValueError, "No error in future.")

proc mget*[T](future: FutureVar[T]): var T =
  ## Returns a mutable value stored in ``future``.
  ##
  ## Unlike ``read``, this function will not raise an exception if the
  ## Future has not been finished.
  result = Future[T](future).value

proc finished*[T](future: Future[T]): bool =
  ## Determines whether ``future`` has completed.
  ##
  ## ``True`` may indicate an error or a value. Use ``failed`` to distinguish.
  future.finished

proc failed*(future: FutureBase): bool =
  ## Determines whether ``future`` completed with an error.
  return future.error != nil

proc asyncCheck*[T](future: Future[T]) =
  ## Sets a callback on ``future`` which raises an exception if the future
  ## finished with an error.
  ##
  ## This should be used instead of ``discard`` to discard void futures.
  future.callback =
    proc () =
      if future.failed:
        injectStacktrace(future)
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

proc all*[T](futs: varargs[Future[T]]): auto =
  ## Returns a future which will complete once
  ## all futures in ``futs`` complete.
  ##
  ## If the awaited futures are not ``Future[void]``, the returned future
  ## will hold the values of all awaited futures in a sequence.
  ##
  ## If the awaited futures *are* ``Future[void]``,
  ## this proc returns ``Future[void]``.

  when T is void:
    var
      retFuture = newFuture[void]("asyncdispatch.all")
      completedFutures = 0

    let totalFutures = len(futs)

    for fut in futs:
      fut.callback = proc(f: Future[T]) =
        inc(completedFutures)

        if completedFutures == totalFutures:
          retFuture.complete()

    return retFuture

  else:
    var
      retFuture = newFuture[seq[T]]("asyncdispatch.all")
      retValues = newSeq[T](len(futs))
      completedFutures = 0

    for i, fut in futs:
      proc setCallback(i: int) =
        fut.callback = proc(f: Future[T]) =
          retValues[i] = f.read()
          inc(completedFutures)

          if completedFutures == len(retValues):
            retFuture.complete(retValues)

      setCallback(i)

    return retFuture

type
  PDispatcherBase = ref object of RootRef
    timers: HeapQueue[tuple[finishAt: float, fut: Future[void]]]
    callbacks: Queue[proc ()]

proc processTimers(p: PDispatcherBase) {.inline.} =
  while p.timers.len > 0 and epochTime() >= p.timers[0].finishAt:
    p.timers.pop().fut.complete()

proc processPendingCallbacks(p: PDispatcherBase) =
  while p.callbacks.len > 0:
    var cb = p.callbacks.dequeue()
    cb()

proc adjustedTimeout(p: PDispatcherBase, timeout: int): int {.inline.} =
  # If dispatcher has active timers this proc returns the timeout
  # of the nearest timer. Returns `timeout` otherwise.
  result = timeout
  if p.timers.len > 0:
    let timerTimeout = p.timers[0].finishAt
    let curTime = epochTime()
    if timeout == -1 or (curTime + (timeout / 1000)) > timerTimeout:
      result = int((timerTimeout - curTime) * 1000)
      if result < 0: result = 0

when defined(windows) or defined(nimdoc):
  import winlean, sets, hashes
  type
    CompletionKey = ULONG_PTR

    CompletionData* = object
      fd*: AsyncFD # TODO: Rename this.
      cb*: proc (fd: AsyncFD, bytesTransferred: Dword,
                errcode: OSErrorCode) {.closure,gcsafe.}
      cell*: ForeignCell # we need this `cell` to protect our `cb` environment,
                         # when using RegisterWaitForSingleObject, because
                         # waiting is done in different thread.

    PDispatcher* = ref object of PDispatcherBase
      ioPort: Handle
      handles: HashSet[AsyncFD]

    CustomOverlapped = object of OVERLAPPED
      data*: CompletionData

    PCustomOverlapped* = ref CustomOverlapped

    AsyncFD* = distinct int

    PostCallbackData = object
      ioPort: Handle
      handleFd: AsyncFD
      waitFd: Handle
      ovl: PCustomOverlapped
    PostCallbackDataPtr = ptr PostCallbackData

    Callback = proc (fd: AsyncFD): bool {.closure,gcsafe.}
  {.deprecated: [TCompletionKey: CompletionKey, TAsyncFD: AsyncFD,
                TCustomOverlapped: CustomOverlapped, TCompletionData: CompletionData].}

  proc hash(x: AsyncFD): Hash {.borrow.}
  proc `==`*(x: AsyncFD, y: AsyncFD): bool {.borrow.}

  proc newDispatcher*(): PDispatcher =
    ## Creates a new Dispatcher instance.
    new result
    result.ioPort = createIoCompletionPort(INVALID_HANDLE_VALUE, 0, 0, 1)
    result.handles = initSet[AsyncFD]()
    result.timers.newHeapQueue()
    result.callbacks = initQueue[proc ()](64)

  var gDisp{.threadvar.}: PDispatcher ## Global dispatcher
  proc getGlobalDispatcher*(): PDispatcher =
    ## Retrieves the global thread-local dispatcher.
    if gDisp.isNil: gDisp = newDispatcher()
    result = gDisp

  proc register*(fd: AsyncFD) =
    ## Registers ``fd`` with the dispatcher.
    let p = getGlobalDispatcher()
    if createIoCompletionPort(fd.Handle, p.ioPort,
                              cast[CompletionKey](fd), 1) == 0:
      raiseOSError(osLastError())
    p.handles.incl(fd)

  proc verifyPresence(fd: AsyncFD) =
    ## Ensures that file descriptor has been registered with the dispatcher.
    let p = getGlobalDispatcher()
    if fd notin p.handles:
      raise newException(ValueError,
        "Operation performed on a socket which has not been registered with" &
        " the dispatcher yet.")

  proc poll*(timeout = 500) =
    ## Waits for completion events and processes them.
    let p = getGlobalDispatcher()
    if p.handles.len == 0 and p.timers.len == 0 and p.callbacks.len == 0:
      raise newException(ValueError,
        "No handles or timers registered in dispatcher.")

    let at = p.adjustedTimeout(timeout)
    var llTimeout =
      if at == -1: winlean.INFINITE
      else: at.int32

    var lpNumberOfBytesTransferred: Dword
    var lpCompletionKey: ULONG_PTR
    var customOverlapped: PCustomOverlapped
    let res = getQueuedCompletionStatus(p.ioPort,
        addr lpNumberOfBytesTransferred, addr lpCompletionKey,
        cast[ptr POVERLAPPED](addr customOverlapped), llTimeout).bool

    # http://stackoverflow.com/a/12277264/492186
    # TODO: http://www.serverframework.com/handling-multiple-pending-socket-read-and-write-operations.html
    if res:
      # This is useful for ensuring the reliability of the overlapped struct.
      assert customOverlapped.data.fd == lpCompletionKey.AsyncFD

      customOverlapped.data.cb(customOverlapped.data.fd,
          lpNumberOfBytesTransferred, OSErrorCode(-1))

      # If cell.data != nil, then system.protect(rawEnv(cb)) was called,
      # so we need to dispose our `cb` environment, because it is not needed
      # anymore.
      if customOverlapped.data.cell.data != nil:
        system.dispose(customOverlapped.data.cell)

      GC_unref(customOverlapped)
    else:
      let errCode = osLastError()
      if customOverlapped != nil:
        assert customOverlapped.data.fd == lpCompletionKey.AsyncFD
        customOverlapped.data.cb(customOverlapped.data.fd,
            lpNumberOfBytesTransferred, errCode)
        if customOverlapped.data.cell.data != nil:
          system.dispose(customOverlapped.data.cell)
        GC_unref(customOverlapped)
      else:
        if errCode.int32 == WAIT_TIMEOUT:
          # Timed out
          discard
        else: raiseOSError(errCode)

    # Timer processing.
    processTimers(p)
    # Callback queue processing
    processPendingCallbacks(p)

  var connectExPtr: pointer = nil
  var acceptExPtr: pointer = nil
  var getAcceptExSockAddrsPtr: pointer = nil

  proc initPointer(s: SocketHandle, fun: var pointer, guid: var GUID): bool =
    # Ref: https://github.com/powdahound/twisted/blob/master/twisted/internet/iocpreactor/iocpsupport/winsock_pointers.c
    var bytesRet: Dword
    fun = nil
    result = WSAIoctl(s, SIO_GET_EXTENSION_FUNCTION_POINTER, addr guid,
                      sizeof(GUID).Dword, addr fun, sizeof(pointer).Dword,
                      addr bytesRet, nil, nil) == 0

  proc initAll() =
    let dummySock = newNativeSocket()
    if not initPointer(dummySock, connectExPtr, WSAID_CONNECTEX):
      raiseOSError(osLastError())
    if not initPointer(dummySock, acceptExPtr, WSAID_ACCEPTEX):
      raiseOSError(osLastError())
    if not initPointer(dummySock, getAcceptExSockAddrsPtr, WSAID_GETACCEPTEXSOCKADDRS):
      raiseOSError(osLastError())

  proc connectEx(s: SocketHandle, name: ptr SockAddr, namelen: cint,
                  lpSendBuffer: pointer, dwSendDataLength: Dword,
                  lpdwBytesSent: PDword, lpOverlapped: POVERLAPPED): bool =
    if connectExPtr.isNil: raise newException(ValueError, "Need to initialise ConnectEx().")
    let fun =
      cast[proc (s: SocketHandle, name: ptr SockAddr, namelen: cint,
         lpSendBuffer: pointer, dwSendDataLength: Dword,
         lpdwBytesSent: PDword, lpOverlapped: POVERLAPPED): bool {.stdcall,gcsafe.}](connectExPtr)

    result = fun(s, name, namelen, lpSendBuffer, dwSendDataLength, lpdwBytesSent,
         lpOverlapped)

  proc acceptEx(listenSock, acceptSock: SocketHandle, lpOutputBuffer: pointer,
                 dwReceiveDataLength, dwLocalAddressLength,
                 dwRemoteAddressLength: Dword, lpdwBytesReceived: PDword,
                 lpOverlapped: POVERLAPPED): bool =
    if acceptExPtr.isNil: raise newException(ValueError, "Need to initialise AcceptEx().")
    let fun =
      cast[proc (listenSock, acceptSock: SocketHandle, lpOutputBuffer: pointer,
                 dwReceiveDataLength, dwLocalAddressLength,
                 dwRemoteAddressLength: Dword, lpdwBytesReceived: PDword,
                 lpOverlapped: POVERLAPPED): bool {.stdcall,gcsafe.}](acceptExPtr)
    result = fun(listenSock, acceptSock, lpOutputBuffer, dwReceiveDataLength,
        dwLocalAddressLength, dwRemoteAddressLength, lpdwBytesReceived,
        lpOverlapped)

  proc getAcceptExSockaddrs(lpOutputBuffer: pointer,
      dwReceiveDataLength, dwLocalAddressLength, dwRemoteAddressLength: Dword,
      LocalSockaddr: ptr ptr SockAddr, LocalSockaddrLength: LPInt,
      RemoteSockaddr: ptr ptr SockAddr, RemoteSockaddrLength: LPInt) =
    if getAcceptExSockAddrsPtr.isNil:
      raise newException(ValueError, "Need to initialise getAcceptExSockAddrs().")

    let fun =
      cast[proc (lpOutputBuffer: pointer,
                 dwReceiveDataLength, dwLocalAddressLength,
                 dwRemoteAddressLength: Dword, LocalSockaddr: ptr ptr SockAddr,
                 LocalSockaddrLength: LPInt, RemoteSockaddr: ptr ptr SockAddr,
                RemoteSockaddrLength: LPInt) {.stdcall,gcsafe.}](getAcceptExSockAddrsPtr)

    fun(lpOutputBuffer, dwReceiveDataLength, dwLocalAddressLength,
                  dwRemoteAddressLength, LocalSockaddr, LocalSockaddrLength,
                  RemoteSockaddr, RemoteSockaddrLength)

  proc connect*(socket: AsyncFD, address: string, port: Port,
    domain = nativesockets.AF_INET): Future[void] =
    ## Connects ``socket`` to server at ``address:port``.
    ##
    ## Returns a ``Future`` which will complete when the connection succeeds
    ## or an error occurs.
    verifyPresence(socket)
    var retFuture = newFuture[void]("connect")
    # Apparently ``ConnectEx`` expects the socket to be initially bound:
    var saddr: Sockaddr_in
    saddr.sin_family = int16(toInt(domain))
    saddr.sin_port = 0
    saddr.sin_addr.s_addr = INADDR_ANY
    if bindAddr(socket.SocketHandle, cast[ptr SockAddr](addr(saddr)),
                  sizeof(saddr).SockLen) < 0'i32:
      raiseOSError(osLastError())

    var aiList = getAddrInfo(address, port, domain)
    var success = false
    var lastError: OSErrorCode
    var it = aiList
    while it != nil:
      # "the OVERLAPPED structure must remain valid until the I/O completes"
      # http://blogs.msdn.com/b/oldnewthing/archive/2011/02/02/10123392.aspx
      var ol = PCustomOverlapped()
      GC_ref(ol)
      ol.data = CompletionData(fd: socket, cb:
        proc (fd: AsyncFD, bytesCount: Dword, errcode: OSErrorCode) =
          if not retFuture.finished:
            if errcode == OSErrorCode(-1):
              retFuture.complete()
            else:
              retFuture.fail(newException(OSError, osErrorMsg(errcode)))
      )

      var ret = connectEx(socket.SocketHandle, it.ai_addr,
                          sizeof(Sockaddr_in).cint, nil, 0, nil,
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

  proc recv*(socket: AsyncFD, size: int,
             flags = {SocketFlag.SafeDisconn}): Future[string] =
    ## Reads **up to** ``size`` bytes from ``socket``. Returned future will
    ## complete once all the data requested is read, a part of the data has been
    ## read, or the socket has disconnected in which case the future will
    ## complete with a value of ``""``.
    ##
    ## **Warning**: The ``Peek`` socket flag is not supported on Windows.


    # Things to note:
    #   * When WSARecv completes immediately then ``bytesReceived`` is very
    #     unreliable.
    #   * Still need to implement message-oriented socket disconnection,
    #     '\0' in the message currently signifies a socket disconnect. Who
    #     knows what will happen when someone sends that to our socket.
    verifyPresence(socket)
    assert SocketFlag.Peek notin flags, "Peek not supported on Windows."

    var retFuture = newFuture[string]("recv")
    var dataBuf: TWSABuf
    dataBuf.buf = cast[cstring](alloc0(size))
    dataBuf.len = size.ULONG

    var bytesReceived: Dword
    var flagsio = flags.toOSFlags().Dword
    var ol = PCustomOverlapped()
    GC_ref(ol)
    ol.data = CompletionData(fd: socket, cb:
      proc (fd: AsyncFD, bytesCount: Dword, errcode: OSErrorCode) =
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
    elif ret == 0:
      # Request completed immediately.
      if bytesReceived != 0:
        var data = newString(bytesReceived)
        assert bytesReceived <= size
        copyMem(addr data[0], addr dataBuf.buf[0], bytesReceived)
        retFuture.complete($data)
      else:
        if hasOverlappedIoCompleted(cast[POVERLAPPED](ol)):
          retFuture.complete("")
    return retFuture

  proc recvInto*(socket: AsyncFD, buf: cstring, size: int,
                flags = {SocketFlag.SafeDisconn}): Future[int] =
    ## Reads **up to** ``size`` bytes from ``socket`` into ``buf``, which must
    ## at least be of that size. Returned future will complete once all the
    ## data requested is read, a part of the data has been read, or the socket
    ## has disconnected in which case the future will complete with a value of
    ## ``0``.
    ##
    ## **Warning**: The ``Peek`` socket flag is not supported on Windows.


    # Things to note:
    #   * When WSARecv completes immediately then ``bytesReceived`` is very
    #     unreliable.
    #   * Still need to implement message-oriented socket disconnection,
    #     '\0' in the message currently signifies a socket disconnect. Who
    #     knows what will happen when someone sends that to our socket.
    verifyPresence(socket)
    assert SocketFlag.Peek notin flags, "Peek not supported on Windows."

    var retFuture = newFuture[int]("recvInto")

    #buf[] = '\0'
    var dataBuf: TWSABuf
    dataBuf.buf = buf
    dataBuf.len = size.ULONG

    var bytesReceived: Dword
    var flagsio = flags.toOSFlags().Dword
    var ol = PCustomOverlapped()
    GC_ref(ol)
    ol.data = CompletionData(fd: socket, cb:
      proc (fd: AsyncFD, bytesCount: Dword, errcode: OSErrorCode) =
        if not retFuture.finished:
          if errcode == OSErrorCode(-1):
            if bytesCount == 0 and dataBuf.buf[0] == '\0':
              retFuture.complete(0)
            else:
              retFuture.complete(bytesCount)
          else:
            if flags.isDisconnectionError(errcode):
              retFuture.complete(0)
            else:
              retFuture.fail(newException(OSError, osErrorMsg(errcode)))
        if dataBuf.buf != nil:
          dataBuf.buf = nil
    )

    let ret = WSARecv(socket.SocketHandle, addr dataBuf, 1, addr bytesReceived,
                      addr flagsio, cast[POVERLAPPED](ol), nil)
    if ret == -1:
      let err = osLastError()
      if err.int32 != ERROR_IO_PENDING:
        if dataBuf.buf != nil:
          dataBuf.buf = nil
        GC_unref(ol)
        if flags.isDisconnectionError(err):
          retFuture.complete(0)
        else:
          retFuture.fail(newException(OSError, osErrorMsg(err)))
    elif ret == 0:
      # Request completed immediately.
      if bytesReceived != 0:
        assert bytesReceived <= size
        retFuture.complete(bytesReceived)
      else:
        if hasOverlappedIoCompleted(cast[POVERLAPPED](ol)):
          retFuture.complete(bytesReceived)
    return retFuture

  proc send*(socket: AsyncFD, data: string,
             flags = {SocketFlag.SafeDisconn}): Future[void] =
    ## Sends ``data`` to ``socket``. The returned future will complete once all
    ## data has been sent.
    verifyPresence(socket)
    var retFuture = newFuture[void]("send")

    var dataBuf: TWSABuf
    dataBuf.buf = data # since this is not used in a callback, this is fine
    dataBuf.len = data.len.ULONG

    var bytesReceived, lowFlags: Dword
    var ol = PCustomOverlapped()
    GC_ref(ol)
    ol.data = CompletionData(fd: socket, cb:
      proc (fd: AsyncFD, bytesCount: Dword, errcode: OSErrorCode) =
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

  proc acceptAddr*(socket: AsyncFD, flags = {SocketFlag.SafeDisconn}):
      Future[tuple[address: string, client: AsyncFD]] =
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
    var retFuture = newFuture[tuple[address: string, client: AsyncFD]]("acceptAddr")

    var clientSock = newNativeSocket()
    if clientSock == osInvalidSocket: raiseOSError(osLastError())

    const lpOutputLen = 1024
    var lpOutputBuf = newString(lpOutputLen)
    var dwBytesReceived: Dword
    let dwReceiveDataLength = 0.Dword # We don't want any data to be read.
    let dwLocalAddressLength = Dword(sizeof (Sockaddr_in) + 16)
    let dwRemoteAddressLength = Dword(sizeof(Sockaddr_in) + 16)

    template completeAccept(): stmt {.immediate, dirty.} =
      var listenSock = socket
      let setoptRet = setsockopt(clientSock, SOL_SOCKET,
          SO_UPDATE_ACCEPT_CONTEXT, addr listenSock,
          sizeof(listenSock).SockLen)
      if setoptRet != 0: raiseOSError(osLastError())

      var localSockaddr, remoteSockaddr: ptr SockAddr
      var localLen, remoteLen: int32
      getAcceptExSockaddrs(addr lpOutputBuf[0], dwReceiveDataLength,
                           dwLocalAddressLength, dwRemoteAddressLength,
                           addr localSockaddr, addr localLen,
                           addr remoteSockaddr, addr remoteLen)
      register(clientSock.AsyncFD)
      # TODO: IPv6. Check ``sa_family``. http://stackoverflow.com/a/9212542/492186
      retFuture.complete(
        (address: $inet_ntoa(cast[ptr Sockaddr_in](remoteSockAddr).sin_addr),
         client: clientSock.AsyncFD)
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
    ol.data = CompletionData(fd: socket, cb:
      proc (fd: AsyncFD, bytesCount: Dword, errcode: OSErrorCode) =
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

  proc newAsyncNativeSocket*(domain, sockType, protocol: cint): AsyncFD =
    ## Creates a new socket and registers it with the dispatcher implicitly.
    result = newNativeSocket(domain, sockType, protocol).AsyncFD
    result.SocketHandle.setBlocking(false)
    register(result)

  proc newAsyncNativeSocket*(domain: Domain = nativesockets.AF_INET,
                             sockType: SockType = SOCK_STREAM,
                             protocol: Protocol = IPPROTO_TCP): AsyncFD =
    ## Creates a new socket and registers it with the dispatcher implicitly.
    result = newNativeSocket(domain, sockType, protocol).AsyncFD
    result.SocketHandle.setBlocking(false)
    register(result)

  proc closeSocket*(socket: AsyncFD) =
    ## Closes a socket and ensures that it is unregistered.
    socket.SocketHandle.close()
    getGlobalDispatcher().handles.excl(socket)

  proc unregister*(fd: AsyncFD) =
    ## Unregisters ``fd``.
    getGlobalDispatcher().handles.excl(fd)

  {.push stackTrace:off.}
  proc waitableCallback(param: pointer,
                        timerOrWaitFired: WINBOOL): void {.stdcall.} =
    var p = cast[PostCallbackDataPtr](param)
    discard postQueuedCompletionStatus(p.ioPort, timerOrWaitFired.Dword,
                                       ULONG_PTR(p.handleFd),
                                       cast[pointer](p.ovl))
  {.pop.}

  template registerWaitableEvent(mask) =
    let p = getGlobalDispatcher()
    var flags = (WT_EXECUTEINWAITTHREAD or WT_EXECUTEONLYONCE).Dword
    var hEvent = wsaCreateEvent()
    if hEvent == 0:
      raiseOSError(osLastError())
    var pcd = cast[PostCallbackDataPtr](allocShared0(sizeof(PostCallbackData)))
    pcd.ioPort = p.ioPort
    pcd.handleFd = fd
    var ol = PCustomOverlapped()
    GC_ref(ol)

    ol.data = CompletionData(fd: fd, cb:
      proc(fd: AsyncFD, bytesCount: Dword, errcode: OSErrorCode) =
        # we excluding our `fd` because cb(fd) can register own handler
        # for this `fd`
        p.handles.excl(fd)
        # unregisterWait() is called before callback, because appropriate
        # winsockets function can re-enable event.
        # https://msdn.microsoft.com/en-us/library/windows/desktop/ms741576(v=vs.85).aspx
        if unregisterWait(pcd.waitFd) == 0:
          let err = osLastError()
          if err.int32 != ERROR_IO_PENDING:
            raiseOSError(osLastError())
        if cb(fd):
          # callback returned `true`, so we free all allocated resources
          deallocShared(cast[pointer](pcd))
          if not wsaCloseEvent(hEvent):
            raiseOSError(osLastError())
          # pcd.ovl will be unrefed in poll().
        else:
          # callback returned `false` we need to continue
          if p.handles.contains(fd):
            # new callback was already registered with `fd`, so we free all
            # allocated resources. This happens because in callback `cb`
            # addRead/addWrite was called with same `fd`.
            deallocShared(cast[pointer](pcd))
            if not wsaCloseEvent(hEvent):
              raiseOSError(osLastError())
          else:
            # we need to include `fd` again
            p.handles.incl(fd)
            # and register WaitForSingleObject again
            if not registerWaitForSingleObject(addr(pcd.waitFd), hEvent,
                                    cast[WAITORTIMERCALLBACK](waitableCallback),
                                       cast[pointer](pcd), INFINITE, flags):
              # pcd.ovl will be unrefed in poll()
              discard wsaCloseEvent(hEvent)
              deallocShared(cast[pointer](pcd))
              raiseOSError(osLastError())
            else:
              # we ref pcd.ovl one more time, because it will be unrefed in
              # poll()
              GC_ref(pcd.ovl)
    )
    # We need to protect our callback environment value, so GC will not free it
    # accidentally.
    ol.data.cell = system.protect(rawEnv(ol.data.cb))

    # This is main part of `hacky way` is using WSAEventSelect, so `hEvent`
    # will be signaled when appropriate `mask` events will be triggered.
    if wsaEventSelect(fd.SocketHandle, hEvent, mask) != 0:
      GC_unref(ol)
      deallocShared(cast[pointer](pcd))
      discard wsaCloseEvent(hEvent)
      raiseOSError(osLastError())

    pcd.ovl = ol
    if not registerWaitForSingleObject(addr(pcd.waitFd), hEvent,
                                    cast[WAITORTIMERCALLBACK](waitableCallback),
                                       cast[pointer](pcd), INFINITE, flags):
      GC_unref(ol)
      deallocShared(cast[pointer](pcd))
      discard wsaCloseEvent(hEvent)
      raiseOSError(osLastError())
    p.handles.incl(fd)

  proc addRead*(fd: AsyncFD, cb: Callback) =
    ## Start watching the file descriptor for read availability and then call
    ## the callback ``cb``.
    ##
    ## This is not ``pure`` mechanism for Windows Completion Ports (IOCP),
    ## so if you can avoid it, please do it. Use `addRead` only if really
    ## need it (main usecase is adaptation of `unix like` libraries to be
    ## asynchronous on Windows).
    ## If you use this function, you dont need to use asyncdispatch.recv()
    ## or asyncdispatch.accept(), because they are using IOCP, please use
    ## nativesockets.recv() and nativesockets.accept() instead.
    ##
    ## Be sure your callback ``cb`` returns ``true``, if you want to remove
    ## watch of `read` notifications, and ``false``, if you want to continue
    ## receiving notifies.
    registerWaitableEvent(FD_READ or FD_ACCEPT or FD_OOB or FD_CLOSE)

  proc addWrite*(fd: AsyncFD, cb: Callback) =
    ## Start watching the file descriptor for write availability and then call
    ## the callback ``cb``.
    ##
    ## This is not ``pure`` mechanism for Windows Completion Ports (IOCP),
    ## so if you can avoid it, please do it. Use `addWrite` only if really
    ## need it (main usecase is adaptation of `unix like` libraries to be
    ## asynchronous on Windows).
    ## If you use this function, you dont need to use asyncdispatch.send()
    ## or asyncdispatch.connect(), because they are using IOCP, please use
    ## nativesockets.send() and nativesockets.connect() instead.
    ##
    ## Be sure your callback ``cb`` returns ``true``, if you want to remove
    ## watch of `write` notifications, and ``false``, if you want to continue
    ## receiving notifies.
    registerWaitableEvent(FD_WRITE or FD_CONNECT or FD_CLOSE)

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
    AsyncFD* = distinct cint
    Callback = proc (fd: AsyncFD): bool {.closure,gcsafe.}

    PData* = ref object of RootRef
      fd: AsyncFD
      readCBs: seq[Callback]
      writeCBs: seq[Callback]

    PDispatcher* = ref object of PDispatcherBase
      selector: Selector
  {.deprecated: [TAsyncFD: AsyncFD, TCallback: Callback].}

  proc `==`*(x, y: AsyncFD): bool {.borrow.}

  proc newDispatcher*(): PDispatcher =
    new result
    result.selector = newSelector()
    result.timers.newHeapQueue()
    result.callbacks = initQueue[proc ()](64)

  var gDisp{.threadvar.}: PDispatcher ## Global dispatcher
  proc getGlobalDispatcher*(): PDispatcher =
    if gDisp.isNil: gDisp = newDispatcher()
    result = gDisp

  proc update(fd: AsyncFD, events: set[Event]) =
    let p = getGlobalDispatcher()
    assert fd.SocketHandle in p.selector
    p.selector.update(fd.SocketHandle, events)

  proc register*(fd: AsyncFD) =
    let p = getGlobalDispatcher()
    var data = PData(fd: fd, readCBs: @[], writeCBs: @[])
    p.selector.register(fd.SocketHandle, {}, data.RootRef)

  proc newAsyncNativeSocket*(domain: cint, sockType: cint,
                             protocol: cint): AsyncFD =
    result = newNativeSocket(domain, sockType, protocol).AsyncFD
    result.SocketHandle.setBlocking(false)
    when defined(macosx):
      result.SocketHandle.setSockOptInt(SOL_SOCKET, SO_NOSIGPIPE, 1)
    register(result)

  proc newAsyncNativeSocket*(domain: Domain = AF_INET,
                             sockType: SockType = SOCK_STREAM,
                             protocol: Protocol = IPPROTO_TCP): AsyncFD =
    result = newNativeSocket(domain, sockType, protocol).AsyncFD
    result.SocketHandle.setBlocking(false)
    when defined(macosx):
      result.SocketHandle.setSockOptInt(SOL_SOCKET, SO_NOSIGPIPE, 1)
    register(result)

  proc closeSocket*(sock: AsyncFD) =
    let disp = getGlobalDispatcher()
    disp.selector.unregister(sock.SocketHandle)
    sock.SocketHandle.close()

  proc unregister*(fd: AsyncFD) =
    getGlobalDispatcher().selector.unregister(fd.SocketHandle)

  proc addRead*(fd: AsyncFD, cb: Callback) =
    let p = getGlobalDispatcher()
    if fd.SocketHandle notin p.selector:
      raise newException(ValueError, "File descriptor not registered.")
    p.selector[fd.SocketHandle].data.PData.readCBs.add(cb)
    update(fd, p.selector[fd.SocketHandle].events + {EvRead})

  proc addWrite*(fd: AsyncFD, cb: Callback) =
    let p = getGlobalDispatcher()
    if fd.SocketHandle notin p.selector:
      raise newException(ValueError, "File descriptor not registered.")
    p.selector[fd.SocketHandle].data.PData.writeCBs.add(cb)
    update(fd, p.selector[fd.SocketHandle].events + {EvWrite})

  proc poll*(timeout = 500) =
    let p = getGlobalDispatcher()
    for info in p.selector.select(p.adjustedTimeout(timeout)):
      let data = PData(info.key.data)
      assert data.fd == info.key.fd.AsyncFD
      #echo("In poll ", data.fd.cint)
      # There may be EvError here, but we handle them in callbacks,
      # so that exceptions can be raised from `send(...)` and
      # `recv(...)` routines.

      if EvRead in info.events:
        # Callback may add items to ``data.readCBs`` which causes issues if
        # we are iterating over ``data.readCBs`` at the same time. We therefore
        # make a copy to iterate over.
        let currentCBs = data.readCBs
        data.readCBs = @[]
        for cb in currentCBs:
          if not cb(data.fd):
            # Callback wants to be called again.
            data.readCBs.add(cb)

      if EvWrite in info.events:
        let currentCBs = data.writeCBs
        data.writeCBs = @[]
        for cb in currentCBs:
          if not cb(data.fd):
            # Callback wants to be called again.
            data.writeCBs.add(cb)

      if info.key in p.selector:
        var newEvents: set[Event]
        if data.readCBs.len != 0: newEvents = {EvRead}
        if data.writeCBs.len != 0: newEvents = newEvents + {EvWrite}
        if newEvents != info.key.events:
          update(data.fd, newEvents)
      else:
        # FD no longer a part of the selector. Likely been closed
        # (e.g. socket disconnected).
        discard

    # Timer processing.
    processTimers(p)
    # Callback queue processing
    processPendingCallbacks(p)

  proc connect*(socket: AsyncFD, address: string, port: Port,
    domain = AF_INET): Future[void] =
    var retFuture = newFuture[void]("connect")

    proc cb(fd: AsyncFD): bool =
      var ret = SocketHandle(fd).getSockOptInt(cint(SOL_SOCKET), cint(SO_ERROR))
      if ret == 0:
          # We have connected.
          retFuture.complete()
          return true
      elif ret == EINTR:
          # interrupted, keep waiting
          return false
      else:
          retFuture.fail(newException(OSError, osErrorMsg(OSErrorCode(ret))))
          return true

    assert getSockDomain(socket.SocketHandle) == domain
    var aiList = getAddrInfo(address, port, domain)
    var success = false
    var lastError: OSErrorCode
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
      retFuture.fail(newException(OSError, osErrorMsg(lastError)))
    return retFuture

  proc recv*(socket: AsyncFD, size: int,
             flags = {SocketFlag.SafeDisconn}): Future[string] =
    var retFuture = newFuture[string]("recv")

    var readBuffer = newString(size)

    proc cb(sock: AsyncFD): bool =
      result = true
      let res = recv(sock.SocketHandle, addr readBuffer[0], size.cint,
                     flags.toOSFlags())
      if res < 0:
        let lastError = osLastError()
        if lastError.int32 notin {EINTR, EWOULDBLOCK, EAGAIN}:
          if flags.isDisconnectionError(lastError):
            retFuture.complete("")
          else:
            retFuture.fail(newException(OSError, osErrorMsg(lastError)))
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

  proc recvInto*(socket: AsyncFD, buf: cstring, size: int,
                  flags = {SocketFlag.SafeDisconn}): Future[int] =
    var retFuture = newFuture[int]("recvInto")

    proc cb(sock: AsyncFD): bool =
      result = true
      let res = recv(sock.SocketHandle, buf, size.cint,
                     flags.toOSFlags())
      if res < 0:
        let lastError = osLastError()
        if lastError.int32 notin {EINTR, EWOULDBLOCK, EAGAIN}:
          if flags.isDisconnectionError(lastError):
            retFuture.complete(0)
          else:
            retFuture.fail(newException(OSError, osErrorMsg(lastError)))
        else:
          result = false # We still want this callback to be called.
      else:
        retFuture.complete(res)
    # TODO: The following causes a massive slowdown.
    #if not cb(socket):
    addRead(socket, cb)
    return retFuture

  proc send*(socket: AsyncFD, data: string,
             flags = {SocketFlag.SafeDisconn}): Future[void] =
    var retFuture = newFuture[void]("send")

    var written = 0

    proc cb(sock: AsyncFD): bool =
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
            retFuture.fail(newException(OSError, osErrorMsg(lastError)))
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

  proc acceptAddr*(socket: AsyncFD, flags = {SocketFlag.SafeDisconn}):
      Future[tuple[address: string, client: AsyncFD]] =
    var retFuture = newFuture[tuple[address: string,
        client: AsyncFD]]("acceptAddr")
    proc cb(sock: AsyncFD): bool =
      result = true
      var sockAddress: Sockaddr_storage
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
            retFuture.fail(newException(OSError, osErrorMsg(lastError)))
      else:
        register(client.AsyncFD)
        retFuture.complete((getAddrString(cast[ptr SockAddr](addr sockAddress)), client.AsyncFD))
    addRead(socket, cb)
    return retFuture

proc sleepAsync*(ms: int): Future[void] =
  ## Suspends the execution of the current async procedure for the next
  ## ``ms`` milliseconds.
  var retFuture = newFuture[void]("sleepAsync")
  let p = getGlobalDispatcher()
  p.timers.push((epochTime() + (ms / 1000), retFuture))
  return retFuture

proc accept*(socket: AsyncFD,
    flags = {SocketFlag.SafeDisconn}): Future[AsyncFD] =
  ## Accepts a new connection. Returns a future containing the client socket
  ## corresponding to that connection.
  ## The future will complete when the connection is successfully accepted.
  var retFut = newFuture[AsyncFD]("accept")
  var fut = acceptAddr(socket, flags)
  fut.callback =
    proc (future: Future[tuple[address: string, client: AsyncFD]]) =
      assert future.finished
      if future.failed:
        retFut.fail(future.error)
      else:
        retFut.complete(future.read.client)
  return retFut

# -- Await Macro

proc skipUntilStmtList(node: NimNode): NimNode {.compileTime.} =
  # Skips a nest of StmtList's.
  result = node
  if node[0].kind == nnkStmtList:
    result = skipUntilStmtList(node[0])

proc skipStmtList(node: NimNode): NimNode {.compileTime.} =
  result = node
  if node[0].kind == nnkStmtList:
    result = node[0]

template createCb(retFutureSym, iteratorNameSym,
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
    tryStmt, rootReceiver, fromNode: NimNode): NimNode {.compileTime.} =
  if tryStmt.kind == nnkNilLit:
    result = rootReceiver
  else:
    var exceptionChecks: seq[tuple[cond, body: NimNode]] = @[]
    let errorNode = newDotExpr(futSym, newIdentNode("error"))
    for i in 1 .. <tryStmt.len:
      let exceptBranch = tryStmt[i]
      if exceptBranch[0].kind == nnkStmtList:
        exceptionChecks.add((newIdentNode("true"), exceptBranch[0]))
      else:
        var exceptIdentCount = 0
        var ifCond: NimNode
        for i in 0 .. <exceptBranch.len:
          let child = exceptBranch[i]
          if child.kind == nnkIdent:
            let cond = infix(errorNode, "of", child)
            if exceptIdentCount == 0:
              ifCond = cond
            else:
              ifCond = infix(ifCond, "or", cond)
          else:
            break
          exceptIdentCount.inc

        expectKind(exceptBranch[exceptIdentCount], nnkStmtList)
        exceptionChecks.add((ifCond, exceptBranch[exceptIdentCount]))
    # -> -> else: raise futSym.error
    exceptionChecks.add((newIdentNode("true"),
        newNimNode(nnkRaiseStmt).add(errorNode)))
    # Read the future if there is no error.
    # -> else: futSym.read
    let elseNode = newNimNode(nnkElse, fromNode)
    elseNode.add newNimNode(nnkStmtList, fromNode)
    elseNode[0].add rootReceiver

    let ifBody = newStmtList()
    ifBody.add newCall(newIdentNode("setCurrentException"), errorNode)
    ifBody.add newIfStmt(exceptionChecks)
    ifBody.add newCall(newIdentNode("setCurrentException"), newNilLit())

    result = newIfStmt(
      (newDotExpr(futSym, newIdentNode("failed")), ifBody)
    )
    result.add elseNode

template useVar(result: var NimNode, futureVarNode: NimNode, valueReceiver,
                rootReceiver: expr, fromNode: NimNode) =
  ## Params:
  ##    futureVarNode: The NimNode which is a symbol identifying the Future[T]
  ##                   variable to yield.
  ##    fromNode: Used for better debug information (to give context).
  ##    valueReceiver: The node which defines an expression that retrieves the
  ##                   future's value.
  ##
  ##    rootReceiver: ??? TODO
  # -> yield future<x>
  result.add newNimNode(nnkYieldStmt, fromNode).add(futureVarNode)
  # -> future<x>.read
  valueReceiver = newDotExpr(futureVarNode, newIdentNode("read"))
  result.add generateExceptionCheck(futureVarNode, tryStmt, rootReceiver,
      fromNode)

template createVar(result: var NimNode, futSymName: string,
                   asyncProc: NimNode,
                   valueReceiver, rootReceiver: expr,
                   fromNode: NimNode) =
  result = newNimNode(nnkStmtList, fromNode)
  var futSym = genSym(nskVar, "future")
  result.add newVarStmt(futSym, asyncProc) # -> var future<x> = y
  useVar(result, futSym, valueReceiver, rootReceiver, fromNode)

proc processBody(node, retFutureSym: NimNode,
                 subTypeIsVoid: bool,
                 tryStmt: NimNode): NimNode {.compileTime.} =
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
        node[0].processBody(retFutureSym, subTypeIsVoid, tryStmt))

    result.add newNimNode(nnkReturnStmt, node).add(newNilLit())
    return # Don't process the children of this return stmt
  of nnkCommand, nnkCall:
    if node[0].kind == nnkIdent and node[0].ident == !"await":
      case node[1].kind
      of nnkIdent, nnkInfix:
        # await x
        # await x or y
        result = newNimNode(nnkYieldStmt, node).add(node[1]) # -> yield x
      of nnkCall, nnkCommand:
        # await foo(p, x)
        # await foo p, x
        var futureValue: NimNode
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
    if node[0].kind == nnkCommand and node[0][0].kind == nnkIdent and
          node[0][0].ident == !"await":
      var newDiscard = node
      result.createVar("futureDiscard_" & $toStrLit(node[0][1]), node[0][1],
                newDiscard[0], newDiscard, node)
  of nnkTryStmt:
    # try: await x; except: ...
    result = newNimNode(nnkStmtList, node)
    template wrapInTry(n, tryBody: expr) =
      var temp = n
      n[0] = tryBody
      tryBody = temp

      # Transform ``except`` body.
      # TODO: Could we perform some ``await`` transformation here to get it
      # working in ``except``?
      tryBody[1] = processBody(n[1], retFutureSym, subTypeIsVoid, nil)

    proc processForTry(n: NimNode, i: var int,
                       res: NimNode): bool {.compileTime.} =
      ## Transforms the body of the tryStmt. Does not transform the
      ## body in ``except``.
      ## Returns true if the tryStmt node was transformed into an ifStmt.
      result = false
      var skipped = n.skipStmtList()
      while i < skipped.len:
        var processed = processBody(skipped[i], retFutureSym,
                                    subTypeIsVoid, n)

        # Check if we transformed the node into an exception check.
        # This suggests skipped[i] contains ``await``.
        if processed.kind != skipped[i].kind or processed.len != skipped[i].len:
          processed = processed.skipUntilStmtList()
          expectKind(processed, nnkStmtList)
          expectKind(processed[2][1], nnkElse)
          i.inc

          if not processForTry(n, i, processed[2][1][0]):
            # We need to wrap the nnkElse nodes back into a tryStmt.
            # As they are executed if an exception does not happen
            # inside the awaited future.
            # The following code will wrap the nodes inside the
            # original tryStmt.
            wrapInTry(n, processed[2][1][0])

          res.add processed
          result = true
        else:
          res.add skipped[i]
          i.inc
    var i = 0
    if not processForTry(node, i, result):
      # If the tryStmt hasn't been transformed we can just put the body
      # back into it.
      wrapInTry(node, result)
    return
  else: discard

  for i in 0 .. <result.len:
    result[i] = processBody(result[i], retFutureSym, subTypeIsVoid, nil)

proc getName(node: NimNode): string {.compileTime.} =
  case node.kind
  of nnkPostfix:
    return $node[1].ident
  of nnkIdent:
    return $node.ident
  of nnkEmpty:
    return "anonymous"
  else:
    error("Unknown name.")

proc asyncSingleProc(prc: NimNode): NimNode {.compileTime.} =
  ## This macro transforms a single procedure into a closure iterator.
  ## The ``async`` macro supports a stmtList holding multiple async procedures.
  if prc.kind notin {nnkProcDef, nnkLambda}:
      error("Cannot transform this node kind into an async proc." &
            " Proc definition or lambda node expected.")

  hint("Processing " & prc[0].getName & " as an async proc.")

  let returnType = prc[3][0]
  var baseType: NimNode
  # Verify that the return type is a Future[T]
  if returnType.kind == nnkBracketExpr:
    let fut = repr(returnType[0])
    if fut != "Future":
      error("Expected return type of 'Future' got '" & fut & "'")
    baseType = returnType[1]
  elif returnType.kind in nnkCallKinds and $returnType[0] == "[]":
    let fut = repr(returnType[1])
    if fut != "Future":
      error("Expected return type of 'Future' got '" & fut & "'")
    baseType = returnType[2]
  elif returnType.kind == nnkEmpty:
    baseType = returnType
  else:
    error("Expected return type of 'Future' got '" & repr(returnType) & "'")

  let subtypeIsVoid = returnType.kind == nnkEmpty or
        (baseType.kind == nnkIdent and returnType[1].ident == !"void")

  var outerProcBody = newNimNode(nnkStmtList, prc[6])

  # -> var retFuture = newFuture[T]()
  var retFutureSym = genSym(nskVar, "retFuture")
  var subRetType =
    if returnType.kind == nnkEmpty: newIdentNode("void")
    else: baseType
  outerProcBody.add(
    newVarStmt(retFutureSym,
      newCall(
        newNimNode(nnkBracketExpr, prc[6]).add(
          newIdentNode(!"newFuture"), # TODO: Strange bug here? Remove the `!`.
          subRetType),
      newLit(prc[0].getName)))) # Get type from return type of this proc

  # -> iterator nameIter(): FutureBase {.closure.} =
  # ->   {.push warning[resultshadowed]: off.}
  # ->   var result: T
  # ->   {.pop.}
  # ->   <proc_body>
  # ->   complete(retFuture, result)
  var iteratorNameSym = genSym(nskIterator, $prc[0].getName & "Iter")
  var procBody = prc[6].processBody(retFutureSym, subtypeIsVoid, nil)
  if not subtypeIsVoid:
    procBody.insert(0, newNimNode(nnkPragma).add(newIdentNode("push"),
      newNimNode(nnkExprColonExpr).add(newNimNode(nnkBracketExpr).add(
        newIdentNode("warning"), newIdentNode("resultshadowed")),
      newIdentNode("off")))) # -> {.push warning[resultshadowed]: off.}

    procBody.insert(1, newNimNode(nnkVarSection, prc[6]).add(
      newIdentDefs(newIdentNode("result"), baseType))) # -> var result: T

    procBody.insert(2, newNimNode(nnkPragma).add(
      newIdentNode("pop"))) # -> {.pop.})

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
  #var cbName = newIdentNode("cb")
  var procCb = newCall(bindSym"createCb", retFutureSym, iteratorNameSym,
                       newStrLitNode(prc[0].getName))
  outerProcBody.add procCb

  # -> return retFuture
  outerProcBody.add newNimNode(nnkReturnStmt, prc[6][prc[6].len-1]).add(retFutureSym)

  result = prc

  # Remove the 'async' pragma.
  for i in 0 .. <result[4].len:
    if result[4][i].kind == nnkIdent and result[4][i].ident == !"async":
      result[4].del(i)
  result[4] = newEmptyNode()
  if subtypeIsVoid:
    # Add discardable pragma.
    if returnType.kind == nnkEmpty:
      # Add Future[void]
      result[3][0] = parseExpr("Future[void]")

  result[6] = outerProcBody

  #echo(treeRepr(result))
  #if prc[0].getName == "testInfix":
  #  echo(toStrLit(result))

macro async*(prc: stmt): stmt {.immediate.} =
  ## Macro which processes async procedures into the appropriate
  ## iterators and yield statements.
  if prc.kind == nnkStmtList:
    for oneProc in prc:
      result = newStmtList()
      result.add asyncSingleProc(oneProc)
  else:
    result = asyncSingleProc(prc)

proc recvLine*(socket: AsyncFD): Future[string] {.async.} =
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
  ## **Warning**: This assumes that lines are delimited by ``\r\L``.
  ##
  ## **Note**: This procedure is mostly used for testing. You likely want to
  ## use ``asyncnet.recvLine`` instead.

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
      c = await recv(socket, 1)
      assert c == "\l"
      addNLIfEmpty()
      return
    elif c == "\L":
      addNLIfEmpty()
      return
    add(result, c)

proc callSoon*(cbproc: proc ()) =
  ## Schedule `cbproc` to be called as soon as possible.
  ## The callback is called when control returns to the event loop.
  getGlobalDispatcher().callbacks.enqueue(cbproc)

proc runForever*() =
  ## Begins a never ending global dispatcher poll loop.
  while true:
    poll()

proc waitFor*[T](fut: Future[T]): T =
  ## **Blocks** the current thread until the specified future completes.
  while not fut.finished:
    poll()

  fut.read
