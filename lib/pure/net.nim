#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a high-level cross-platform sockets interface.
## The procedures implemented in this module are primarily for blocking sockets.
## For asynchronous non-blocking sockets use the ``asyncnet`` module together
## with the ``asyncdispatch`` module.
##
## The first thing you will always need to do in order to start using sockets,
## is to create a new instance of the ``Socket`` type using the ``newSocket``
## procedure.
##
## SSL
## ====
##
## In order to use the SSL procedures defined in this module, you will need to
## compile your application with the ``-d:ssl`` flag.
##
## Examples
## ========
##
## Connecting to a server
## ----------------------
##
## After you create a socket with the ``newSocket`` procedure, you can easily
## connect it to a server running at a known hostname (or IP address) and port.
## To do so over TCP, use the example below.
##
## .. code-block:: Nim
##   var socket = newSocket()
##   socket.connect("google.com", Port(80))
##
## UDP is a connectionless protocol, so UDP sockets don't have to explicitly
## call the ``connect`` procedure. They can simply start sending data
## immediately.
##
## .. code-block:: Nim
##   var socket = newSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
##   socket.sendTo("192.168.0.1", Port(27960), "status\n")
##
## Creating a server
## -----------------
##
## After you create a socket with the ``newSocket`` procedure, you can create a
## TCP server by calling the ``bindAddr`` and ``listen`` procedures.
##
## .. code-block:: Nim
##   var socket = newSocket()
##   socket.bindAddr(Port(1234))
##   socket.listen()
##
## You can then begin accepting connections using the ``accept`` procedure.
##
## .. code-block:: Nim
##   var client: Socket
##   var address = ""
##   while true:
##     socket.acceptAddr(client, address)
##     echo("Client connected from: ", address)

{.deadCodeElim: on.}  # dce option deprecated
import nativesockets, os, strutils, parseutils, times, sets, options
export Port, `$`, `==`
export Domain, SockType, Protocol

const useWinVersion = defined(Windows) or defined(nimdoc)
const defineSsl = defined(ssl) or defined(nimdoc)

when defineSsl:
  import openssl

# Note: The enumerations are mapped to Window's constants.

when defineSsl:
  type
    SslError* = object of Exception

    SslCVerifyMode* = enum
      CVerifyNone, CVerifyPeer

    SslProtVersion* = enum
      protSSLv2, protSSLv3, protTLSv1, protSSLv23

    SslContext* = ref object
      context*: SslCtx
      referencedData: HashSet[int]
      extraInternal: SslContextExtraInternal

    SslAcceptResult* = enum
      AcceptNoClient = 0, AcceptNoHandshake, AcceptSuccess

    SslHandshakeType* = enum
      handshakeAsClient, handshakeAsServer

    SslClientGetPskFunc* = proc(hint: string): tuple[identity: string, psk: string]

    SslServerGetPskFunc* = proc(identity: string): string

    SslContextExtraInternal = ref object of RootRef
      serverGetPskFunc: SslServerGetPskFunc
      clientGetPskFunc: SslClientGetPskFunc

else:
  type
    SslContext* = void # TODO: Workaround #4797.

const
  BufferSize*: int = 4000 ## size of a buffered socket's buffer
  MaxLineLength* = 1_000_000

type
  SocketImpl* = object ## socket type
    fd: SocketHandle
    case isBuffered: bool # determines whether this socket is buffered.
    of true:
      buffer: array[0..BufferSize, char]
      currPos: int # current index in buffer
      bufLen: int # current length of buffer
    of false: nil
    when defineSsl:
      case isSsl: bool
      of true:
        sslHandle: SSLPtr
        sslContext: SSLContext
        sslNoHandshake: bool # True if needs handshake.
        sslHasPeekChar: bool
        sslPeekChar: char
      of false: nil
    lastError: OSErrorCode ## stores the last error on this socket
    domain: Domain
    sockType: SockType
    protocol: Protocol

  Socket* = ref SocketImpl

  SOBool* = enum ## Boolean socket options.
    OptAcceptConn, OptBroadcast, OptDebug, OptDontRoute, OptKeepAlive,
    OptOOBInline, OptReuseAddr, OptReusePort, OptNoDelay

  ReadLineResult* = enum ## result for readLineAsync
    ReadFullLine, ReadPartialLine, ReadDisconnected, ReadNone

  TimeoutError* = object of Exception

  SocketFlag* {.pure.} = enum
    Peek,
    SafeDisconn ## Ensures disconnection exceptions (ECONNRESET, EPIPE etc) are not thrown.

type
  IpAddressFamily* {.pure.} = enum ## Describes the type of an IP address
    IPv6, ## IPv6 address
    IPv4  ## IPv4 address

  IpAddress* = object ## stores an arbitrary IP address
    case family*: IpAddressFamily ## the type of the IP address (IPv4 or IPv6)
    of IpAddressFamily.IPv6:
      address_v6*: array[0..15, uint8] ## Contains the IP address in bytes in
                                       ## case of IPv6
    of IpAddressFamily.IPv4:
      address_v4*: array[0..3, uint8] ## Contains the IP address in bytes in
                                      ## case of IPv4

proc socketError*(socket: Socket, err: int = -1, async = false,
                  lastError = (-1).OSErrorCode): void {.gcsafe.}

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

proc newSocket*(fd: SocketHandle, domain: Domain = AF_INET,
    sockType: SockType = SOCK_STREAM,
    protocol: Protocol = IPPROTO_TCP, buffered = true): Socket =
  ## Creates a new socket as specified by the params.
  assert fd != osInvalidSocket
  result = Socket(
    fd: fd,
    isBuffered: buffered,
    domain: domain,
    sockType: sockType,
    protocol: protocol)
  if buffered:
    result.currPos = 0

  # Set SO_NOSIGPIPE on OS X.
  when defined(macosx) and not defined(nimdoc):
    setSockOptInt(fd, SOL_SOCKET, SO_NOSIGPIPE, 1)

