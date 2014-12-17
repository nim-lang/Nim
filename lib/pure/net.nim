#
#
#            Nim's Runtime Library
#        (c) Copyright 2014 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a high-level cross-platform sockets interface.

{.deadCodeElim: on.}
import rawsockets, os, strutils, unsigned, parseutils, times
export Port, `$`, `==`

const useWinVersion = defined(Windows) or defined(nimdoc)

when defined(ssl):
  import openssl

# Note: The enumerations are mapped to Window's constants.

when defined(ssl):
  type
    SslError* = object of Exception

    SslCVerifyMode* = enum
      CVerifyNone, CVerifyPeer
    
    SslProtVersion* = enum
      protSSLv2, protSSLv3, protTLSv1, protSSLv23
    
    SslContext* = distinct SslCtx

    SslAcceptResult* = enum
      AcceptNoClient = 0, AcceptNoHandshake, AcceptSuccess

  {.deprecated: [ESSL: SSLError, TSSLCVerifyMode: SSLCVerifyMode,
    TSSLProtVersion: SSLProtVersion, PSSLContext: SSLContext,
    TSSLAcceptResult: SSLAcceptResult].}

const
  BufferSize*: int = 4000 ## size of a buffered socket's buffer

type
  SocketImpl* = object ## socket type
    fd*: SocketHandle
    case isBuffered*: bool # determines whether this socket is buffered.
    of true:
      buffer*: array[0..BufferSize, char]
      currPos*: int # current index in buffer
      bufLen*: int # current length of buffer
    of false: nil
    when defined(ssl):
      case isSsl*: bool
      of true:
        sslHandle*: SSLPtr
        sslContext*: SSLContext
        sslNoHandshake*: bool # True if needs handshake.
        sslHasPeekChar*: bool
        sslPeekChar*: char
      of false: nil
  
  Socket* = ref SocketImpl

  SOBool* = enum ## Boolean socket options.
    OptAcceptConn, OptBroadcast, OptDebug, OptDontRoute, OptKeepAlive,
    OptOOBInline, OptReuseAddr

  ReadLineResult* = enum ## result for readLineAsync
    ReadFullLine, ReadPartialLine, ReadDisconnected, ReadNone

  TimeoutError* = object of Exception

  SocketFlag* {.pure.} = enum
    Peek,
    SafeDisconn ## Ensures disconnection exceptions (ECONNRESET, EPIPE etc) are not thrown.

{.deprecated: [TSocketFlags: SocketFlag, ETimeout: TimeoutError,
    TReadLineResult: ReadLineResult, TSOBool: SOBool, PSocket: Socket,
    TSocketImpl: SocketImpl].}

proc isDisconnectionError*(flags: set[SocketFlag],
    lastError: OSErrorCode): bool =
  ## Determines whether ``lastError`` is a disconnection error. Only does this
  ## if flags contains ``SafeDisconn``.
  when useWinVersion:
    SocketFlag.SafeDisconn in flags and
      lastError.int32 in {WSAECONNRESET, WSAECONNABORTED, WSAENETRESET,
                          WSAEDISCON, ERROR_NETNAME_DELETED}
  else:
    SocketFlag.SafeDisconn in flags and
      lastError.int32 in {ECONNRESET, EPIPE, ENETRESET} 

proc toOSFlags*(socketFlags: set[SocketFlag]): cint =
  ## Converts the flags into the underlying OS representation.
  for f in socketFlags:
    case f
    of SocketFlag.Peek:
      result = result or MSG_PEEK
    of SocketFlag.SafeDisconn: continue

proc createSocket(fd: SocketHandle, isBuff: bool): Socket =
  assert fd != osInvalidSocket
  new(result)
  result.fd = fd
  result.isBuffered = isBuff
  if isBuff:
    result.currPos = 0

proc newSocket*(domain, typ, protocol: cint, buffered = true): Socket =
  ## Creates a new socket.
  ##
  ## If an error occurs EOS will be raised.
  let fd = newRawSocket(domain, typ, protocol)
  if fd == osInvalidSocket:
    raiseOSError(osLastError())
  result = createSocket(fd, buffered)

proc newSocket*(domain: Domain = AF_INET, typ: SockType = SOCK_STREAM,
             protocol: Protocol = IPPROTO_TCP, buffered = true): Socket =
  ## Creates a new socket.
  ##
  ## If an error occurs EOS will be raised.
  let fd = newRawSocket(domain, typ, protocol)
  if fd == osInvalidSocket:
    raiseOSError(osLastError())
  result = createSocket(fd, buffered)

