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

  var lastException: ref Exception
  var curAddrInfo = addrInfo
  when shouldCreateFd:
    var curFd: AsyncFD
  else:
    var curFd = fd
  proc tryNextAddrInfo(fut: Future[void]) {.gcsafe.} =
    if fut == nil or fut.failed:
      if fut != nil:
        lastException = fut.readError()
        when shouldCreateFd:
          curFd.closeSocket()

      var domain: Domain
      while curAddrInfo != nil:
        let domainOpt = curAddrInfo.ai_family.toKnownDomain()
        if domainOpt.isSome:
          domain = domainOpt.unsafeGet()
          break
        curAddrInfo = curAddrInfo.ai_next

      if curAddrInfo == nil:
        freeAddrInfo(addrInfo)
        if lastException != nil:
          retFuture.fail(lastException)
        else:
          retFuture.fail(newException(
            IOError, "Couldn't resolve hostname: " & address))
        return

      when shouldCreateFd:
        curFd = newAsyncNativeSocket(domain, sockType, protocol)
        when defined(windows):
          curFd.SocketHandle.bindToDomain(domain)
      doConnect(curFd, curAddrInfo).callback = tryNextAddrInfo
      curAddrInfo = curAddrInfo.ai_next
    else:
      freeAddrInfo(addrInfo)
      when shouldCreateFd:
        retFuture.complete(curFd)
      else:
        retFuture.complete()

  tryNextAddrInfo(nil)

proc dial*(address: string, port: Port,
           protocol: Protocol = IPPROTO_TCP): Future[AsyncFD] =
  ## Establishes connection to the specified address:port pair via the
  ## specified protocol.
  ## Returns the async file descriptor, registered in the dispatcher of
  ## the current thread
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
  assert getSockDomain(socket.SocketHandle) == domain

  let aiList = getAddrInfo(address, port, domain)
  when defined(windows):
    socket.SocketHandle.bindToDomain(domain)
  asyncAddrInfoLoop(aiList, socket)