proc newSocket*(domain, sockType, protocol: cint, buffered = true): Socket =
  ## Creates a new socket.
  ##
  ## If an error occurs OSError will be raised.
  let fd = createNativeSocket(domain, sockType, protocol)
  if fd == osInvalidSocket:
    raiseOSError(osLastError())
  result = newSocket(fd, domain.Domain, sockType.SockType, protocol.Protocol,
                     buffered)

proc newSocket*(domain: Domain = AF_INET, sockType: SockType = SOCK_STREAM,
                protocol: Protocol = IPPROTO_TCP, buffered = true): Socket =
  ## Creates a new socket.
  ##
  ## If an error occurs OSError will be raised.
  let fd = createNativeSocket(domain, sockType, protocol)
  if fd == osInvalidSocket:
    raiseOSError(osLastError())
  result = newSocket(fd, domain, sockType, protocol, buffered)

proc parseIPv4Address(addressStr: string): IpAddress =
  ## Parses IPv4 adresses
  ## Raises ValueError on errors
  var
    byteCount = 0
    currentByte:uint16 = 0
    separatorValid = false

  result.family = IpAddressFamily.IPv4

  for i in 0 .. high(addressStr):
    if addressStr[i] in strutils.Digits: # Character is a number
      currentByte = currentByte * 10 +
        cast[uint16](ord(addressStr[i]) - ord('0'))
      if currentByte > 255'u16:
        raise newException(ValueError,
          "Invalid IP Address. Value is out of range")
      separatorValid = true
    elif addressStr[i] == '.': # IPv4 address separator
      if not separatorValid or byteCount >= 3:
        raise newException(ValueError,
          "Invalid IP Address. The address consists of too many groups")
      result.address_v4[byteCount] = cast[uint8](currentByte)
      currentByte = 0
      byteCount.inc
      separatorValid = false
    else:
      raise newException(ValueError,
        "Invalid IP Address. Address contains an invalid character")

  if byteCount != 3 or not separatorValid:
    raise newException(ValueError, "Invalid IP Address")
  result.address_v4[byteCount] = cast[uint8](currentByte)

proc parseIPv6Address(addressStr: string): IpAddress =
  ## Parses IPv6 adresses
  ## Raises ValueError on errors
  result.family = IpAddressFamily.IPv6
  if addressStr.len < 2:
    raise newException(ValueError, "Invalid IP Address")

  var
    groupCount = 0
    currentGroupStart = 0
    currentShort:uint32 = 0
    separatorValid = true
    dualColonGroup = -1
    lastWasColon = false
    v4StartPos = -1
    byteCount = 0

  for i,c in addressStr:
    if c == ':':
      if not separatorValid:
        raise newException(ValueError,
          "Invalid IP Address. Address contains an invalid separator")
      if lastWasColon:
        if dualColonGroup != -1:
          raise newException(ValueError,
            "Invalid IP Address. Address contains more than one \"::\" separator")
        dualColonGroup = groupCount
        separatorValid = false
      elif i != 0 and i != high(addressStr):
        if groupCount >= 8:
          raise newException(ValueError,
            "Invalid IP Address. The address consists of too many groups")
        result.address_v6[groupCount*2] = cast[uint8](currentShort shr 8)
        result.address_v6[groupCount*2+1] = cast[uint8](currentShort and 0xFF)
        currentShort = 0
        groupCount.inc()
        if dualColonGroup != -1: separatorValid = false
      elif i == 0: # only valid if address starts with ::
        if addressStr[1] != ':':
          raise newException(ValueError,
            "Invalid IP Address. Address may not start with \":\"")
      else: # i == high(addressStr) - only valid if address ends with ::
        if addressStr[high(addressStr)-1] != ':':
          raise newException(ValueError,
            "Invalid IP Address. Address may not end with \":\"")
      lastWasColon = true
      currentGroupStart = i + 1
    elif c == '.': # Switch to parse IPv4 mode
      if i < 3 or not separatorValid or groupCount >= 7:
        raise newException(ValueError, "Invalid IP Address")
      v4StartPos = currentGroupStart
      currentShort = 0
      separatorValid = false
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
      separatorValid = true
    else:
      raise newException(ValueError,
        "Invalid IP Address. Address contains an invalid character")


  if v4StartPos == -1: # Don't parse v4. Copy the remaining v6 stuff
    if separatorValid: # Copy remaining data
      if groupCount >= 8:
        raise newException(ValueError,
          "Invalid IP Address. The address consists of too many groups")
      result.address_v6[groupCount*2] = cast[uint8](currentShort shr 8)
      result.address_v6[groupCount*2+1] = cast[uint8](currentShort and 0xFF)
      groupCount.inc()
  else: # Must parse IPv4 address
    for i,c in addressStr[v4StartPos..high(addressStr)]:
      if c in strutils.Digits: # Character is a number
        currentShort = currentShort * 10 + cast[uint32](ord(c) - ord('0'))
        if currentShort > 255'u32:
          raise newException(ValueError,
            "Invalid IP Address. Value is out of range")
        separatorValid = true
      elif c == '.': # IPv4 address separator
        if not separatorValid or byteCount >= 3:
          raise newException(ValueError, "Invalid IP Address")
        result.address_v6[groupCount*2 + byteCount] = cast[uint8](currentShort)
        currentShort = 0
        byteCount.inc()
        separatorValid = false
      else: # Invalid character
        raise newException(ValueError,
          "Invalid IP Address. Address contains an invalid character")

    if byteCount != 3 or not separatorValid:
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

proc parseIpAddress*(addressStr: string): IpAddress =
  ## Parses an IP address
  ## Raises ValueError on error
  if addressStr.len == 0:
    raise newException(ValueError, "IP Address string is empty")
  if addressStr.contains(':'):
    return parseIPv6Address(addressStr)
  else:
    return parseIPv4Address(addressStr)

proc isIpAddress*(addressStr: string): bool {.tags: [].} =
  ## Checks if a string is an IP address
  ## Returns true if it is, false otherwise
  try:
    discard parseIpAddress(addressStr)
  except ValueError:
    return false
  return true

