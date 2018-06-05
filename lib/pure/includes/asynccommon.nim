template createAsyncNativeSocketImpl(domain, sockType, protocol) =
  let handle = newNativeSocket(domain, sockType, protocol)
  if handle == osInvalidSocket:
    return osInvalidSocket.AsyncFD
  handle.setBlocking(false)
  when defined(macosx) and not defined(nimdoc):
    handle.setSockOptInt(SOL_SOCKET, SO_NOSIGPIPE, 1)
  result = handle.AsyncFD
  register(result)

proc createAsyncNativeSocket*(domain: cint, sockType: cint,
                           protocol: cint): AsyncFD =
  createAsyncNativeSocketImpl(domain, sockType, protocol)

proc createAsyncNativeSocket*(domain: Domain = Domain.AF_INET,
                           sockType: SockType = SOCK_STREAM,
                           protocol: Protocol = IPPROTO_TCP): AsyncFD =
  createAsyncNativeSocketImpl(domain, sockType, protocol)

proc newAsyncNativeSocket*(domain: cint, sockType: cint,
                           protocol: cint): AsyncFD {.deprecated: "use createAsyncNativeSocket instead".} =
  createAsyncNativeSocketImpl(domain, sockType, protocol)

proc newAsyncNativeSocket*(domain: Domain = Domain.AF_INET,
                           sockType: SockType = SOCK_STREAM,
                           protocol: Protocol = IPPROTO_TCP): AsyncFD
                           {.deprecated: "use createAsyncNativeSocket instead".} =
  createAsyncNativeSocketImpl(domain, sockType, protocol)

when defined(windows) or defined(nimdoc):
  proc bindToDomain(handle: SocketHandle, domain: Domain) =
    # Extracted into a separate proc, because connect() on Windows requires
    # the socket to be initially bound.
    template doBind(saddr) =
      if bindAddr(handle, cast[ptr SockAddr](addr(saddr)),
                  sizeof(saddr).SockLen) < 0'i32:
        raiseOSError(osLastError())

    if domain == Domain.AF_INET6:
      var saddr: Sockaddr_in6
      saddr.sin6_family = int16(toInt(domain))
      doBind(saddr)
    else:
      var saddr: Sockaddr_in
      saddr.sin_family = int16(toInt(domain))
      doBind(saddr)

  proc doConnect(socket: AsyncFD, addrInfo: ptr AddrInfo): Future[void] =
    let retFuture = newFuture[void]("doConnect")
    result = retFuture

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

    let ret = connectEx(socket.SocketHandle, addrInfo.ai_addr,
                        cint(addrInfo.ai_addrlen), nil, 0, nil,
                        cast[POVERLAPPED](ol))
    if ret:
      # Request to connect completed immediately.
      retFuture.complete()
      # We don't deallocate ``ol`` here because even though this completed
      # immediately poll will still be notified about its completion and it
      # will free ``ol``.
    else:
      let lastError = osLastError()
      if lastError.int32 != ERROR_IO_PENDING:
        # With ERROR_IO_PENDING ``ol`` will be deallocated in ``poll``,
        # and the future will be completed/failed there, too.
        GC_unref(ol)
        retFuture.fail(newException(OSError, osErrorMsg(lastError)))
else:
  proc doConnect(socket: AsyncFD, addrInfo: ptr AddrInfo): Future[void] =
    let retFuture = newFuture[void]("doConnect")
    result = retFuture

    proc cb(fd: AsyncFD): bool =
      let ret = SocketHandle(fd).getSockOptInt(
        cint(SOL_SOCKET), cint(SO_ERROR))
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

    let ret = connect(socket.SocketHandle,
                      addrInfo.ai_addr,
                      addrInfo.ai_addrlen.Socklen)
    if ret == 0:
      # Request to connect completed immediately.
      retFuture.complete()
    else:
      let lastError = osLastError()
      if lastError.int32 == EINTR or lastError.int32 == EINPROGRESS:
        addWrite(socket, cb)
      else:
        retFuture.fail(newException(OSError, osErrorMsg(lastError)))