when defined(ssl):
  CRYPTO_malloc_init()
  SslLibraryInit()
  SslLoadErrorStrings()
  ErrLoadBioStrings()
  OpenSSL_add_all_algorithms()

  proc raiseSSLError*(s = "") =
    ## Raises a new SSL error.
    if s != "":
      raise newException(SSLError, s)
    let err = ErrPeekLastError()
    if err == 0:
      raise newException(SSLError, "No error reported.")
    if err == -1:
      raiseOSError(osLastError())
    var errStr = ErrErrorString(err, nil)
    raise newException(SSLError, $errStr)

  # http://simplestcodings.blogspot.co.uk/2010/08/secure-server-client-using-openssl-in-c.html
  proc loadCertificates(ctx: SSL_CTX, certFile, keyFile: string) =
    if certFile != "" and not existsFile(certFile):
      raise newException(system.IOError, "Certificate file could not be found: " & certFile)
    if keyFile != "" and not existsFile(keyFile):
      raise newException(system.IOError, "Key file could not be found: " & keyFile)
    
    if certFile != "":
      var ret = SSLCTXUseCertificateChainFile(ctx, certFile)
      if ret != 1:
        raiseSSLError()
    
    # TODO: Password? www.rtfm.com/openssl-examples/part1.pdf
    if keyFile != "":
      if SSL_CTX_use_PrivateKey_file(ctx, keyFile,
                                     SSL_FILETYPE_PEM) != 1:
        raiseSSLError()
        
      if SSL_CTX_check_private_key(ctx) != 1:
        raiseSSLError("Verification of private key file failed.")

  proc newContext*(protVersion = protSSLv23, verifyMode = CVerifyPeer,
                   certFile = "", keyFile = ""): SSLContext =
    ## Creates an SSL context.
    ## 
    ## Protocol version specifies the protocol to use. SSLv2, SSLv3, TLSv1 
    ## are available with the addition of ``protSSLv23`` which allows for 
    ## compatibility with all of them.
    ##
    ## There are currently only two options for verify mode;
    ## one is ``CVerifyNone`` and with it certificates will not be verified
    ## the other is ``CVerifyPeer`` and certificates will be verified for
    ## it, ``CVerifyPeer`` is the safest choice.
    ##
    ## The last two parameters specify the certificate file path and the key file
    ## path, a server socket will most likely not work without these.
    ## Certificates can be generated using the following command:
    ## ``openssl req -x509 -nodes -days 365 -newkey rsa:1024 -keyout mycert.pem -out mycert.pem``.
    var newCTX: SSL_CTX
    case protVersion
    of protSSLv23:
      newCTX = SSL_CTX_new(SSLv23_method()) # SSlv2,3 and TLS1 support.
    of protSSLv2:
      when not defined(linux):
        newCTX = SSL_CTX_new(SSLv2_method())
      else:
        raiseSslError()
    of protSSLv3:
      newCTX = SSL_CTX_new(SSLv3_method())
    of protTLSv1:
      newCTX = SSL_CTX_new(TLSv1_method())
    
    if newCTX.SSLCTXSetCipherList("ALL") != 1:
      raiseSSLError()
    case verifyMode
    of CVerifyPeer:
      newCTX.SSLCTXSetVerify(SSLVerifyPeer, nil)
    of CVerifyNone:
      newCTX.SSLCTXSetVerify(SSLVerifyNone, nil)
    if newCTX == nil:
      raiseSSLError()

    discard newCTX.SSLCTXSetMode(SSL_MODE_AUTO_RETRY)
    newCTX.loadCertificates(certFile, keyFile)
    return SSLContext(newCTX)

  proc wrapSocket*(ctx: SSLContext, socket: Socket) =
    ## Wraps a socket in an SSL context. This function effectively turns
    ## ``socket`` into an SSL socket.
    ##
    ## **Disclaimer**: This code is not well tested, may be very unsafe and
    ## prone to security vulnerabilities.
    
    socket.isSSL = true
    socket.sslContext = ctx
    socket.sslHandle = SSLNew(SSLCTX(socket.sslContext))
    socket.sslNoHandshake = false
    socket.sslHasPeekChar = false
    if socket.sslHandle == nil:
      raiseSSLError()
    
    if SSLSetFd(socket.sslHandle, socket.fd) != 1:
      raiseSSLError()

proc socketError*(socket: Socket, err: int = -1, async = false,
                  lastError = (-1).OSErrorCode) =
  ## Raises an OSError based on the error code returned by ``SSLGetError``
  ## (for SSL sockets) and ``osLastError`` otherwise.
  ##
  ## If ``async`` is ``true`` no error will be thrown in the case when the
  ## error was caused by no data being available to be read.
  ##
  ## If ``err`` is not lower than 0 no exception will be raised.
  when defined(ssl):
    if socket.isSSL:
      if err <= 0:
        var ret = SSLGetError(socket.sslHandle, err.cint)
        case ret
        of SSL_ERROR_ZERO_RETURN:
          raiseSSLError("TLS/SSL connection failed to initiate, socket closed prematurely.")
        of SSL_ERROR_WANT_CONNECT, SSL_ERROR_WANT_ACCEPT:
          if async:
            return
          else: raiseSSLError("Not enough data on socket.")
        of SSL_ERROR_WANT_WRITE, SSL_ERROR_WANT_READ:
          if async:
            return
          else: raiseSSLError("Not enough data on socket.")
        of SSL_ERROR_WANT_X509_LOOKUP:
          raiseSSLError("Function for x509 lookup has been called.")
        of SSL_ERROR_SYSCALL:
          var errStr = "IO error has occured "
          let sslErr = ErrPeekLastError()
          if sslErr == 0 and err == 0:
            errStr.add "because an EOF was observed that violates the protocol"
          elif sslErr == 0 and err == -1:
            errStr.add "in the BIO layer"
          else:
            let errStr = $ErrErrorString(sslErr, nil)
            raiseSSLError(errStr & ": " & errStr)
          let osMsg = osErrorMsg osLastError()
          if osMsg != "":
            errStr.add ". The OS reports: " & osMsg
          raise newException(OSError, errStr)
        of SSL_ERROR_SSL:
          raiseSSLError()
        else: raiseSSLError("Unknown Error")
  
  if err == -1 and not (when defined(ssl): socket.isSSL else: false):
    let lastE = if lastError.int == -1: osLastError() else: lastError
    if async:
      when useWinVersion:
        if lastE.int32 == WSAEWOULDBLOCK:
          return
        else: raiseOSError(lastE)
      else:
        if lastE.int32 == EAGAIN or lastE.int32 == EWOULDBLOCK:
          return
        else: raiseOSError(lastE)
    else: raiseOSError(lastE)

proc listen*(socket: Socket, backlog = SOMAXCONN) {.tags: [ReadIOEffect].} =
  ## Marks ``socket`` as accepting connections. 
  ## ``Backlog`` specifies the maximum length of the 
  ## queue of pending connections.
  ##
  ## Raises an EOS error upon failure.
  if listen(socket.fd, backlog) < 0'i32: raiseOSError(osLastError())