proc toSockAddr*(address: IpAddress, port: Port, sa: var Sockaddr_storage,
                 sl: var Socklen) =
  ## Converts `IpAddress` and `Port` to `SockAddr` and `Socklen`
  let port = htons(uint16(port))
  case address.family
  of IpAddressFamily.IPv4:
    sl = sizeof(Sockaddr_in).Socklen
    let s = cast[ptr Sockaddr_in](addr sa)
    s.sin_family = type(s.sin_family)(toInt(AF_INET))
    s.sin_port = port
    copyMem(addr s.sin_addr, unsafeAddr address.address_v4[0],
            sizeof(s.sin_addr))
  of IpAddressFamily.IPv6:
    sl = sizeof(Sockaddr_in6).Socklen
    let s = cast[ptr Sockaddr_in6](addr sa)
    s.sin6_family = type(s.sin6_family)(toInt(AF_INET6))
    s.sin6_port = port
    copyMem(addr s.sin6_addr, unsafeAddr address.address_v6[0],
            sizeof(s.sin6_addr))

proc fromSockAddrAux(sa: ptr Sockaddr_storage, sl: Socklen,
                     address: var IpAddress, port: var Port) =
  if sa.ss_family.cint == toInt(AF_INET) and sl == sizeof(Sockaddr_in).Socklen:
    address = IpAddress(family: IpAddressFamily.IPv4)
    let s = cast[ptr Sockaddr_in](sa)
    copyMem(addr address.address_v4[0], addr s.sin_addr,
            sizeof(address.address_v4))
    port = ntohs(s.sin_port).Port
  elif sa.ss_family.cint == toInt(AF_INET6) and
       sl == sizeof(Sockaddr_in6).Socklen:
    address = IpAddress(family: IpAddressFamily.IPv6)
    let s = cast[ptr Sockaddr_in6](sa)
    copyMem(addr address.address_v6[0], addr s.sin6_addr,
            sizeof(address.address_v6))
    port = ntohs(s.sin6_port).Port
  else:
    raise newException(ValueError, "Neither IPv4 nor IPv6")

proc fromSockAddr*(sa: Sockaddr_storage | SockAddr | Sockaddr_in | Sockaddr_in6,
    sl: Socklen, address: var IpAddress, port: var Port) {.inline.} =
  ## Converts `SockAddr` and `Socklen` to `IpAddress` and `Port`. Raises
  ## `ObjectConversionError` in case of invalid `sa` and `sl` arguments.
  fromSockAddrAux(cast[ptr Sockaddr_storage](unsafeAddr sa), sl, address, port)

when defineSsl:
  CRYPTO_malloc_init()
  doAssert SslLibraryInit() == 1
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
    var errStr = $ErrErrorString(err, nil)
    case err
    of 336032814, 336032784:
      errStr = "Please upgrade your OpenSSL library, it does not support the " &
               "necessary protocols. OpenSSL error is: " & errStr
    else:
      discard
    raise newException(SSLError, errStr)

  proc getExtraData*(ctx: SSLContext, index: int): RootRef =
    ## Retrieves arbitrary data stored inside SSLContext.
    if index notin ctx.referencedData:
      raise newException(IndexError, "No data with that index.")
    let res = ctx.context.SSL_CTX_get_ex_data(index.cint)
    if cast[int](res) == 0:
      raiseSSLError()
    return cast[RootRef](res)

  proc setExtraData*(ctx: SSLContext, index: int, data: RootRef) =
    ## Stores arbitrary data inside SSLContext. The unique `index`
    ## should be retrieved using getSslContextExtraDataIndex.
    if index in ctx.referencedData:
      GC_unref(getExtraData(ctx, index))

    if ctx.context.SSL_CTX_set_ex_data(index.cint, cast[pointer](data)) == -1:
      raiseSSLError()

    if index notin ctx.referencedData:
      ctx.referencedData.incl(index)
    GC_ref(data)

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
                   certFile = "", keyFile = "", cipherList = "ALL"): SSLContext =
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
      raiseSslError("SSLv2 is no longer secure and has been deprecated, use protSSLv23")
    of protSSLv3:
      raiseSslError("SSLv3 is no longer secure and has been deprecated, use protSSLv23")
    of protTLSv1:
      newCTX = SSL_CTX_new(TLSv1_method())

    if newCTX.SSLCTXSetCipherList(cipherList) != 1:
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

    result = SSLContext(context: newCTX, referencedData: initSet[int](),
      extraInternal: new(SslContextExtraInternal))

  proc getExtraInternal(ctx: SSLContext): SslContextExtraInternal =
    return ctx.extraInternal

  proc destroyContext*(ctx: SSLContext) =
    ## Free memory referenced by SSLContext.

    # We assume here that OpenSSL's internal indexes increase by 1 each time.
    # That means we can assume that the next internal index is the length of
    # extra data indexes.
    for i in ctx.referencedData:
      GC_unref(getExtraData(ctx, i).RootRef)
    ctx.context.SSL_CTX_free()

  proc `pskIdentityHint=`*(ctx: SSLContext, hint: string) =
    ## Sets the identity hint passed to server.
    ##
    ## Only used in PSK ciphersuites.
    if ctx.context.SSL_CTX_use_psk_identity_hint(hint) <= 0:
      raiseSSLError()

  proc clientGetPskFunc*(ctx: SSLContext): SslClientGetPskFunc =
    return ctx.getExtraInternal().clientGetPskFunc

  proc pskClientCallback(ssl: SslPtr; hint: cstring; identity: cstring; max_identity_len: cuint; psk: ptr cuchar;
    max_psk_len: cuint): cuint {.cdecl.} =
    let ctx = SSLContext(context: ssl.SSL_get_SSL_CTX)
    let hintString = if hint == nil: "" else: $hint
    let (identityString, pskString) = (ctx.clientGetPskFunc)(hintString)
    if psk.len.cuint > max_psk_len:
      return 0
    if identityString.len.cuint >= max_identity_len:
      return 0

    copyMem(identity, identityString.cstring, pskString.len + 1) # with the last zero byte
    copyMem(psk, pskString.cstring, pskString.len)

    return pskString.len.cuint

  proc `clientGetPskFunc=`*(ctx: SSLContext, fun: SslClientGetPskFunc) =
    ## Sets function that returns the client identity and the PSK based on identity
    ## hint from the server.
    ##
    ## Only used in PSK ciphersuites.
    ctx.getExtraInternal().clientGetPskFunc = fun
    ctx.context.SSL_CTX_set_psk_client_callback(
        if fun == nil: nil else: pskClientCallback)

  proc serverGetPskFunc*(ctx: SSLContext): SslServerGetPskFunc =
    return ctx.getExtraInternal().serverGetPskFunc

  proc pskServerCallback(ssl: SslCtx; identity: cstring; psk: ptr cuchar; max_psk_len: cint): cuint {.cdecl.} =
    let ctx = SSLContext(context: ssl.SSL_get_SSL_CTX)
    let pskString = (ctx.serverGetPskFunc)($identity)
    if psk.len.cint > max_psk_len:
      return 0
    copyMem(psk, pskString.cstring, pskString.len)

    return pskString.len.cuint

  proc `serverGetPskFunc=`*(ctx: SSLContext, fun: SslServerGetPskFunc) =
    ## Sets function that returns PSK based on the client identity.
    ##
    ## Only used in PSK ciphersuites.
    ctx.getExtraInternal().serverGetPskFunc = fun
    ctx.context.SSL_CTX_set_psk_server_callback(if fun == nil: nil
                                                else: pskServerCallback)

  proc getPskIdentity*(socket: Socket): string =
    ## Gets the PSK identity provided by the client.
    assert socket.isSSL
    return $(socket.sslHandle.SSL_get_psk_identity)

  proc wrapSocket*(ctx: SSLContext, socket: Socket) =
    ## Wraps a socket in an SSL context. This function effectively turns
    ## ``socket`` into an SSL socket.
    ##
    ## This must be called on an unconnected socket; an SSL session will
    ## be started when the socket is connected.
    ##
    ## **Disclaimer**: This code is not well tested, may be very unsafe and
    ## prone to security vulnerabilities.

    assert(not socket.isSSL)
    socket.isSSL = true
    socket.sslContext = ctx
    socket.sslHandle = SSLNew(socket.sslContext.context)
    socket.sslNoHandshake = false
    socket.sslHasPeekChar = false
    if socket.sslHandle == nil:
      raiseSSLError()

    if SSLSetFd(socket.sslHandle, socket.fd) != 1:
      raiseSSLError()

  proc wrapConnectedSocket*(ctx: SSLContext, socket: Socket,
                            handshake: SslHandshakeType,
                            hostname: string = "") =
    ## Wraps a connected socket in an SSL context. This function effectively
    ## turns ``socket`` into an SSL socket.
    ## ``hostname`` should be specified so that the client knows which hostname
    ## the server certificate should be validated against.
    ##
    ## This should be called on a connected socket, and will perform
    ## an SSL handshake immediately.
    ##
    ## **Disclaimer**: This code is not well tested, may be very unsafe and
    ## prone to security vulnerabilities.
    wrapSocket(ctx, socket)
    case handshake
    of handshakeAsClient:
      if hostname.len > 0 and not isIpAddress(hostname):
        # Discard result in case OpenSSL version doesn't support SNI, or we're
        # not using TLSv1+
        discard SSL_set_tlsext_host_name(socket.sslHandle, hostname)
      let ret = SSLConnect(socket.sslHandle)
      socketError(socket, ret)
    of handshakeAsServer:
      let ret = SSLAccept(socket.sslHandle)
      socketError(socket, ret)