template asyncAddrInfoLoop(addrInfo: ptr AddrInfo, fd: untyped,
                           protocol: Protocol = IPPROTO_RAW) =
  ## Iterates through the AddrInfo linked list asynchronously
  ## until the connection can be established.
  const shouldCreateFd = not declared(fd)

  when shouldCreateFd:
    let sockType = protocol.toSockType()

    var fdPerDomain: array[low(Domain).ord..high(Domain).ord, AsyncFD]
    for i in low(fdPerDomain)..high(fdPerDomain):
      fdPerDomain[i] = osInvalidSocket.AsyncFD
    template closeUnusedFds(domainToKeep = -1) {.dirty.} =
      for i, fd in fdPerDomain:
        if fd != osInvalidSocket.AsyncFD and i != domainToKeep:
          fd.closeSocket()

  var lastException: ref Exception
  var curAddrInfo = addrInfo
  var domain: Domain
  when shouldCreateFd:
    var curFd: AsyncFD
  else:
    var curFd = fd
  proc tryNextAddrInfo(fut: Future[void]) {.gcsafe.} =
    if fut == nil or fut.failed:
      if fut != nil:
        lastException = fut.readError()

      while curAddrInfo != nil:
        let domainOpt = curAddrInfo.ai_family.toKnownDomain()
        if domainOpt.isSome:
          domain = domainOpt.unsafeGet()
          break
        curAddrInfo = curAddrInfo.ai_next

      if curAddrInfo == nil:
        freeAddrInfo(addrInfo)
        when shouldCreateFd:
          closeUnusedFds()
        if lastException != nil:
          retFuture.fail(lastException)
        else:
          retFuture.fail(newException(
            IOError, "Couldn't resolve address: " & address))
        return

      when shouldCreateFd:
        curFd = fdPerDomain[ord(domain)]
        if curFd == osInvalidSocket.AsyncFD:
          try:
            curFd = newAsyncNativeSocket(domain, sockType, protocol)
          except:
            freeAddrInfo(addrInfo)
            closeUnusedFds()
            raise getCurrentException()
          when defined(windows):
            curFd.SocketHandle.bindToDomain(domain)
          fdPerDomain[ord(domain)] = curFd

      doConnect(curFd, curAddrInfo).callback = tryNextAddrInfo
      curAddrInfo = curAddrInfo.ai_next
    else:
      freeAddrInfo(addrInfo)
      when shouldCreateFd:
        closeUnusedFds(ord(domain))
        retFuture.complete(curFd)
      else:
        retFuture.complete()

  tryNextAddrInfo(nil)

proc dial*(address: string, port: Port,
           protocol: Protocol = IPPROTO_TCP): Future[AsyncFD] =
  ## Establishes connection to the specified ``address``:``port`` pair via the
  ## specified protocol. The procedure iterates through possible
  ## resolutions of the ``address`` until it succeeds, meaning that it
  ## seamlessly works with both IPv4 and IPv6.
  ## Returns the async file descriptor, registered in the dispatcher of
  ## the current thread, ready to send or receive data.
  let retFuture = newFuture[AsyncFD]("dial")
  result = retFuture
  let sockType = protocol.toSockType()

  let aiList = getAddrInfo(address, port, Domain.AF_UNSPEC, sockType, protocol)
  asyncAddrInfoLoop(aiList, noFD, protocol)

proc connect*(socket: AsyncFD, address: string, port: Port,
              domain = Domain.AF_INET): Future[void] =
  let retFuture = newFuture[void]("connect")
  result = retFuture

  when defined(windows):
    verifyPresence(socket)
  else:
    assert getSockDomain(socket.SocketHandle) == domain

  let aiList = getAddrInfo(address, port, domain)
  when defined(windows):
    socket.SocketHandle.bindToDomain(domain)
  asyncAddrInfoLoop(aiList, socket)