proc bindAddr*(socket: Socket, port = Port(0), address = "") {.
  tags: [ReadIOEffect].} =
  ## Binds ``address``:``port`` to the socket.
  ##
  ## If ``address`` is "" then ADDR_ANY will be bound.

  if address == "":
    var name: Sockaddr_in
    when useWinVersion:
      name.sin_family = toInt(AF_INET).int16
    else:
      name.sin_family = toInt(AF_INET)
    name.sin_port = htons(int16(port))
    name.sin_addr.s_addr = htonl(INADDR_ANY)
    if bindAddr(socket.fd, cast[ptr SockAddr](addr(name)),
                  sizeof(name).SockLen) < 0'i32:
      raiseOSError(osLastError())
  else:
    var aiList = getAddrInfo(address, port, AF_INET)
    if bindAddr(socket.fd, aiList.ai_addr, aiList.ai_addrlen.SockLen) < 0'i32:
      dealloc(aiList)
      raiseOSError(osLastError())
    dealloc(aiList)

proc acceptAddr*(server: Socket, client: var Socket, address: var string,
                 flags = {SocketFlag.SafeDisconn}) {.tags: [ReadIOEffect].} =
  ## Blocks until a connection is being made from a client. When a connection
  ## is made sets ``client`` to the client socket and ``address`` to the address
  ## of the connecting client.
  ## This function will raise EOS if an error occurs.
  ##
  ## The resulting client will inherit any properties of the server socket. For
  ## example: whether the socket is buffered or not.
  ##
  ## **Note**: ``client`` must be initialised (with ``new``), this function 
  ## makes no effort to initialise the ``client`` variable.
  ##
  ## The ``accept`` call may result in an error if the connecting socket
  ## disconnects during the duration of the ``accept``. If the ``SafeDisconn``
  ## flag is specified then this error will not be raised and instead
  ## accept will be called again.
  assert(client != nil)
  var sockAddress: Sockaddr_in
  var addrLen = sizeof(sockAddress).SockLen
  var sock = accept(server.fd, cast[ptr SockAddr](addr(sockAddress)),
                    addr(addrLen))
  
  if sock == osInvalidSocket:
    let err = osLastError()
    if flags.isDisconnectionError(err):
      acceptAddr(server, client, address, flags)
    raiseOSError(err)
  else:
    client.fd = sock
    client.isBuffered = server.isBuffered

    # Handle SSL.
    when defined(ssl):
      if server.isSSL:
        # We must wrap the client sock in a ssl context.
        
        server.sslContext.wrapSocket(client)
        let ret = SSLAccept(client.sslHandle)
        socketError(client, ret, false)
    
    # Client socket is set above.
    address = $inet_ntoa(sockAddress.sin_addr)

when false: #defined(ssl):
  proc acceptAddrSSL*(server: Socket, client: var Socket,
                      address: var string): TSSLAcceptResult {.
                      tags: [ReadIOEffect].} =
    ## This procedure should only be used for non-blocking **SSL** sockets. 
    ## It will immediately return with one of the following values:
    ## 
    ## ``AcceptSuccess`` will be returned when a client has been successfully
    ## accepted and the handshake has been successfully performed between
    ## ``server`` and the newly connected client.
    ##
    ## ``AcceptNoHandshake`` will be returned when a client has been accepted
    ## but no handshake could be performed. This can happen when the client
    ## connects but does not yet initiate a handshake. In this case
    ## ``acceptAddrSSL`` should be called again with the same parameters.
    ##
    ## ``AcceptNoClient`` will be returned when no client is currently attempting
    ## to connect.
    template doHandshake(): stmt =
      when defined(ssl):
        if server.isSSL:
          client.setBlocking(false)
          # We must wrap the client sock in a ssl context.
          
          if not client.isSSL or client.sslHandle == nil:
            server.sslContext.wrapSocket(client)
          let ret = SSLAccept(client.sslHandle)
          while ret <= 0:
            let err = SSLGetError(client.sslHandle, ret)
            if err != SSL_ERROR_WANT_ACCEPT:
              case err
              of SSL_ERROR_ZERO_RETURN:
                raiseSSLError("TLS/SSL connection failed to initiate, socket closed prematurely.")
              of SSL_ERROR_WANT_READ, SSL_ERROR_WANT_WRITE,
                 SSL_ERROR_WANT_CONNECT, SSL_ERROR_WANT_ACCEPT:
                client.sslNoHandshake = true
                return AcceptNoHandshake
              of SSL_ERROR_WANT_X509_LOOKUP:
                raiseSSLError("Function for x509 lookup has been called.")
              of SSL_ERROR_SYSCALL, SSL_ERROR_SSL:
                raiseSSLError()
              else:
                raiseSSLError("Unknown error")
          client.sslNoHandshake = false

    if client.isSSL and client.sslNoHandshake:
      doHandshake()
      return AcceptSuccess
    else:
      acceptAddrPlain(AcceptNoClient, AcceptSuccess):
        doHandshake()

proc accept*(server: Socket, client: var Socket,
             flags = {SocketFlag.SafeDisconn}) {.tags: [ReadIOEffect].} =
  ## Equivalent to ``acceptAddr`` but doesn't return the address, only the
  ## socket.
  ## 
  ## **Note**: ``client`` must be initialised (with ``new``), this function
  ## makes no effort to initialise the ``client`` variable.
  ##
  ## The ``accept`` call may result in an error if the connecting socket
  ## disconnects during the duration of the ``accept``. If the ``SafeDisconn``
  ## flag is specified then this error will not be raised and instead
  ## accept will be called again.
  var addrDummy = ""
  acceptAddr(server, client, addrDummy, flags)

proc close*(socket: Socket) =
  ## Closes a socket.
  when defined(ssl):
    if socket.isSSL:
      ErrClearError()
      # As we are closing the underlying socket immediately afterwards,
      # it is valid, under the TLS standard, to perform a unidirectional
      # shutdown i.e not wait for the peers "close notify" alert with a second
      # call to SSLShutdown
      let res = SSLShutdown(socket.sslHandle)
      if res == 0:
        discard
      elif res != 1:
        socketError(socket, res)
  socket.fd.close()