proc getSocketError*(socket: Socket): OSErrorCode =
  ## Checks ``osLastError`` for a valid error. If it has been reset it uses
  ## the last error stored in the socket object.
  result = osLastError()
  if result == 0.OSErrorCode:
    result = socket.lastError
  if result == 0.OSErrorCode:
    raiseOSError(result, "No valid socket error code available")

proc socketError*(socket: Socket, err: int = -1, async = false,
                  lastError = (-1).OSErrorCode) =
  ## Raises an OSError based on the error code returned by ``SSLGetError``
  ## (for SSL sockets) and ``osLastError`` otherwise.
  ##
  ## If ``async`` is ``true`` no error will be thrown in the case when the
  ## error was caused by no data being available to be read.
  ##
  ## If ``err`` is not lower than 0 no exception will be raised.
  when defineSsl:
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
          var errStr = "IO error has occurred "
          let sslErr = ErrPeekLastError()
          if sslErr == 0 and err == 0:
            errStr.add "because an EOF was observed that violates the protocol"
          elif sslErr == 0 and err == -1:
            errStr.add "in the BIO layer"
          else:
            let errStr = $ErrErrorString(sslErr, nil)
            raiseSSLError(errStr & ": " & errStr)
          let osErr = osLastError()
          raiseOSError(osErr, errStr)
        of SSL_ERROR_SSL:
          raiseSSLError()
        else: raiseSSLError("Unknown Error")

  if err == -1 and not (when defineSsl: socket.isSSL else: false):
    var lastE = if lastError.int == -1: getSocketError(socket) else: lastError
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
  ## Raises an OSError error upon failure.
  if nativesockets.listen(socket.fd, backlog) < 0'i32:
    raiseOSError(osLastError())

proc bindAddr*(socket: Socket, port = Port(0), address = "") {.
  tags: [ReadIOEffect].} =
  ## Binds ``address``:``port`` to the socket.
  ##
  ## If ``address`` is "" then ADDR_ANY will be bound.
  var realaddr = address
  if realaddr == "":
    case socket.domain
    of AF_INET6: realaddr = "::"
    of AF_INET:  realaddr = "0.0.0.0"
    else:
      raise newException(ValueError,
        "Unknown socket address family and no address specified to bindAddr")

  var aiList = getAddrInfo(realaddr, port, socket.domain)
  if bindAddr(socket.fd, aiList.ai_addr, aiList.ai_addrlen.SockLen) < 0'i32:
    freeAddrInfo(aiList)
    raiseOSError(osLastError())
  freeAddrInfo(aiList)

proc acceptAddr*(server: Socket, client: var Socket, address: var string,
                 flags = {SocketFlag.SafeDisconn}) {.
                 tags: [ReadIOEffect], gcsafe, locks: 0.} =
  ## Blocks until a connection is being made from a client. When a connection
  ## is made sets ``client`` to the client socket and ``address`` to the address
  ## of the connecting client.
  ## This function will raise OSError if an error occurs.
  ##
  ## The resulting client will inherit any properties of the server socket. For
  ## example: whether the socket is buffered or not.
  ##
  ## The ``accept`` call may result in an error if the connecting socket
  ## disconnects during the duration of the ``accept``. If the ``SafeDisconn``
  ## flag is specified then this error will not be raised and instead
  ## accept will be called again.
  if client.isNil:
    new(client)
  let ret = accept(server.fd)
  let sock = ret[0]

  if sock == osInvalidSocket:
    let err = osLastError()
    if flags.isDisconnectionError(err):
      acceptAddr(server, client, address, flags)
    raiseOSError(err)
  else:
    address = ret[1]
    client.fd = sock
    client.domain = getSockDomain(sock)
    client.isBuffered = server.isBuffered

    # Handle SSL.
    when defineSsl:
      if server.isSSL:
        # We must wrap the client sock in a ssl context.

        server.sslContext.wrapSocket(client)
        let ret = SSLAccept(client.sslHandle)
        socketError(client, ret, false)