proc toCInt*(opt: SOBool): cint =
  ## Converts a ``SOBool`` into its Socket Option cint representation.
  case opt
  of OptAcceptConn: SO_ACCEPTCONN
  of OptBroadcast: SO_BROADCAST
  of OptDebug: SO_DEBUG
  of OptDontRoute: SO_DONTROUTE
  of OptKeepAlive: SO_KEEPALIVE
  of OptOOBInline: SO_OOBINLINE
  of OptReuseAddr: SO_REUSEADDR

proc getSockOpt*(socket: Socket, opt: SOBool, level = SOL_SOCKET): bool {.
  tags: [ReadIOEffect].} =
  ## Retrieves option ``opt`` as a boolean value.
  var res = getSockOptInt(socket.fd, cint(level), toCInt(opt))
  result = res != 0

proc setSockOpt*(socket: Socket, opt: SOBool, value: bool, level = SOL_SOCKET) {.
  tags: [WriteIOEffect].} =
  ## Sets option ``opt`` to a boolean value specified by ``value``.
  var valuei = cint(if value: 1 else: 0)
  setSockOptInt(socket.fd, cint(level), toCInt(opt), valuei)

proc connect*(socket: Socket, address: string, port = Port(0), 
              af: Domain = AF_INET) {.tags: [ReadIOEffect].} =
  ## Connects socket to ``address``:``port``. ``Address`` can be an IP address or a
  ## host name. If ``address`` is a host name, this function will try each IP
  ## of that host name. ``htons`` is already performed on ``port`` so you must
  ## not do it.
  ##
  ## If ``socket`` is an SSL socket a handshake will be automatically performed.
  var aiList = getAddrInfo(address, port, af)
  # try all possibilities:
  var success = false
  var lastError: OSErrorCode
  var it = aiList
  while it != nil:
    if connect(socket.fd, it.ai_addr, it.ai_addrlen.SockLen) == 0'i32:
      success = true
      break
    else: lastError = osLastError()
    it = it.ai_next

  dealloc(aiList)
  if not success: raiseOSError(lastError)
  
  when defined(ssl):
    if socket.isSSL:
      let ret = SSLConnect(socket.sslHandle)
      socketError(socket, ret)

when defined(ssl):
  proc handshake*(socket: Socket): bool {.tags: [ReadIOEffect, WriteIOEffect].} =
    ## This proc needs to be called on a socket after it connects. This is
    ## only applicable when using ``connectAsync``.
    ## This proc performs the SSL handshake.
    ##
    ## Returns ``False`` whenever the socket is not yet ready for a handshake,
    ## ``True`` whenever handshake completed successfully.
    ##
    ## A ESSL error is raised on any other errors.
    result = true
    if socket.isSSL:
      var ret = SSLConnect(socket.sslHandle)
      if ret <= 0:
        var errret = SSLGetError(socket.sslHandle, ret)
        case errret
        of SSL_ERROR_ZERO_RETURN:
          raiseSSLError("TLS/SSL connection failed to initiate, socket closed prematurely.")
        of SSL_ERROR_WANT_CONNECT, SSL_ERROR_WANT_ACCEPT,
          SSL_ERROR_WANT_READ, SSL_ERROR_WANT_WRITE:
          return false
        of SSL_ERROR_WANT_X509_LOOKUP:
          raiseSSLError("Function for x509 lookup has been called.")
        of SSL_ERROR_SYSCALL, SSL_ERROR_SSL:
          raiseSSLError()
        else:
          raiseSSLError("Unknown Error")
      socket.sslNoHandshake = false
    else:
      raiseSSLError("Socket is not an SSL socket.")

  proc gotHandshake*(socket: Socket): bool =
    ## Determines whether a handshake has occurred between a client (``socket``)
    ## and the server that ``socket`` is connected to.
    ##
    ## Throws ESSL if ``socket`` is not an SSL socket.
    if socket.isSSL:
      return not socket.sslNoHandshake
    else:
      raiseSSLError("Socket is not an SSL socket.")

proc hasDataBuffered*(s: Socket): bool =
  ## Determines whether a socket has data buffered.
  result = false
  if s.isBuffered:
    result = s.bufLen > 0 and s.currPos != s.bufLen

  when defined(ssl):
    if s.isSSL and not result:
      result = s.sslHasPeekChar

proc select(readfd: Socket, timeout = 500): int =
  ## Used for socket operation timeouts.
  if readfd.hasDataBuffered:
    return 1

  var fds = @[readfd.fd]
  result = select(fds, timeout)

proc readIntoBuf(socket: Socket, flags: int32): int =
  result = 0
  when defined(ssl):
    if socket.isSSL:
      result = SSLRead(socket.sslHandle, addr(socket.buffer), int(socket.buffer.high))
    else:
      result = recv(socket.fd, addr(socket.buffer), cint(socket.buffer.high), flags)
  else:
    result = recv(socket.fd, addr(socket.buffer), cint(socket.buffer.high), flags)
  if result <= 0:
    socket.bufLen = 0
    socket.currPos = 0
    return result
  socket.bufLen = result
  socket.currPos = 0

template retRead(flags, readBytes: int) {.dirty.} =
  let res = socket.readIntoBuf(flags.int32)
  if res <= 0:
    if readBytes > 0:
      return readBytes
    else:
      return res