when false: #defineSsl:
  proc acceptAddrSSL*(server: Socket, client: var Socket,
                      address: var string): SSLAcceptResult {.
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
    template doHandshake(): untyped =
      when defineSsl:
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
  ## The ``accept`` call may result in an error if the connecting socket
  ## disconnects during the duration of the ``accept``. If the ``SafeDisconn``
  ## flag is specified then this error will not be raised and instead
  ## accept will be called again.
  var addrDummy = ""
  acceptAddr(server, client, addrDummy, flags)

proc close*(socket: Socket) =
  ## Closes a socket.
  try:
    when defineSsl:
      if socket.isSSL and socket.sslHandle != nil:
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
  finally:
    when defineSsl:
      if socket.isSSL and socket.sslHandle != nil:
        SSLFree(socket.sslHandle)
        socket.sslHandle = nil

    socket.fd.close()
    socket.fd = osInvalidSocket

when defined(posix):
  from posix import TCP_NODELAY
else:
  from winlean import TCP_NODELAY

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
  of OptReusePort: SO_REUSEPORT
  of OptNoDelay: TCP_NODELAY

proc getSockOpt*(socket: Socket, opt: SOBool, level = SOL_SOCKET): bool {.
  tags: [ReadIOEffect].} =
  ## Retrieves option ``opt`` as a boolean value.
  var res = getSockOptInt(socket.fd, cint(level), toCInt(opt))
  result = res != 0

proc getLocalAddr*(socket: Socket): (string, Port) =
  ## Get the socket's local address and port number.
  ##
  ## This is high-level interface for `getsockname`:idx:.
  getLocalAddr(socket.fd, socket.domain)

proc getPeerAddr*(socket: Socket): (string, Port) =
  ## Get the socket's peer address and port number.
  ##
  ## This is high-level interface for `getpeername`:idx:.
  getPeerAddr(socket.fd, socket.domain)

proc setSockOpt*(socket: Socket, opt: SOBool, value: bool, level = SOL_SOCKET) {.
  tags: [WriteIOEffect].} =
  ## Sets option ``opt`` to a boolean value specified by ``value``.
  ##
  ## .. code-block:: Nim
  ##   var socket = newSocket()
  ##   socket.setSockOpt(OptReusePort, true)
  ##   socket.setSockOpt(OptNoDelay, true, level=IPPROTO_TCP.toInt)
  ##
  var valuei = cint(if value: 1 else: 0)
  setSockOptInt(socket.fd, cint(level), toCInt(opt), valuei)

when defined(posix) or defined(nimdoc):
  proc connectUnix*(socket: Socket, path: string) =
    ## Connects to Unix socket on `path`.
    ## This only works on Unix-style systems: Mac OS X, BSD and Linux
    when not defined(nimdoc):
      var socketAddr = makeUnixAddr(path)
      if socket.fd.connect(cast[ptr SockAddr](addr socketAddr),
                           (sizeof(socketAddr.sun_family) + path.len).Socklen) != 0'i32:
        raiseOSError(osLastError())

  proc bindUnix*(socket: Socket, path: string) =
    ## Binds Unix socket to `path`.
    ## This only works on Unix-style systems: Mac OS X, BSD and Linux
    when not defined(nimdoc):
      var socketAddr = makeUnixAddr(path)
      if socket.fd.bindAddr(cast[ptr SockAddr](addr socketAddr),
                            (sizeof(socketAddr.sun_family) + path.len).Socklen) != 0'i32:
        raiseOSError(osLastError())

when defined(ssl):
  proc gotHandshake*(socket: Socket): bool =
    ## Determines whether a handshake has occurred between a client (``socket``)
    ## and the server that ``socket`` is connected to.
    ##
    ## Throws SslError if ``socket`` is not an SSL socket.
    if socket.isSSL:
      return not socket.sslNoHandshake
    else:
      raiseSSLError("Socket is not an SSL socket.")

proc hasDataBuffered*(s: Socket): bool =
  ## Determines whether a socket has data buffered.
  result = false
  if s.isBuffered:
    result = s.bufLen > 0 and s.currPos != s.bufLen

  when defineSsl:
    if s.isSSL and not result:
      result = s.sslHasPeekChar

proc select(readfd: Socket, timeout = 500): int =
  ## Used for socket operation timeouts.
  if readfd.hasDataBuffered:
    return 1

  var fds = @[readfd.fd]
  result = selectRead(fds, timeout)

proc isClosed(socket: Socket): bool =
  socket.fd == osInvalidSocket

proc uniRecv(socket: Socket, buffer: pointer, size, flags: cint): int =
  ## Handles SSL and non-ssl recv in a nice package.
  ##
  ## In particular handles the case where socket has been closed properly
  ## for both SSL and non-ssl.
  result = 0
  assert(not socket.isClosed, "Cannot `recv` on a closed socket")
  when defineSsl:
    if socket.isSsl:
      return SSLRead(socket.sslHandle, buffer, size)

  return recv(socket.fd, buffer, size, flags)

proc readIntoBuf(socket: Socket, flags: int32): int =
  result = 0
  result = uniRecv(socket, addr(socket.buffer), socket.buffer.high, flags)
  if result < 0:
    # Save it in case it gets reset (the Nim codegen occasionally may call
    # Win API functions which reset it).
    socket.lastError = osLastError()
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
    when defineSsl:
      if socket.isSSL:
        if socket.sslHasPeekChar: # TODO: Merge this peek char mess into uniRecv
          copyMem(data, addr(socket.sslPeekChar), 1)
          socket.sslHasPeekChar = false
          if size-1 > 0:
            var d = cast[cstring](data)
            result = uniRecv(socket, addr(d[1]), cint(size-1), 0'i32) + 1
          else:
            result = 1
        else:
          result = uniRecv(socket, data, size.cint, 0'i32)
      else:
        result = recv(socket.fd, data, size.cint, 0'i32)
    else:
      result = recv(socket.fd, data, size.cint, 0'i32)
    if result < 0:
      # Save the error in case it gets reset.
      socket.lastError = osLastError()

proc waitFor(socket: Socket, waited: var float, timeout, size: int,
             funcName: string): int {.tags: [TimeEffect].} =
  ## determines the amount of characters that can be read. Result will never
  ## be larger than ``size``. For unbuffered sockets this will be ``1``.
  ## For buffered sockets it can be as big as ``BufferSize``.
  ##
  ## If this function does not determine that there is data on the socket
  ## within ``timeout`` ms, a TimeoutError error will be raised.
  result = 1
  if size <= 0: assert false
  if timeout == -1: return size
  if socket.isBuffered and socket.bufLen != 0 and socket.bufLen != socket.currPos:
    result = socket.bufLen - socket.currPos
    result = min(result, size)
  else:
    if timeout - int(waited * 1000.0) < 1:
      raise newException(TimeoutError, "Call to '" & funcName & "' timed out.")

    when defineSsl:
      if socket.isSSL:
        if socket.hasDataBuffered:
          # sslPeekChar is present.
          return 1
        let sslPending = SSLPending(socket.sslHandle)
        if sslPending != 0:
          return min(sslPending, size)

    var startTime = epochTime()
    let selRet = select(socket, timeout - int(waited * 1000.0))
    if selRet < 0: raiseOSError(osLastError())
    if selRet != 1:
      raise newException(TimeoutError, "Call to '" & funcName & "' timed out.")
    waited += (epochTime() - startTime)

proc recv*(socket: Socket, data: pointer, size: int, timeout: int): int {.
  tags: [ReadIOEffect, TimeEffect].} =
  ## overload with a ``timeout`` parameter in milliseconds.
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
  ## This function will throw an OSError exception when an error occurs. A value
  ## lower than 0 is never returned.
  ##
  ## A timeout may be specified in milliseconds, if enough data is not received
  ## within the time specified a TimeoutError exception will be raised.
  ##
  ## **Note**: ``data`` must be initialised.
  ##
  ## **Warning**: Only the ``SafeDisconn`` flag is currently supported.
  data.setLen(size)
  result =
    if timeout == -1:
      recv(socket, cstring(data), size)
    else:
      recv(socket, cstring(data), size, timeout)
  if result < 0:
    data.setLen(0)
    let lastError = getSocketError(socket)
    if flags.isDisconnectionError(lastError): return
    socket.socketError(result, lastError = lastError)
  data.setLen(result)

proc recv*(socket: Socket, size: int, timeout = -1,
           flags = {SocketFlag.SafeDisconn}): string {.inline.} =
  ## Higher-level version of ``recv`` which returns a string.
  ##
  ## When ``""`` is returned the socket's connection has been closed.
  ##
  ## This function will throw an OSError exception when an error occurs.
  ##
  ## A timeout may be specified in milliseconds, if enough data is not received
  ## within the time specified a TimeoutError exception will be raised.
  ##
  ##
  ## **Warning**: Only the ``SafeDisconn`` flag is currently supported.
  result = newString(size)
  discard recv(socket, result, size, timeout, flags)

proc peekChar(socket: Socket, c: var char): int {.tags: [ReadIOEffect].} =
  if socket.isBuffered:
    result = 1
    if socket.bufLen == 0 or socket.currPos > socket.bufLen-1:
      var res = socket.readIntoBuf(0'i32)
      if res <= 0:
        result = res

    c = socket.buffer[socket.currPos]
  else:
    when defineSsl:
      if socket.isSSL:
        if not socket.sslHasPeekChar:
          result = uniRecv(socket, addr(socket.sslPeekChar), 1, 0'i32)
          socket.sslHasPeekChar = true

        c = socket.sslPeekChar
        return
    result = recv(socket.fd, addr(c), 1, MSG_PEEK)

proc readLine*(socket: Socket, line: var TaintedString, timeout = -1,
               flags = {SocketFlag.SafeDisconn}, maxLength = MaxLineLength) {.
  tags: [ReadIOEffect, TimeEffect].} =
  ## Reads a line of data from ``socket``.
  ##
  ## If a full line is read ``\r\L`` is not
  ## added to ``line``, however if solely ``\r\L`` is read then ``line``
  ## will be set to it.
  ##
  ## If the socket is disconnected, ``line`` will be set to ``""``.
  ##
  ## An OSError exception will be raised in the case of a socket error.
  ##
  ## A timeout can be specified in milliseconds, if data is not received within
  ## the specified time a TimeoutError exception will be raised.
  ##
  ## The ``maxLength`` parameter determines the maximum amount of characters
  ## that can be read. The result is truncated after that.
  ##
  ## **Warning**: Only the ``SafeDisconn`` flag is currently supported.

  template addNLIfEmpty() =
    if line.len == 0:
      line.string.add("\c\L")

  template raiseSockError() {.dirty.} =
    let lastError = getSocketError(socket)
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

    # Verify that this isn't a DOS attack: #3847.
    if line.string.len > maxLength: break

proc recvLine*(socket: Socket, timeout = -1,
               flags = {SocketFlag.SafeDisconn},
               maxLength = MaxLineLength): TaintedString =
  ## Reads a line of data from ``socket``.
  ##
  ## If a full line is read ``\r\L`` is not
  ## added to the result, however if solely ``\r\L`` is read then the result
  ## will be set to it.
  ##
  ## If the socket is disconnected, the result will be set to ``""``.
  ##
  ## An OSError exception will be raised in the case of a socket error.
  ##
  ## A timeout can be specified in milliseconds, if data is not received within
  ## the specified time a TimeoutError exception will be raised.
  ##
  ## The ``maxLength`` parameter determines the maximum amount of characters
  ## that can be read. The result is truncated after that.
  ##
  ## **Warning**: Only the ``SafeDisconn`` flag is currently supported.
  result = ""
  readLine(socket, result, timeout, flags, maxLength)

proc recvFrom*(socket: Socket, data: var string, length: int,
               address: var string, port: var Port, flags = 0'i32): int {.
               tags: [ReadIOEffect].} =
  ## Receives data from ``socket``. This function should normally be used with
  ## connection-less sockets (UDP sockets).
  ##
  ## If an error occurs an OSError exception will be raised. Otherwise the return
  ## value will be the length of data received.
  ##
  ## **Warning:** This function does not yet have a buffered implementation,
  ## so when ``socket`` is buffered the non-buffered implementation will be
  ## used. Therefore if ``socket`` contains something in its buffer this
  ## function will make no effort to return it.

  assert(socket.protocol != IPPROTO_TCP, "Cannot `recvFrom` on a TCP socket")
  # TODO: Buffered sockets
  data.setLen(length)
  var sockAddress: Sockaddr_in
  var addrLen = sizeof(sockAddress).SockLen
  result = recvfrom(socket.fd, cstring(data), length.cint, flags.cint,
                    cast[ptr SockAddr](addr(sockAddress)), addr(addrLen))

  if result != -1:
    data.setLen(result)
    address = getAddrString(cast[ptr SockAddr](addr(sockAddress)))
    port = ntohs(sockAddress.sin_port).Port
  else:
    raiseOSError(osLastError())

proc skip*(socket: Socket, size: int, timeout = -1) =
  ## Skips ``size`` amount of bytes.
  ##
  ## An optional timeout can be specified in milliseconds, if skipping the
  ## bytes takes longer than specified a TimeoutError exception will be raised.
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
  assert(not socket.isClosed, "Cannot `send` on a closed socket")
  when defineSsl:
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
    raiseOSError(osLastError(), "Could not send all data.")

template `&=`*(socket: Socket; data: typed) =
  ## an alias for 'send'.
  send(socket, data)

proc trySend*(socket: Socket, data: string): bool {.tags: [WriteIOEffect].} =
  ## Safe alternative to ``send``. Does not raise an OSError when an error occurs,
  ## and instead returns ``false`` on failure.
  result = send(socket, cstring(data), data.len) == data.len

proc sendTo*(socket: Socket, address: string, port: Port, data: pointer,
             size: int, af: Domain = AF_INET, flags = 0'i32) {.
             tags: [WriteIOEffect].} =
  ## This proc sends ``data`` to the specified ``address``,
  ## which may be an IP address or a hostname, if a hostname is specified
  ## this function will try each IP of that hostname.
  ##
  ## If an error occurs an OSError exception will be raised.
  ##
  ## **Note:** You may wish to use the high-level version of this function
  ## which is defined below.
  ##
  ## **Note:** This proc is not available for SSL sockets.
  assert(socket.protocol != IPPROTO_TCP, "Cannot `sendTo` on a TCP socket")
  assert(not socket.isClosed, "Cannot `sendTo` on a closed socket")
  var aiList = getAddrInfo(address, port, af, socket.sockType, socket.protocol)
  # try all possibilities:
  var success = false
  var it = aiList
  var result = 0
  while it != nil:
    result = sendto(socket.fd, data, size.cint, flags.cint, it.ai_addr,
                    it.ai_addrlen.SockLen)
    if result != -1'i32:
      success = true
      break
    it = it.ai_next

  let osError = osLastError()
  freeAddrInfo(aiList)

  if not success:
    raiseOSError(osError)

proc sendTo*(socket: Socket, address: string, port: Port,
             data: string) {.tags: [WriteIOEffect].} =
  ## This proc sends ``data`` to the specified ``address``,
  ## which may be an IP address or a hostname, if a hostname is specified
  ## this function will try each IP of that hostname.
  ##
  ## If an error occurs an OSError exception will be raised.
  ##
  ## This is the high-level version of the above ``sendTo`` function.
  socket.sendTo(address, port, cstring(data), data.len, socket.domain)


proc isSsl*(socket: Socket): bool =
  ## Determines whether ``socket`` is a SSL socket.
  when defineSsl:
    result = socket.isSSL
  else:
    result = false

proc getFd*(socket: Socket): SocketHandle = return socket.fd
  ## Returns the socket's file descriptor

proc IPv4_any*(): IpAddress =
  ## Returns the IPv4 any address, which can be used to listen on all available
  ## network adapters
  result = IpAddress(
    family: IpAddressFamily.IPv4,
    address_v4: [0'u8, 0, 0, 0])

proc IPv4_loopback*(): IpAddress =
  ## Returns the IPv4 loopback address (127.0.0.1)
  result = IpAddress(
    family: IpAddressFamily.IPv4,
    address_v4: [127'u8, 0, 0, 1])

proc IPv4_broadcast*(): IpAddress =
  ## Returns the IPv4 broadcast address (255.255.255.255)
  result = IpAddress(
    family: IpAddressFamily.IPv4,
    address_v4: [255'u8, 255, 255, 255])

proc IPv6_any*(): IpAddress =
  ## Returns the IPv6 any address (::0), which can be used
  ## to listen on all available network adapters
  result = IpAddress(
    family: IpAddressFamily.IPv6,
    address_v6: [0'u8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])

proc IPv6_loopback*(): IpAddress =
  ## Returns the IPv6 loopback address (::1)
  result = IpAddress(
    family: IpAddressFamily.IPv6,
    address_v6: [0'u8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1])

proc `==`*(lhs, rhs: IpAddress): bool =
  ## Compares two IpAddresses for Equality. Returns true if the addresses are equal
  if lhs.family != rhs.family: return false
  if lhs.family == IpAddressFamily.IPv4:
    for i in low(lhs.address_v4) .. high(lhs.address_v4):
      if lhs.address_v4[i] != rhs.address_v4[i]: return false
  else: # IPv6
    for i in low(lhs.address_v6) .. high(lhs.address_v6):
      if lhs.address_v6[i] != rhs.address_v6[i]: return false
  return true

proc `$`*(address: IpAddress): string =
  ## Converts an IpAddress into the textual representation
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

proc dial*(address: string, port: Port,
           protocol = IPPROTO_TCP, buffered = true): Socket
           {.tags: [ReadIOEffect, WriteIOEffect].} =
  ## Establishes connection to the specified ``address``:``port`` pair via the
  ## specified protocol. The procedure iterates through possible
  ## resolutions of the ``address`` until it succeeds, meaning that it
  ## seamlessly works with both IPv4 and IPv6.
  ## Returns Socket ready to send or receive data.
  let sockType = protocol.toSockType()

  let aiList = getAddrInfo(address, port, AF_UNSPEC, sockType, protocol)

  var fdPerDomain: array[low(Domain).ord..high(Domain).ord, SocketHandle]
  for i in low(fdPerDomain)..high(fdPerDomain):
    fdPerDomain[i] = osInvalidSocket
  template closeUnusedFds(domainToKeep = -1) {.dirty.} =
    for i, fd in fdPerDomain:
      if fd != osInvalidSocket and i != domainToKeep:
        fd.close()

  var success = false
  var lastError: OSErrorCode
  var it = aiList
  var domain: Domain
  var lastFd: SocketHandle
  while it != nil:
    let domainOpt = it.ai_family.toKnownDomain()
    if domainOpt.isNone:
      it = it.ai_next
      continue
    domain = domainOpt.unsafeGet()
    lastFd = fdPerDomain[ord(domain)]
    if lastFd == osInvalidSocket:
      lastFd = createNativeSocket(domain, sockType, protocol)
      if lastFd == osInvalidSocket:
        # we always raise if socket creation failed, because it means a
        # network system problem (e.g. not enough FDs), and not an unreachable
        # address.
        let err = osLastError()
        freeAddrInfo(aiList)
        closeUnusedFds()
        raiseOSError(err)
      fdPerDomain[ord(domain)] = lastFd
    if connect(lastFd, it.ai_addr, it.ai_addrlen.SockLen) == 0'i32:
      success = true
      break
    lastError = osLastError()
    it = it.ai_next
  freeAddrInfo(aiList)
  closeUnusedFds(ord(domain))

  if success:
    result = newSocket(lastFd, domain, sockType, protocol)
  elif lastError != 0.OSErrorCode:
    raiseOSError(lastError)
  else:
    raise newException(IOError, "Couldn't resolve address: " & address)

proc connect*(socket: Socket, address: string,
    port = Port(0)) {.tags: [ReadIOEffect].} =
  ## Connects socket to ``address``:``port``. ``Address`` can be an IP address or a
  ## host name. If ``address`` is a host name, this function will try each IP
  ## of that host name. ``htons`` is already performed on ``port`` so you must
  ## not do it.
  ##
  ## If ``socket`` is an SSL socket a handshake will be automatically performed.
  var aiList = getAddrInfo(address, port, socket.domain)
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

  freeAddrInfo(aiList)
  if not success: raiseOSError(lastError)

  when defineSsl:
    if socket.isSSL:
      # RFC3546 for SNI specifies that IP addresses are not allowed.
      if not isIpAddress(address):
        # Discard result in case OpenSSL version doesn't support SNI, or we're
        # not using TLSv1+
        discard SSL_set_tlsext_host_name(socket.sslHandle, address)

      let ret = SSLConnect(socket.sslHandle)
      socketError(socket, ret)

proc connectAsync(socket: Socket, name: string, port = Port(0),
                  af: Domain = AF_INET) {.tags: [ReadIOEffect].} =
  ## A variant of ``connect`` for non-blocking sockets.
  ##
  ## This procedure will immediately return, it will not block until a connection
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

  freeAddrInfo(aiList)
  if not success: raiseOSError(lastError)

proc connect*(socket: Socket, address: string, port = Port(0),
    timeout: int) {.tags: [ReadIOEffect, WriteIOEffect].} =
  ## Connects to server as specified by ``address`` on port specified by ``port``.
  ##
  ## The ``timeout`` paremeter specifies the time in milliseconds to allow for
  ## the connection to the server to be made.
  socket.fd.setBlocking(false)

  socket.connectAsync(address, port, socket.domain)
  var s = @[socket.fd]
  if selectWrite(s, timeout) != 1:
    raise newException(TimeoutError, "Call to 'connect' timed out.")
  else:
    let res = getSockOptInt(socket.fd, SOL_SOCKET, SO_ERROR)
    if res != 0:
      raiseOSError(OSErrorCode(res))
    when defineSsl and not defined(nimdoc):
      if socket.isSSL:
        socket.fd.setBlocking(true)
        doAssert socket.gotHandshake()
  socket.fd.setBlocking(true)

proc getPrimaryIPAddr*(dest = parseIpAddress("8.8.8.8")): IpAddress =
  ## Finds the local IP address, usually assigned to eth0 on LAN or wlan0 on WiFi,
  ## used to reach an external address. Useful to run local services.
  ##
  ## No traffic is sent.
  ##
  ## Supports IPv4 and v6.
  ## Raises OSError if external networking is not set up.
  ##
  ## .. code-block:: Nim
  ##   echo $getPrimaryIPAddr()  # "192.168.1.2"

  let socket =
    if dest.family == IpAddressFamily.IPv4:
      newSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
    else:
      newSocket(AF_INET6, SOCK_DGRAM, IPPROTO_UDP)
  socket.connect($dest, 80.Port)
  socket.getLocalAddr()[0].parseIpAddress()