proc recv*(socket: Socket, data: pointer, size: int): int {.tags: [ReadIOEffect].} =
  ## Receives data from a socket.
  ##
  ## **Note**: This is a low-level function, you may be interested in the higher
  ## level versions of this function which are also named ``recv``.
  if size == 0: return
  if socket.isBuffered:
    if socket.bufLen == 0:
      retRead(0'i32, 0)
    
    var read = 0
    while read < size:
      if socket.currPos >= socket.bufLen:
        retRead(0'i32, read)
    
      let chunk = min(socket.bufLen-socket.currPos, size-read)
      var d = cast[cstring](data)
      assert size-read >= chunk
      copyMem(addr(d[read]), addr(socket.buffer[socket.currPos]), chunk)
      read.inc(chunk)
      socket.currPos.inc(chunk)

    result = read
  else:
    when defined(ssl):
      if socket.isSSL:
        if socket.sslHasPeekChar:
          copyMem(data, addr(socket.sslPeekChar), 1)
          socket.sslHasPeekChar = false
          if size-1 > 0:
            var d = cast[cstring](data)
            result = SSLRead(socket.sslHandle, addr(d[1]), size-1) + 1
          else:
            result = 1
        else:
          result = SSLRead(socket.sslHandle, data, size)
      else:
        result = recv(socket.fd, data, size.cint, 0'i32)
    else:
      result = recv(socket.fd, data, size.cint, 0'i32)

proc waitFor(socket: Socket, waited: var float, timeout, size: int,
             funcName: string): int {.tags: [TimeEffect].} =
  ## determines the amount of characters that can be read. Result will never
  ## be larger than ``size``. For unbuffered sockets this will be ``1``.
  ## For buffered sockets it can be as big as ``BufferSize``.
  ##
  ## If this function does not determine that there is data on the socket
  ## within ``timeout`` ms, an ETimeout error will be raised.
  result = 1
  if size <= 0: assert false
  if timeout == -1: return size
  if socket.isBuffered and socket.bufLen != 0 and socket.bufLen != socket.currPos:
    result = socket.bufLen - socket.currPos
    result = min(result, size)
  else:
    if timeout - int(waited * 1000.0) < 1:
      raise newException(TimeoutError, "Call to '" & funcName & "' timed out.")
    
    when defined(ssl):
      if socket.isSSL:
        if socket.hasDataBuffered:
          # sslPeekChar is present.
          return 1
        let sslPending = SSLPending(socket.sslHandle)
        if sslPending != 0:
          return sslPending
    
    var startTime = epochTime()
    let selRet = select(socket, timeout - int(waited * 1000.0))
    if selRet < 0: raiseOSError(osLastError())
    if selRet != 1:
      raise newException(TimeoutError, "Call to '" & funcName & "' timed out.")
    waited += (epochTime() - startTime)

proc recv*(socket: Socket, data: pointer, size: int, timeout: int): int {.
  tags: [ReadIOEffect, TimeEffect].} =
  ## overload with a ``timeout`` parameter in miliseconds.
  var waited = 0.0 # number of seconds already waited  
  
  var read = 0
  while read < size:
    let avail = waitFor(socket, waited, timeout, size-read, "recv")
    var d = cast[cstring](data)
    assert avail <= size-read
    result = recv(socket, addr(d[read]), avail)
    if result == 0: break
    if result < 0:
      return result
    inc(read, result)
  
  result = read

proc recv*(socket: Socket, data: var string, size: int, timeout = -1,
           flags = {SocketFlag.SafeDisconn}): int =
  ## Higher-level version of ``recv``.
  ##
  ## When 0 is returned the socket's connection has been closed.
  ##
  ## This function will throw an EOS exception when an error occurs. A value
  ## lower than 0 is never returned.
  ##
  ## A timeout may be specified in miliseconds, if enough data is not received
  ## within the time specified an ETimeout exception will be raised.
  ##
  ## **Note**: ``data`` must be initialised.
  ##
  ## **Warning**: Only the ``SafeDisconn`` flag is currently supported.
  data.setLen(size)
  result = recv(socket, cstring(data), size, timeout)
  if result < 0:
    data.setLen(0)
    let lastError = osLastError()
    if flags.isDisconnectionError(lastError): return
    socket.socketError(result, lastError = lastError)
  data.setLen(result)

proc peekChar(socket: Socket, c: var char): int {.tags: [ReadIOEffect].} =
  if socket.isBuffered:
    result = 1
    if socket.bufLen == 0 or socket.currPos > socket.bufLen-1:
      var res = socket.readIntoBuf(0'i32)
      if res <= 0:
        result = res
    
    c = socket.buffer[socket.currPos]
  else:
    when defined(ssl):
      if socket.isSSL:
        if not socket.sslHasPeekChar:
          result = SSLRead(socket.sslHandle, addr(socket.sslPeekChar), 1)
          socket.sslHasPeekChar = true
        
        c = socket.sslPeekChar
        return
    result = recv(socket.fd, addr(c), 1, MSG_PEEK)

proc readLine*(socket: Socket, line: var TaintedString, timeout = -1,
               flags = {SocketFlag.SafeDisconn}) {.
  tags: [ReadIOEffect, TimeEffect].} =
  ## Reads a line of data from ``socket``.
  ##
  ## If a full line is read ``\r\L`` is not
  ## added to ``line``, however if solely ``\r\L`` is read then ``line``
  ## will be set to it.
  ## 
  ## If the socket is disconnected, ``line`` will be set to ``""``.
  ##
  ## An EOS exception will be raised in the case of a socket error.
  ##
  ## A timeout can be specified in miliseconds, if data is not received within
  ## the specified time an ETimeout exception will be raised.
  ##
  ## **Warning**: Only the ``SafeDisconn`` flag is currently supported.
  
  template addNLIfEmpty(): stmt =
    if line.len == 0:
      line.add("\c\L")

  template raiseSockError(): stmt {.dirty, immediate.} =
    let lastError = osLastError()
    if flags.isDisconnectionError(lastError): setLen(line.string, 0); return
    socket.socketError(n, lastError = lastError)

  var waited = 0.0

  setLen(line.string, 0)
  while true:
    var c: char
    discard waitFor(socket, waited, timeout, 1, "readLine")
    var n = recv(socket, addr(c), 1)
    if n < 0: raiseSockError()
    elif n == 0: setLen(line.string, 0); return
    if c == '\r':
      discard waitFor(socket, waited, timeout, 1, "readLine")
      n = peekChar(socket, c)
      if n > 0 and c == '\L':
        discard recv(socket, addr(c), 1)
      elif n <= 0: raiseSockError()
      addNLIfEmpty()
      return
    elif c == '\L': 
      addNLIfEmpty()
      return
    add(line.string, c)

proc recvFrom*(socket: Socket, data: var string, length: int,
               address: var string, port: var Port, flags = 0'i32): int {.
               tags: [ReadIOEffect].} =
  ## Receives data from ``socket``. This function should normally be used with
  ## connection-less sockets (UDP sockets).
  ##
  ## If an error occurs an EOS exception will be raised. Otherwise the return
  ## value will be the length of data received.
  ##
  ## **Warning:** This function does not yet have a buffered implementation,
  ## so when ``socket`` is buffered the non-buffered implementation will be
  ## used. Therefore if ``socket`` contains something in its buffer this
  ## function will make no effort to return it.
  
  # TODO: Buffered sockets
  data.setLen(length)
  var sockAddress: Sockaddr_in
  var addrLen = sizeof(sockAddress).SockLen
  result = recvfrom(socket.fd, cstring(data), length.cint, flags.cint,
                    cast[ptr SockAddr](addr(sockAddress)), addr(addrLen))

  if result != -1:
    data.setLen(result)
    address = $inet_ntoa(sockAddress.sin_addr)
    port = ntohs(sockAddress.sin_port).Port
  else:
    raiseOSError(osLastError())

proc skip*(socket: Socket, size: int, timeout = -1) =
  ## Skips ``size`` amount of bytes.
  ##
  ## An optional timeout can be specified in miliseconds, if skipping the
  ## bytes takes longer than specified an ETimeout exception will be raised.
  ##
  ## Returns the number of skipped bytes.
  var waited = 0.0
  var dummy = alloc(size)
  var bytesSkipped = 0
  while bytesSkipped != size:
    let avail = waitFor(socket, waited, timeout, size-bytesSkipped, "skip")
    bytesSkipped += recv(socket, dummy, avail)
  dealloc(dummy)

proc send*(socket: Socket, data: pointer, size: int): int {.
  tags: [WriteIOEffect].} =
  ## Sends data to a socket.
  ##
  ## **Note**: This is a low-level version of ``send``. You likely should use 
  ## the version below.
  when defined(ssl):
    if socket.isSSL:
      return SSLWrite(socket.sslHandle, cast[cstring](data), size)
  
  when useWinVersion or defined(macosx):
    result = send(socket.fd, data, size.cint, 0'i32)
  else:
    when defined(solaris): 
      const MSG_NOSIGNAL = 0
    result = send(socket.fd, data, size, int32(MSG_NOSIGNAL))

proc send*(socket: Socket, data: string,
           flags = {SocketFlag.SafeDisconn}) {.tags: [WriteIOEffect].} =
  ## sends data to a socket.
  let sent = send(socket, cstring(data), data.len)
  if sent < 0:
    let lastError = osLastError()
    if flags.isDisconnectionError(lastError): return
    socketError(socket, lastError = lastError)

  if sent != data.len:
    raise newException(OSError, "Could not send all data.")

proc trySend*(socket: Socket, data: string): bool {.tags: [WriteIOEffect].} =
  ## Safe alternative to ``send``. Does not raise an EOS when an error occurs,
  ## and instead returns ``false`` on failure.
  result = send(socket, cstring(data), data.len) == data.len

proc sendTo*(socket: Socket, address: string, port: Port, data: pointer,
             size: int, af: Domain = AF_INET, flags = 0'i32): int {.
             tags: [WriteIOEffect].} =
  ## This proc sends ``data`` to the specified ``address``,
  ## which may be an IP address or a hostname, if a hostname is specified 
  ## this function will try each IP of that hostname.
  ##
  ##
  ## **Note:** You may wish to use the high-level version of this function
  ## which is defined below.
  ##
  ## **Note:** This proc is not available for SSL sockets.
  var aiList = getAddrInfo(address, port, af)
  
  # try all possibilities:
  var success = false
  var it = aiList
  while it != nil:
    result = sendto(socket.fd, data, size.cint, flags.cint, it.ai_addr,
                    it.ai_addrlen.SockLen)
    if result != -1'i32:
      success = true
      break
    it = it.ai_next

  dealloc(aiList)

proc sendTo*(socket: Socket, address: string, port: Port, 
             data: string): int {.tags: [WriteIOEffect].} =
  ## This proc sends ``data`` to the specified ``address``,
  ## which may be an IP address or a hostname, if a hostname is specified 
  ## this function will try each IP of that hostname.
  ##
  ## This is the high-level version of the above ``sendTo`` function.
  result = socket.sendTo(address, port, cstring(data), data.len)

proc connectAsync(socket: Socket, name: string, port = Port(0),
                  af: Domain = AF_INET) {.tags: [ReadIOEffect].} =
  ## A variant of ``connect`` for non-blocking sockets.
  ##
  ## This procedure will immediatelly return, it will not block until a connection
  ## is made. It is up to the caller to make sure the connection has been established
  ## by checking (using ``select``) whether the socket is writeable.
  ##
  ## **Note**: For SSL sockets, the ``handshake`` procedure must be called
  ## whenever the socket successfully connects to a server.
  var aiList = getAddrInfo(name, port, af)
  # try all possibilities:
  var success = false
  var lastError: OSErrorCode
  var it = aiList
  while it != nil:
    var ret = connect(socket.fd, it.ai_addr, it.ai_addrlen.SockLen)
    if ret == 0'i32:
      success = true
      break
    else:
      lastError = osLastError()
      when useWinVersion:
        # Windows EINTR doesn't behave same as POSIX.
        if lastError.int32 == WSAEWOULDBLOCK:
          success = true
          break
      else:
        if lastError.int32 == EINTR or lastError.int32 == EINPROGRESS:
          success = true
          break
        
    it = it.ai_next

  dealloc(aiList)
  if not success: raiseOSError(lastError)

proc connect*(socket: Socket, address: string, port = Port(0), timeout: int,
             af: Domain = AF_INET) {.tags: [ReadIOEffect, WriteIOEffect].} =
  ## Connects to server as specified by ``address`` on port specified by ``port``.
  ##
  ## The ``timeout`` paremeter specifies the time in miliseconds to allow for
  ## the connection to the server to be made.
  socket.fd.setBlocking(false)
  
  socket.connectAsync(address, port, af)
  var s = @[socket.fd]
  if selectWrite(s, timeout) != 1:
    raise newException(TimeoutError, "Call to 'connect' timed out.")
  else:
    when defined(ssl):
      if socket.isSSL:
        socket.fd.setBlocking(true)
        doAssert socket.handshake()
  socket.fd.setBlocking(true)

proc isSSL*(socket: Socket): bool = return socket.isSSL
  ## Determines whether ``socket`` is a SSL socket.

proc getFD*(socket: Socket): SocketHandle = return socket.fd
  ## Returns the socket's file descriptor

type
  IpAddressFamily* {.pure.} = enum ## Describes the type of an IP address
    IPv6, ## IPv6 address
    IPv4  ## IPv4 address

  TIpAddress* = object ## stores an arbitrary IP address    
    case family*: IpAddressFamily ## the type of the IP address (IPv4 or IPv6)
    of IpAddressFamily.IPv6:
      address_v6*: array[0..15, uint8] ## Contains the IP address in bytes in
                                       ## case of IPv6
    of IpAddressFamily.IPv4:
      address_v4*: array[0..3, uint8] ## Contains the IP address in bytes in
                                      ## case of IPv4

proc IPv4_any*(): TIpAddress =
  ## Returns the IPv4 any address, which can be used to listen on all available
  ## network adapters
  result = TIpAddress(
    family: IpAddressFamily.IPv4,
    address_v4: [0'u8, 0, 0, 0])

proc IPv4_loopback*(): TIpAddress =
  ## Returns the IPv4 loopback address (127.0.0.1)
  result = TIpAddress(
    family: IpAddressFamily.IPv4,
    address_v4: [127'u8, 0, 0, 1])

proc IPv4_broadcast*(): TIpAddress =
  ## Returns the IPv4 broadcast address (255.255.255.255)
  result = TIpAddress(
    family: IpAddressFamily.IPv4,
    address_v4: [255'u8, 255, 255, 255])

proc IPv6_any*(): TIpAddress =
  ## Returns the IPv6 any address (::0), which can be used
  ## to listen on all available network adapters 
  result = TIpAddress(
    family: IpAddressFamily.IPv6,
    address_v6: [0'u8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])

proc IPv6_loopback*(): TIpAddress =
  ## Returns the IPv6 loopback address (::1)
  result = TIpAddress(
    family: IpAddressFamily.IPv6,
    address_v6: [0'u8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1])

proc `==`*(lhs, rhs: TIpAddress): bool =
  ## Compares two IpAddresses for Equality. Returns two if the addresses are equal
  if lhs.family != rhs.family: return false
  if lhs.family == IpAddressFamily.IPv4:
    for i in low(lhs.address_v4) .. high(lhs.address_v4):
      if lhs.address_v4[i] != rhs.address_v4[i]: return false
  else: # IPv6
    for i in low(lhs.address_v6) .. high(lhs.address_v6):
      if lhs.address_v6[i] != rhs.address_v6[i]: return false
  return true

proc `$`*(address: TIpAddress): string =
  ## Converts an TIpAddress into the textual representation
  result = ""
  case address.family
  of IpAddressFamily.IPv4:
    for i in 0 .. 3:
      if i != 0:
        result.add('.')
      result.add($address.address_v4[i])
  of IpAddressFamily.IPv6:
    var
      currentZeroStart = -1
      currentZeroCount = 0
      biggestZeroStart = -1
      biggestZeroCount = 0
    # Look for the largest block of zeros
    for i in 0..7:
      var isZero = address.address_v6[i*2] == 0 and address.address_v6[i*2+1] == 0
      if isZero:
        if currentZeroStart == -1:
          currentZeroStart = i
          currentZeroCount = 1
        else:
          currentZeroCount.inc()
        if currentZeroCount > biggestZeroCount:
          biggestZeroCount = currentZeroCount
          biggestZeroStart = currentZeroStart
      else:
        currentZeroStart = -1

    if biggestZeroCount == 8: # Special case ::0
      result.add("::")
    else: # Print address
      var printedLastGroup = false
      for i in 0..7:
        var word:uint16 = (cast[uint16](address.address_v6[i*2])) shl 8
        word = word or cast[uint16](address.address_v6[i*2+1])

        if biggestZeroCount != 0 and # Check if group is in skip group
          (i >= biggestZeroStart and i < (biggestZeroStart + biggestZeroCount)):
          if i == biggestZeroStart: # skip start
            result.add("::")
          printedLastGroup = false
        else:
          if printedLastGroup:
            result.add(':')
          var
            afterLeadingZeros = false
            mask = 0xF000'u16
          for j in 0'u16..3'u16:
            var val = (mask and word) shr (4'u16*(3'u16-j))
            if val != 0 or afterLeadingZeros:
              if val < 0xA:
                result.add(chr(uint16(ord('0'))+val))
              else: # val >= 0xA
                result.add(chr(uint16(ord('a'))+val-0xA))
              afterLeadingZeros = true
            mask = mask shr 4
          printedLastGroup = true

proc parseIPv4Address(address_str: string): TIpAddress =
  ## Parses IPv4 adresses
  ## Raises EInvalidValue on errors
  var
    byteCount = 0
    currentByte:uint16 = 0
    seperatorValid = false

  result.family = IpAddressFamily.IPv4

  for i in 0 .. high(address_str):
    if address_str[i] in strutils.Digits: # Character is a number
      currentByte = currentByte * 10 +
        cast[uint16](ord(address_str[i]) - ord('0'))
      if currentByte > 255'u16:
        raise newException(ValueError,
          "Invalid IP Address. Value is out of range")
      seperatorValid = true
    elif address_str[i] == '.': # IPv4 address separator
      if not seperatorValid or byteCount >= 3:
        raise newException(ValueError,
          "Invalid IP Address. The address consists of too many groups")
      result.address_v4[byteCount] = cast[uint8](currentByte)
      currentByte = 0
      byteCount.inc
      seperatorValid = false
    else:
      raise newException(ValueError,
        "Invalid IP Address. Address contains an invalid character")

  if byteCount != 3 or not seperatorValid:
    raise newException(ValueError, "Invalid IP Address")
  result.address_v4[byteCount] = cast[uint8](currentByte)

proc parseIPv6Address(address_str: string): TIpAddress =
  ## Parses IPv6 adresses
  ## Raises EInvalidValue on errors
  result.family = IpAddressFamily.IPv6
  if address_str.len < 2:
    raise newException(ValueError, "Invalid IP Address")

  var
    groupCount = 0
    currentGroupStart = 0
    currentShort:uint32 = 0
    seperatorValid = true
    dualColonGroup = -1
    lastWasColon = false
    v4StartPos = -1
    byteCount = 0

  for i,c in address_str:
    if c == ':':
      if not seperatorValid:
        raise newException(ValueError,
          "Invalid IP Address. Address contains an invalid seperator")
      if lastWasColon:        
        if dualColonGroup != -1:
          raise newException(ValueError,
            "Invalid IP Address. Address contains more than one \"::\" seperator")
        dualColonGroup = groupCount
        seperatorValid = false
      elif i != 0 and i != high(address_str):
        if groupCount >= 8:
          raise newException(ValueError,
            "Invalid IP Address. The address consists of too many groups")
        result.address_v6[groupCount*2] = cast[uint8](currentShort shr 8)
        result.address_v6[groupCount*2+1] = cast[uint8](currentShort and 0xFF)
        currentShort = 0
        groupCount.inc()        
        if dualColonGroup != -1: seperatorValid = false
      elif i == 0: # only valid if address starts with ::
        if address_str[1] != ':':
          raise newException(ValueError,
            "Invalid IP Address. Address may not start with \":\"")
      else: # i == high(address_str) - only valid if address ends with ::
        if address_str[high(address_str)-1] != ':': 
          raise newException(ValueError,
            "Invalid IP Address. Address may not end with \":\"")
      lastWasColon = true
      currentGroupStart = i + 1
    elif c == '.': # Switch to parse IPv4 mode
      if i < 3 or not seperatorValid or groupCount >= 7:
        raise newException(ValueError, "Invalid IP Address")
      v4StartPos = currentGroupStart
      currentShort = 0
      seperatorValid = false
      break
    elif c in strutils.HexDigits:
      if c in strutils.Digits: # Normal digit
        currentShort = (currentShort shl 4) + cast[uint32](ord(c) - ord('0'))
      elif c >= 'a' and c <= 'f': # Lower case hex
        currentShort = (currentShort shl 4) + cast[uint32](ord(c) - ord('a')) + 10
      else: # Upper case hex
        currentShort = (currentShort shl 4) + cast[uint32](ord(c) - ord('A')) + 10
      if currentShort > 65535'u32:
        raise newException(ValueError,
          "Invalid IP Address. Value is out of range")
      lastWasColon = false
      seperatorValid = true
    else:
      raise newException(ValueError,
        "Invalid IP Address. Address contains an invalid character")


  if v4StartPos == -1: # Don't parse v4. Copy the remaining v6 stuff
    if seperatorValid: # Copy remaining data
      if groupCount >= 8:
        raise newException(ValueError,
          "Invalid IP Address. The address consists of too many groups")
      result.address_v6[groupCount*2] = cast[uint8](currentShort shr 8)
      result.address_v6[groupCount*2+1] = cast[uint8](currentShort and 0xFF)
      groupCount.inc()
  else: # Must parse IPv4 address
    for i,c in address_str[v4StartPos..high(address_str)]:
      if c in strutils.Digits: # Character is a number
        currentShort = currentShort * 10 + cast[uint32](ord(c) - ord('0'))
        if currentShort > 255'u32:
          raise newException(ValueError,
            "Invalid IP Address. Value is out of range")
        seperatorValid = true
      elif c == '.': # IPv4 address separator
        if not seperatorValid or byteCount >= 3:
          raise newException(ValueError, "Invalid IP Address")
        result.address_v6[groupCount*2 + byteCount] = cast[uint8](currentShort)
        currentShort = 0
        byteCount.inc()
        seperatorValid = false
      else: # Invalid character
        raise newException(ValueError,
          "Invalid IP Address. Address contains an invalid character")

    if byteCount != 3 or not seperatorValid:
      raise newException(ValueError, "Invalid IP Address")
    result.address_v6[groupCount*2 + byteCount] = cast[uint8](currentShort)
    groupCount += 2

  # Shift and fill zeros in case of ::
  if groupCount > 8:
    raise newException(ValueError,
      "Invalid IP Address. The address consists of too many groups")
  elif groupCount < 8: # must fill
    if dualColonGroup == -1:
      raise newException(ValueError,
        "Invalid IP Address. The address consists of too few groups")
    var toFill = 8 - groupCount # The number of groups to fill
    var toShift = groupCount - dualColonGroup # Nr of known groups after ::
    for i in 0..2*toShift-1: # shift
      result.address_v6[15-i] = result.address_v6[groupCount*2-i-1]
    for i in 0..2*toFill-1: # fill with 0s
      result.address_v6[dualColonGroup*2+i] = 0
  elif dualColonGroup != -1:
    raise newException(ValueError,
      "Invalid IP Address. The address consists of too many groups")

proc parseIpAddress*(address_str: string): TIpAddress =
  ## Parses an IP address
  ## Raises EInvalidValue on error
  if address_str == nil:
    raise newException(ValueError, "IP Address string is nil")
  if address_str.contains(':'):
    return parseIPv6Address(address_str)
  else:
    return parseIPv4Address(address_str)
