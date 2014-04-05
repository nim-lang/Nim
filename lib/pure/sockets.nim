#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2013 Andreas Rumpf, Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements portable sockets, it supports a mix of different types
## of sockets. Sockets are buffered by default meaning that data will be
## received in ``BufferSize`` (4000) sized chunks, buffering
## behaviour can be disabled by setting the ``buffered`` parameter when calling
## the ``socket`` function to `false`. Be aware that some functions may not yet
## support buffered sockets (mainly the recvFrom function).
##
## Most procedures raise EOS on error, but some may return ``-1`` or a boolean
## ``false``.
##
## SSL is supported through the OpenSSL library. This support can be activated
## by compiling with the ``-d:ssl`` switch. When an SSL socket is used it will
## raise ESSL exceptions when SSL errors occur.
##
## Asynchronous sockets are supported, however a better alternative is to use
## the `asyncio <asyncio.html>`_ module.

{.deadCodeElim: on.}

when hostOS == "solaris":
  {.passl: "-lsocket -lnsl".}

import os, parseutils
from times import epochTime
import unsigned

when defined(ssl):
  import openssl

when defined(Windows):
  import winlean
else:
  import posix

# Note: The enumerations are mapped to Window's constants.

when defined(ssl):
  type
    ESSL* = object of ESynch

    TSSLCVerifyMode* = enum
      CVerifyNone, CVerifyPeer
    
    TSSLProtVersion* = enum
      protSSLv2, protSSLv3, protTLSv1, protSSLv23
    
    PSSLContext* = distinct PSSLCTX

    TSSLAcceptResult* = enum
      AcceptNoClient = 0, AcceptNoHandshake, AcceptSuccess

const
  BufferSize*: int = 4000 ## size of a buffered socket's buffer

type
  TSocketImpl = object ## socket type
    fd: TSocketHandle
    case isBuffered: bool # determines whether this socket is buffered.
    of true:
      buffer: array[0..BufferSize, char]
      currPos: int # current index in buffer
      bufLen: int # current length of buffer
    of false: nil
    when defined(ssl):
      case isSsl: bool
      of true:
        sslHandle: PSSL
        sslContext: PSSLContext
        sslNoHandshake: bool # True if needs handshake.
        sslHasPeekChar: bool
        sslPeekChar: char
      of false: nil
    nonblocking: bool
  
  TSocket* = ref TSocketImpl
  
  TPort* = distinct uint16  ## port type
  
  TDomain* = enum   ## domain, which specifies the protocol family of the
                    ## created socket. Other domains than those that are listed
                    ## here are unsupported.
    AF_UNIX,        ## for local socket (using a file). Unsupported on Windows.
    AF_INET = 2,    ## for network protocol IPv4 or
    AF_INET6 = 23   ## for network protocol IPv6.

  TType* = enum        ## second argument to `socket` proc
    SOCK_STREAM = 1,   ## reliable stream-oriented service or Stream Sockets
    SOCK_DGRAM = 2,    ## datagram service or Datagram Sockets
    SOCK_RAW = 3,      ## raw protocols atop the network layer.
    SOCK_SEQPACKET = 5 ## reliable sequenced packet service

  TProtocol* = enum     ## third argument to `socket` proc
    IPPROTO_TCP = 6,    ## Transmission control protocol. 
    IPPROTO_UDP = 17,   ## User datagram protocol.
    IPPROTO_IP,         ## Internet protocol. Unsupported on Windows.
    IPPROTO_IPV6,       ## Internet Protocol Version 6. Unsupported on Windows.
    IPPROTO_RAW,        ## Raw IP Packets Protocol. Unsupported on Windows.
    IPPROTO_ICMP        ## Control message protocol. Unsupported on Windows.

  TServent* {.pure, final.} = object ## information about a service
    name*: string
    aliases*: seq[string]
    port*: TPort
    proto*: string

  Thostent* {.pure, final.} = object ## information about a given host
    name*: string
    aliases*: seq[string]
    addrtype*: TDomain
    length*: int
    addrList*: seq[string]

  TSOBool* = enum ## Boolean socket options.
    OptAcceptConn, OptBroadcast, OptDebug, OptDontRoute, OptKeepAlive,
    OptOOBInline, OptReuseAddr

  TRecvLineResult* = enum ## result for recvLineAsync
    RecvFullLine, RecvPartialLine, RecvDisconnected, RecvFail

  TReadLineResult* = enum ## result for readLineAsync
    ReadFullLine, ReadPartialLine, ReadDisconnected, ReadNone

  ETimeout* = object of ESynch

let
  invalidSocket*: TSocket = nil ## invalid socket

when defined(windows):
  let
    osInvalidSocket = winlean.INVALID_SOCKET
else:
  let
    osInvalidSocket = posix.INVALID_SOCKET

proc newTSocket(fd: TSocketHandle, isBuff: bool): TSocket =
  if fd == osInvalidSocket:
    return nil
  new(result)
  result.fd = fd
  result.isBuffered = isBuff
  if isBuff:
    result.currPos = 0
  result.nonblocking = false

proc `==`*(a, b: TPort): bool {.borrow.}
  ## ``==`` for ports.

proc `$`*(p: TPort): string {.borrow.}
  ## returns the port number as a string

proc ntohl*(x: int32): int32 = 
  ## Converts 32-bit integers from network to host byte order.
  ## On machines where the host byte order is the same as network byte order,
  ## this is a no-op; otherwise, it performs a 4-byte swap operation.
  when cpuEndian == bigEndian: result = x
  else: result = (x shr 24'i32) or
                 (x shr 8'i32 and 0xff00'i32) or
                 (x shl 8'i32 and 0xff0000'i32) or
                 (x shl 24'i32)

proc ntohs*(x: int16): int16 =
  ## Converts 16-bit integers from network to host byte order. On machines
  ## where the host byte order is the same as network byte order, this is
  ## a no-op; otherwise, it performs a 2-byte swap operation.
  when cpuEndian == bigEndian: result = x
  else: result = (x shr 8'i16) or (x shl 8'i16)

proc htonl*(x: int32): int32 =
  ## Converts 32-bit integers from host to network byte order. On machines
  ## where the host byte order is the same as network byte order, this is
  ## a no-op; otherwise, it performs a 4-byte swap operation.
  result = sockets.ntohl(x)

proc htons*(x: int16): int16 =
  ## Converts 16-bit positive integers from host to network byte order.
  ## On machines where the host byte order is the same as network byte
  ## order, this is a no-op; otherwise, it performs a 2-byte swap operation.
  result = sockets.ntohs(x)
  
when defined(Posix):
  proc toInt(domain: TDomain): cint =
    case domain
    of AF_UNIX:        result = posix.AF_UNIX
    of AF_INET:        result = posix.AF_INET
    of AF_INET6:       result = posix.AF_INET6
    else: discard

  proc toInt(typ: TType): cint =
    case typ
    of SOCK_STREAM:    result = posix.SOCK_STREAM
    of SOCK_DGRAM:     result = posix.SOCK_DGRAM
    of SOCK_SEQPACKET: result = posix.SOCK_SEQPACKET
    of SOCK_RAW:       result = posix.SOCK_RAW
    else: discard

  proc toInt(p: TProtocol): cint =
    case p
    of IPPROTO_TCP:    result = posix.IPPROTO_TCP
    of IPPROTO_UDP:    result = posix.IPPROTO_UDP
    of IPPROTO_IP:     result = posix.IPPROTO_IP
    of IPPROTO_IPV6:   result = posix.IPPROTO_IPV6
    of IPPROTO_RAW:    result = posix.IPPROTO_RAW
    of IPPROTO_ICMP:   result = posix.IPPROTO_ICMP
    else: discard

else:
  proc toInt(domain: TDomain): cint = 
    result = toU16(ord(domain))

  proc toInt(typ: TType): cint =
    result = cint(ord(typ))
  
  proc toInt(p: TProtocol): cint =
    result = cint(ord(p))

proc socket*(domain: TDomain = AF_INET, typ: TType = SOCK_STREAM,
             protocol: TProtocol = IPPROTO_TCP, buffered = true): TSocket =
  ## Creates a new socket; returns `InvalidSocket` if an error occurs.
  
  # TODO: Perhaps this should just raise EOS when an error occurs.
  when defined(Windows):
    result = newTSocket(winlean.socket(ord(domain), ord(typ), ord(protocol)), buffered)
  else:
    result = newTSocket(posix.socket(toInt(domain), toInt(typ), toInt(protocol)), buffered)

when defined(ssl):
  CRYPTO_malloc_init()
  SslLibraryInit()
  SslLoadErrorStrings()
  ErrLoadBioStrings()
  OpenSSL_add_all_algorithms()

  proc SSLError(s = "") =
    if s != "":
      raise newException(ESSL, s)
    let err = ErrPeekLastError()
    if err == 0:
      raise newException(ESSL, "No error reported.")
    if err == -1:
      OSError(OSLastError())
    var errStr = ErrErrorString(err, nil)
    raise newException(ESSL, $errStr)

  # http://simplestcodings.blogspot.co.uk/2010/08/secure-server-client-using-openssl-in-c.html
  proc loadCertificates(ctx: PSSL_CTX, certFile, keyFile: string) =
    if certFile != "" and not existsFile(certFile):
      raise newException(system.EIO, "Certificate file could not be found: " & certFile)
    if keyFile != "" and not existsFile(keyFile):
      raise newException(system.EIO, "Key file could not be found: " & keyFile)
    
    if certFile != "":
      var ret = SSLCTXUseCertificateChainFile(ctx, certFile)
      if ret != 1:
        SSLError()
    
    # TODO: Password? www.rtfm.com/openssl-examples/part1.pdf
    if keyFile != "":
      if SSL_CTX_use_PrivateKey_file(ctx, keyFile,
                                     SSL_FILETYPE_PEM) != 1:
        SSLError()
        
      if SSL_CTX_check_private_key(ctx) != 1:
        SSLError("Verification of private key file failed.")

  proc newContext*(protVersion = ProtSSLv23, verifyMode = CVerifyPeer,
                   certFile = "", keyFile = ""): PSSLContext =
    ## Creates an SSL context.
    ## 
    ## Protocol version specifies the protocol to use. SSLv2, SSLv3, TLSv1 are 
    ## are available with the addition of ``ProtSSLv23`` which allows for 
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
    var newCTX: PSSL_CTX
    case protVersion
    of protSSLv23:
      newCTX = SSL_CTX_new(SSLv23_method()) # SSlv2,3 and TLS1 support.
    of protSSLv2:
      when not defined(linux):
        newCTX = SSL_CTX_new(SSLv2_method())
      else:
        SSLError()
    of protSSLv3:
      newCTX = SSL_CTX_new(SSLv3_method())
    of protTLSv1:
      newCTX = SSL_CTX_new(TLSv1_method())
    
    if newCTX.SSLCTXSetCipherList("ALL") != 1:
      SSLError()
    case verifyMode
    of CVerifyPeer:
      newCTX.SSLCTXSetVerify(SSLVerifyPeer, nil)
    of CVerifyNone:
      newCTX.SSLCTXSetVerify(SSLVerifyNone, nil)
    if newCTX == nil:
      SSLError()

    discard newCTX.SSLCTXSetMode(SSL_MODE_AUTO_RETRY)
    newCTX.loadCertificates(certFile, keyFile)
    return PSSLContext(newCTX)

  proc wrapSocket*(ctx: PSSLContext, socket: TSocket) =
    ## Wraps a socket in an SSL context. This function effectively turns
    ## ``socket`` into an SSL socket.
    ##
    ## **Disclaimer**: This code is not well tested, may be very unsafe and
    ## prone to security vulnerabilities.
    
    socket.isSSL = true
    socket.sslContext = ctx
    socket.sslHandle = SSLNew(PSSLCTX(socket.sslContext))
    socket.sslNoHandshake = false
    socket.sslHasPeekChar = false
    if socket.sslHandle == nil:
      SSLError()
    
    if SSLSetFd(socket.sslHandle, socket.fd) != 1:
      SSLError()

proc socketError*(socket: TSocket, err: int = -1, async = false) =
  ## Raises proper errors based on return values of ``recv`` functions.
  ##
  ## If ``async`` is ``True`` no error will be thrown in the case when the
  ## error was caused by no data being available to be read.
  ##
  ## If ``err`` is not lower than 0 no exception will be raised.
  when defined(ssl):
    if socket.isSSL:
      if err <= 0:
        var ret = SSLGetError(socket.sslHandle, err.cint)
        case ret
        of SSL_ERROR_ZERO_RETURN:
          SSLError("TLS/SSL connection failed to initiate, socket closed prematurely.")
        of SSL_ERROR_WANT_CONNECT, SSL_ERROR_WANT_ACCEPT:
          if async:
            return
          else: SSLError("Not enough data on socket.")
        of SSL_ERROR_WANT_WRITE, SSL_ERROR_WANT_READ:
          if async:
            return
          else: SSLError("Not enough data on socket.")
        of SSL_ERROR_WANT_X509_LOOKUP:
          SSLError("Function for x509 lookup has been called.")
        of SSL_ERROR_SYSCALL, SSL_ERROR_SSL:
          SSLError()
        else: SSLError("Unknown Error")
  
  if err == -1 and not (when defined(ssl): socket.isSSL else: false):
    let lastError = osLastError()
    if async:
      when defined(windows):
        if lastError.int32 == WSAEWOULDBLOCK:
          return
        else: osError(lastError)
      else:
        if lastError.int32 == EAGAIN or lastError.int32 == EWOULDBLOCK:
          return
        else: osError(lastError)
    else: osError(lastError)

proc listen*(socket: TSocket, backlog = SOMAXCONN) {.tags: [FReadIO].} =
  ## Marks ``socket`` as accepting connections. 
  ## ``Backlog`` specifies the maximum length of the 
  ## queue of pending connections.
  if listen(socket.fd, cint(backlog)) < 0'i32: osError(osLastError())

proc invalidIp4(s: string) {.noreturn, noinline.} =
  raise newException(EInvalidValue, "invalid ip4 address: " & s)

proc parseIp4*(s: string): BiggestInt = 
  ## parses an IP version 4 in dotted decimal form like "a.b.c.d".
  ##
  ## This is equivalent to `inet_ntoa`:idx:.
  ##
  ## Raises EInvalidValue in case of an error.
  var a, b, c, d: int
  var i = 0
  var j = parseInt(s, a, i)
  if j <= 0: invalidIp4(s)
  inc(i, j)
  if s[i] == '.': inc(i)
  else: invalidIp4(s)
  j = parseInt(s, b, i)
  if j <= 0: invalidIp4(s)
  inc(i, j)
  if s[i] == '.': inc(i)
  else: invalidIp4(s)
  j = parseInt(s, c, i)
  if j <= 0: invalidIp4(s)
  inc(i, j)
  if s[i] == '.': inc(i)
  else: invalidIp4(s)
  j = parseInt(s, d, i)
  if j <= 0: invalidIp4(s)
  inc(i, j)
  if s[i] != '\0': invalidIp4(s)
  result = BiggestInt(a shl 24 or b shl 16 or c shl 8 or d)

template gaiNim(a, p, h, list: expr): stmt =
  block:
    var gaiResult = getaddrinfo(a, $p, addr(h), list)
    if gaiResult != 0'i32:
      when defined(windows):
        osError(osLastError())
      else:
        raise newException(EOS, $gai_strerror(gaiResult))

proc bindAddr*(socket: TSocket, port = TPort(0), address = "") {.
  tags: [FReadIO].} =
  ## binds an address/port number to a socket.
  ## Use address string in dotted decimal form like "a.b.c.d"
  ## or leave "" for any address.

  if address == "":
    var name: Tsockaddr_in
    when defined(Windows):
      name.sin_family = int16(ord(AF_INET))
    else:
      name.sin_family = posix.AF_INET
    name.sin_port = sockets.htons(int16(port))
    name.sin_addr.s_addr = sockets.htonl(INADDR_ANY)
    if bindSocket(socket.fd, cast[ptr TSockAddr](addr(name)),
                  sizeof(name).TSocklen) < 0'i32:
      osError(osLastError())
  else:
    var hints: Taddrinfo
    var aiList: ptr Taddrinfo = nil
    hints.ai_family = toInt(AF_INET)
    hints.ai_socktype = toInt(SOCK_STREAM)
    hints.ai_protocol = toInt(IPPROTO_TCP)
    gaiNim(address, port, hints, aiList)
    if bindSocket(socket.fd, aiList.ai_addr, aiList.ai_addrlen.TSocklen) < 0'i32:
      osError(osLastError())
  
proc getSockName*(socket: TSocket): TPort = 
  ## returns the socket's associated port number.
  var name: Tsockaddr_in
  when defined(Windows):
    name.sin_family = int16(ord(AF_INET))
  else:
    name.sin_family = posix.AF_INET
  #name.sin_port = htons(cint16(port))
  #name.sin_addr.s_addr = htonl(INADDR_ANY)
  var namelen = sizeof(name).TSocklen
  if getsockname(socket.fd, cast[ptr TSockAddr](addr(name)),
                 addr(namelen)) == -1'i32:
    osError(osLastError())
  result = TPort(sockets.ntohs(name.sin_port))

template acceptAddrPlain(noClientRet, successRet: expr, 
                         sslImplementation: stmt): stmt {.immediate.} =
  assert(client != nil)
  var sockAddress: Tsockaddr_in
  var addrLen = sizeof(sockAddress).TSocklen
  var sock = accept(server.fd, cast[ptr TSockAddr](addr(sockAddress)),
                    addr(addrLen))
  
  if sock == osInvalidSocket:
    let err = osLastError()
    when defined(windows):
      if err.int32 == WSAEINPROGRESS:
        client = invalidSocket
        address = ""
        when noClientRet.int == -1:
          return
        else:
          return noClientRet
      else: osError(err)
    else:
      if err.int32 == EAGAIN or err.int32 == EWOULDBLOCK:
        client = invalidSocket
        address = ""
        when noClientRet.int == -1:
          return
        else:
          return noClientRet
      else: osError(err)
  else:
    client.fd = sock
    client.isBuffered = server.isBuffered
    sslImplementation
    # Client socket is set above.
    address = $inet_ntoa(sockAddress.sin_addr)
    when successRet.int == -1:
      return
    else:
      return successRet

proc acceptAddr*(server: TSocket, client: var TSocket, address: var string) {.
  tags: [FReadIO].} =
  ## Blocks until a connection is being made from a client. When a connection
  ## is made sets ``client`` to the client socket and ``address`` to the address
  ## of the connecting client.
  ## If ``server`` is non-blocking then this function returns immediately, and
  ## if there are no connections queued the returned socket will be
  ## ``InvalidSocket``.
  ## This function will raise EOS if an error occurs.
  ##
  ## The resulting client will inherit any properties of the server socket. For
  ## example: whether the socket is buffered or not.
  ##
  ## **Note**: ``client`` must be initialised (with ``new``), this function 
  ## makes no effort to initialise the ``client`` variable.
  ##
  ## **Warning:** When using SSL with non-blocking sockets, it is best to use
  ## the acceptAddrSSL procedure as this procedure will most likely block.
  acceptAddrPlain(-1, -1):
    when defined(ssl):
      if server.isSSL:
        # We must wrap the client sock in a ssl context.
        
        server.sslContext.wrapSocket(client)
        let ret = SSLAccept(client.sslHandle)
        while ret <= 0:
          let err = SSLGetError(client.sslHandle, ret)
          if err != SSL_ERROR_WANT_ACCEPT:
            case err
            of SSL_ERROR_ZERO_RETURN:
              SSLError("TLS/SSL connection failed to initiate, socket closed prematurely.")
            of SSL_ERROR_WANT_READ, SSL_ERROR_WANT_WRITE,
               SSL_ERROR_WANT_CONNECT, SSL_ERROR_WANT_ACCEPT:
              SSLError("acceptAddrSSL should be used for non-blocking SSL sockets.")
            of SSL_ERROR_WANT_X509_LOOKUP:
              SSLError("Function for x509 lookup has been called.")
            of SSL_ERROR_SYSCALL, SSL_ERROR_SSL:
              SSLError()
            else:
              SSLError("Unknown error")

proc setBlocking*(s: TSocket, blocking: bool) {.tags: [].}
  ## Sets blocking mode on socket

when defined(ssl):
  proc acceptAddrSSL*(server: TSocket, client: var TSocket,
                      address: var string): TSSLAcceptResult {.
                      tags: [FReadIO].} =
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
                SSLError("TLS/SSL connection failed to initiate, socket closed prematurely.")
              of SSL_ERROR_WANT_READ, SSL_ERROR_WANT_WRITE,
                 SSL_ERROR_WANT_CONNECT, SSL_ERROR_WANT_ACCEPT:
                client.sslNoHandshake = true
                return AcceptNoHandshake
              of SSL_ERROR_WANT_X509_LOOKUP:
                SSLError("Function for x509 lookup has been called.")
              of SSL_ERROR_SYSCALL, SSL_ERROR_SSL:
                SSLError()
              else:
                SSLError("Unknown error")
          client.sslNoHandshake = false

    if client.isSSL and client.sslNoHandshake:
      doHandshake()
      return AcceptSuccess
    else:
      acceptAddrPlain(AcceptNoClient, AcceptSuccess):
        doHandshake()

proc accept*(server: TSocket, client: var TSocket) {.tags: [FReadIO].} =
  ## Equivalent to ``acceptAddr`` but doesn't return the address, only the
  ## socket.
  ## 
  ## **Note**: ``client`` must be initialised (with ``new``), this function
  ## makes no effort to initialise the ``client`` variable.
  
  var addrDummy = ""
  acceptAddr(server, client, addrDummy)

proc acceptAddr*(server: TSocket): tuple[client: TSocket, address: string] {.
  deprecated, tags: [FReadIO].} =
  ## Slightly different version of ``acceptAddr``.
  ##
  ## **Deprecated since version 0.9.0:** Please use the function above.
  var client: TSocket
  new(client)
  var address = ""
  acceptAddr(server, client, address)
  return (client, address)

proc accept*(server: TSocket): TSocket {.deprecated, tags: [FReadIO].} =
  ## **Deprecated since version 0.9.0:** Please use the function above.
  new(result)
  var address = ""
  acceptAddr(server, result, address)

proc close*(socket: TSocket) =
  ## closes a socket.
  when defined(windows):
    discard winlean.closesocket(socket.fd)
  else:
    discard posix.close(socket.fd)
  # TODO: These values should not be discarded. An EOS should be raised.
  # http://stackoverflow.com/questions/12463473/what-happens-if-you-call-close-on-a-bsd-socket-multiple-times
  when defined(ssl):
    if socket.isSSL:
      discard SSLShutdown(socket.sslHandle)

proc getServByName*(name, proto: string): TServent {.tags: [FReadIO].} =
  ## Searches the database from the beginning and finds the first entry for 
  ## which the service name specified by ``name`` matches the s_name member
  ## and the protocol name specified by ``proto`` matches the s_proto member.
  ##
  ## On posix this will search through the ``/etc/services`` file.
  when defined(Windows):
    var s = winlean.getservbyname(name, proto)
  else:
    var s = posix.getservbyname(name, proto)
  if s == nil: raise newException(EOS, "Service not found.")
  result.name = $s.s_name
  result.aliases = cstringArrayToSeq(s.s_aliases)
  result.port = TPort(s.s_port)
  result.proto = $s.s_proto
  
proc getServByPort*(port: TPort, proto: string): TServent {.tags: [FReadIO].} = 
  ## Searches the database from the beginning and finds the first entry for 
  ## which the port specified by ``port`` matches the s_port member and the 
  ## protocol name specified by ``proto`` matches the s_proto member.
  ##
  ## On posix this will search through the ``/etc/services`` file.
  when defined(Windows):
    var s = winlean.getservbyport(ze(int16(port)).cint, proto)
  else:
    var s = posix.getservbyport(ze(int16(port)).cint, proto)
  if s == nil: raise newException(EOS, "Service not found.")
  result.name = $s.s_name
  result.aliases = cstringArrayToSeq(s.s_aliases)
  result.port = TPort(s.s_port)
  result.proto = $s.s_proto

proc getHostByAddr*(ip: string): Thostent {.tags: [FReadIO].} =
  ## This function will lookup the hostname of an IP Address.
  var myaddr: TInAddr
  myaddr.s_addr = inet_addr(ip)
  
  when defined(windows):
    var s = winlean.gethostbyaddr(addr(myaddr), sizeof(myaddr).cuint,
                                  cint(sockets.AF_INET))
    if s == nil: osError(osLastError())
  else:
    var s = posix.gethostbyaddr(addr(myaddr), sizeof(myaddr).TSocklen, 
                                cint(posix.AF_INET))
    if s == nil:
      raise newException(EOS, $hstrerror(h_errno))
  
  result.name = $s.h_name
  result.aliases = cstringArrayToSeq(s.h_aliases)
  when defined(windows): 
    result.addrtype = TDomain(s.h_addrtype)
  else:
    if s.h_addrtype == posix.AF_INET:
      result.addrtype = AF_INET
    elif s.h_addrtype == posix.AF_INET6:
      result.addrtype = AF_INET6
    else:
      raise newException(EOS, "unknown h_addrtype")
  result.addrList = cstringArrayToSeq(s.h_addr_list)
  result.length = int(s.h_length)

proc getHostByName*(name: string): Thostent {.tags: [FReadIO].} = 
  ## This function will lookup the IP address of a hostname.
  when defined(Windows):
    var s = winlean.gethostbyname(name)
  else:
    var s = posix.gethostbyname(name)
  if s == nil: osError(osLastError())
  result.name = $s.h_name
  result.aliases = cstringArrayToSeq(s.h_aliases)
  when defined(windows): 
    result.addrtype = TDomain(s.h_addrtype)
  else:
    if s.h_addrtype == posix.AF_INET:
      result.addrtype = AF_INET
    elif s.h_addrtype == posix.AF_INET6:
      result.addrtype = AF_INET6
    else:
      raise newException(EOS, "unknown h_addrtype")
  result.addrList = cstringArrayToSeq(s.h_addr_list)
  result.length = int(s.h_length)

proc getSockOptInt*(socket: TSocket, level, optname: int): int {.
  tags: [FReadIO].} = 
  ## getsockopt for integer options.
  var res: cint
  var size = sizeof(res).TSocklen
  if getsockopt(socket.fd, cint(level), cint(optname), 
                addr(res), addr(size)) < 0'i32:
    osError(osLastError())
  result = int(res)

proc setSockOptInt*(socket: TSocket, level, optname, optval: int) {.
  tags: [FWriteIO].} =
  ## setsockopt for integer options.
  var value = cint(optval)
  if setsockopt(socket.fd, cint(level), cint(optname), addr(value),  
                sizeof(value).TSocklen) < 0'i32:
    osError(osLastError())

proc toCInt(opt: TSOBool): cint =
  case opt
  of OptAcceptConn: SO_ACCEPTCONN
  of OptBroadcast: SO_BROADCAST
  of OptDebug: SO_DEBUG
  of OptDontRoute: SO_DONTROUTE
  of OptKeepAlive: SO_KEEPALIVE
  of OptOOBInline: SO_OOBINLINE
  of OptReuseAddr: SO_REUSEADDR

proc getSockOpt*(socket: TSocket, opt: TSOBool, level = SOL_SOCKET): bool {.
  tags: [FReadIO].} =
  ## Retrieves option ``opt`` as a boolean value.
  var res: cint
  var size = sizeof(res).TSocklen
  if getsockopt(socket.fd, cint(level), toCInt(opt), 
                addr(res), addr(size)) < 0'i32:
    osError(osLastError())
  result = res != 0

proc setSockOpt*(socket: TSocket, opt: TSOBool, value: bool, level = SOL_SOCKET) {.
  tags: [FWriteIO].} =
  ## Sets option ``opt`` to a boolean value specified by ``value``.
  var valuei = cint(if value: 1 else: 0)
  if setsockopt(socket.fd, cint(level), toCInt(opt), addr(valuei),  
                sizeof(valuei).TSocklen) < 0'i32:
    osError(osLastError())

proc connect*(socket: TSocket, address: string, port = TPort(0), 
              af: TDomain = AF_INET) {.tags: [FReadIO].} =
  ## Connects socket to ``address``:``port``. ``Address`` can be an IP address or a
  ## host name. If ``address`` is a host name, this function will try each IP
  ## of that host name. ``htons`` is already performed on ``port`` so you must
  ## not do it.
  ##
  ## If ``socket`` is an SSL socket a handshake will be automatically performed.
  var hints: Taddrinfo
  var aiList: ptr Taddrinfo = nil
  hints.ai_family = toInt(af)
  hints.ai_socktype = toInt(SOCK_STREAM)
  hints.ai_protocol = toInt(IPPROTO_TCP)
  gaiNim(address, port, hints, aiList)
  # try all possibilities:
  var success = false
  var lastError: TOSErrorCode
  var it = aiList
  while it != nil:
    if connect(socket.fd, it.ai_addr, it.ai_addrlen.TSocklen) == 0'i32:
      success = true
      break
    else: lastError = osLastError()
    it = it.ai_next

  freeaddrinfo(aiList)
  if not success: osError(lastError)
  
  when defined(ssl):
    if socket.isSSL:
      let ret = SSLConnect(socket.sslHandle)
      if ret <= 0:
        let err = SSLGetError(socket.sslHandle, ret)
        case err
        of SSL_ERROR_ZERO_RETURN:
          SSLError("TLS/SSL connection failed to initiate, socket closed prematurely.")
        of SSL_ERROR_WANT_READ, SSL_ERROR_WANT_WRITE, SSL_ERROR_WANT_CONNECT, 
           SSL_ERROR_WANT_ACCEPT:
          SSLError("The operation did not complete. Perhaps you should use connectAsync?")
        of SSL_ERROR_WANT_X509_LOOKUP:
          SSLError("Function for x509 lookup has been called.")
        of SSL_ERROR_SYSCALL, SSL_ERROR_SSL:
          SSLError()
        else:
          SSLError("Unknown error")
        
  when false:
    var s: TSockAddrIn
    s.sin_addr.s_addr = inet_addr(address)
    s.sin_port = sockets.htons(int16(port))
    when defined(windows):
      s.sin_family = toU16(ord(af))
    else:
      case af 
      of AF_UNIX: s.sin_family = posix.AF_UNIX
      of AF_INET: s.sin_family = posix.AF_INET
      of AF_INET6: s.sin_family = posix.AF_INET6
      else: nil
    if connect(socket.fd, cast[ptr TSockAddr](addr(s)), sizeof(s).cint) < 0'i32:
      OSError()

proc connectAsync*(socket: TSocket, name: string, port = TPort(0),
                     af: TDomain = AF_INET) {.tags: [FReadIO].} =
  ## A variant of ``connect`` for non-blocking sockets.
  ##
  ## This procedure will immediatelly return, it will not block until a connection
  ## is made. It is up to the caller to make sure the connection has been established
  ## by checking (using ``select``) whether the socket is writeable.
  ##
  ## **Note**: For SSL sockets, the ``handshake`` procedure must be called
  ## whenever the socket successfully connects to a server.
  var hints: Taddrinfo
  var aiList: ptr Taddrinfo = nil
  hints.ai_family = toInt(af)
  hints.ai_socktype = toInt(SOCK_STREAM)
  hints.ai_protocol = toInt(IPPROTO_TCP)
  gaiNim(name, port, hints, aiList)
  # try all possibilities:
  var success = false
  var lastError: TOSErrorCode
  var it = aiList
  while it != nil:
    var ret = connect(socket.fd, it.ai_addr, it.ai_addrlen.TSocklen)
    if ret == 0'i32:
      success = true
      break
    else:
      lastError = osLastError()
      when defined(windows):
        # Windows EINTR doesn't behave same as POSIX.
        if lastError.int32 == WSAEWOULDBLOCK:
          success = true
          break
      else:
        if lastError.int32 == EINTR or lastError.int32 == EINPROGRESS:
          success = true
          break
        
    it = it.ai_next

  freeaddrinfo(aiList)
  if not success: osError(lastError)
  when defined(ssl):
    if socket.isSSL:
      socket.sslNoHandshake = true

when defined(ssl):
  proc handshake*(socket: TSocket): bool {.tags: [FReadIO, FWriteIO].} =
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
          SSLError("TLS/SSL connection failed to initiate, socket closed prematurely.")
        of SSL_ERROR_WANT_CONNECT, SSL_ERROR_WANT_ACCEPT,
          SSL_ERROR_WANT_READ, SSL_ERROR_WANT_WRITE:
          return false
        of SSL_ERROR_WANT_X509_LOOKUP:
          SSLError("Function for x509 lookup has been called.")
        of SSL_ERROR_SYSCALL, SSL_ERROR_SSL:
          SSLError()
        else:
          SSLError("Unknown Error")
      socket.sslNoHandshake = false
    else:
      SSLError("Socket is not an SSL socket.")

  proc gotHandshake*(socket: TSocket): bool =
    ## Determines whether a handshake has occurred between a client (``socket``)
    ## and the server that ``socket`` is connected to.
    ##
    ## Throws ESSL if ``socket`` is not an SSL socket.
    if socket.isSSL:
      return not socket.sslNoHandshake
    else:
      SSLError("Socket is not an SSL socket.")

proc timeValFromMilliseconds(timeout = 500): Ttimeval =
  if timeout != -1:
    var seconds = timeout div 1000
    result.tv_sec = seconds.int32
    result.tv_usec = ((timeout - seconds * 1000) * 1000).int32

proc createFdSet(fd: var TFdSet, s: seq[TSocket], m: var int) = 
  FD_ZERO(fd)
  for i in items(s): 
    m = max(m, int(i.fd))
    FD_SET(i.fd, fd)
   
proc pruneSocketSet(s: var seq[TSocket], fd: var TFdSet) =
  var newSet: seq[TSocket] = @[]
  for sock in s:
    if FD_ISSET(sock.fd, fd) == 1'i32:
      ## Is set.
      newSet.add(sock)
  s = newSet

proc hasDataBuffered*(s: TSocket): bool =
  ## Determines whether a socket has data buffered.
  result = false
  if s.isBuffered:
    result = s.bufLen > 0 and s.currPos != s.bufLen

  when defined(ssl):
    if s.isSSL and not result:
      result = s.sslHasPeekChar

proc checkBuffer(readfds: var seq[TSocket]): int =
  ## Checks the buffer of each socket in ``readfds`` to see whether there is data.
  ## Removes the sockets from ``readfds`` and returns the count of removed sockets.
  var res: seq[TSocket] = @[]
  result = 0
  for s in readfds:
    if hasDataBuffered(s):
      inc(result)
      res.add(s)
  if result > 0:
    readfds = res

proc select*(readfds, writefds, exceptfds: var seq[TSocket], 
             timeout = 500): int {.tags: [FReadIO].} = 
  ## Traditional select function. This function will return the number of
  ## sockets that are ready to be read from, written to, or which have errors.
  ## If there are none; 0 is returned. 
  ## ``Timeout`` is in miliseconds and -1 can be specified for no timeout.
  ## 
  ## Sockets which are **not** ready for reading, writing or which don't have
  ## errors waiting on them are removed from the ``readfds``, ``writefds``,
  ## ``exceptfds`` sequences respectively.
  let buffersFilled = checkBuffer(readfds)
  if buffersFilled > 0:
    return buffersFilled

  var tv {.noInit.}: Ttimeval = timeValFromMilliseconds(timeout)
  
  var rd, wr, ex: TFdSet
  var m = 0
  createFdSet((rd), readfds, m)
  createFdSet((wr), writefds, m)
  createFdSet((ex), exceptfds, m)
  
  if timeout != -1:
    result = int(select(cint(m+1), addr(rd), addr(wr), addr(ex), addr(tv)))
  else:
    result = int(select(cint(m+1), addr(rd), addr(wr), addr(ex), nil))
  
  pruneSocketSet(readfds, (rd))
  pruneSocketSet(writefds, (wr))
  pruneSocketSet(exceptfds, (ex))

proc select*(readfds, writefds: var seq[TSocket], 
             timeout = 500): int {.tags: [FReadIO].} =
  ## Variant of select with only a read and write list.
  let buffersFilled = checkBuffer(readfds)
  if buffersFilled > 0:
    return buffersFilled
  var tv {.noInit.}: Ttimeval = timeValFromMilliseconds(timeout)
  
  var rd, wr: TFdSet
  var m = 0
  createFdSet((rd), readfds, m)
  createFdSet((wr), writefds, m)
  
  if timeout != -1:
    result = int(select(cint(m+1), addr(rd), addr(wr), nil, addr(tv)))
  else:
    result = int(select(cint(m+1), addr(rd), addr(wr), nil, nil))
  
  pruneSocketSet(readfds, (rd))
  pruneSocketSet(writefds, (wr))

proc selectWrite*(writefds: var seq[TSocket], 
                  timeout = 500): int {.tags: [FReadIO].} =
  ## When a socket in ``writefds`` is ready to be written to then a non-zero
  ## value will be returned specifying the count of the sockets which can be
  ## written to. The sockets which **cannot** be written to will also be removed
  ## from ``writefds``.
  ##
  ## ``timeout`` is specified in miliseconds and ``-1`` can be specified for
  ## an unlimited time.
  var tv {.noInit.}: Ttimeval = timeValFromMilliseconds(timeout)
  
  var wr: TFdSet
  var m = 0
  createFdSet((wr), writefds, m)
  
  if timeout != -1:
    result = int(select(cint(m+1), nil, addr(wr), nil, addr(tv)))
  else:
    result = int(select(cint(m+1), nil, addr(wr), nil, nil))
  
  pruneSocketSet(writefds, (wr))

proc select*(readfds: var seq[TSocket], timeout = 500): int =
  ## variant of select with a read list only
  let buffersFilled = checkBuffer(readfds)
  if buffersFilled > 0:
    return buffersFilled
  var tv {.noInit.}: Ttimeval = timeValFromMilliseconds(timeout)
  
  var rd: TFdSet
  var m = 0
  createFdSet((rd), readfds, m)
  
  if timeout != -1:
    result = int(select(cint(m+1), addr(rd), nil, nil, addr(tv)))
  else:
    result = int(select(cint(m+1), addr(rd), nil, nil, nil))
  
  pruneSocketSet(readfds, (rd))

proc readIntoBuf(socket: TSocket, flags: int32): int =
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

proc recv*(socket: TSocket, data: pointer, size: int): int {.tags: [FReadIO].} =
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

proc waitFor(socket: TSocket, waited: var float, timeout, size: int,
             funcName: string): int {.tags: [FTime].} =
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
      raise newException(ETimeout, "Call to '" & funcName & "' timed out.")
    
    when defined(ssl):
      if socket.isSSL:
        if socket.hasDataBuffered:
          # sslPeekChar is present.
          return 1
        let sslPending = SSLPending(socket.sslHandle)
        if sslPending != 0:
          return sslPending
    
    var s = @[socket]
    var startTime = epochTime()
    let selRet = select(s, timeout - int(waited * 1000.0))
    if selRet < 0: osError(osLastError())
    if selRet != 1:
      raise newException(ETimeout, "Call to '" & funcName & "' timed out.")
    waited += (epochTime() - startTime)

proc recv*(socket: TSocket, data: pointer, size: int, timeout: int): int {.
  tags: [FReadIO, FTime].} =
  ## overload with a ``timeout`` parameter in miliseconds.
  var waited = 0.0 # number of seconds already waited  
  
  var read = 0
  while read < size:
    let avail = waitFor(socket, waited, timeout, size-read, "recv")
    var d = cast[cstring](data)
    result = recv(socket, addr(d[read]), avail)
    if result == 0: break
    if result < 0:
      return result
    inc(read, result)
  
  result = read

proc recv*(socket: TSocket, data: var string, size: int, timeout = -1): int =
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
  data.setLen(size)
  result = recv(socket, cstring(data), size, timeout)
  if result < 0:
    data.setLen(0)
    socket.socketError(result)
  data.setLen(result)

proc recvAsync*(socket: TSocket, data: var string, size: int): int =
  ## Async version of ``recv``.
  ##
  ## When socket is non-blocking and no data is available on the socket,
  ## ``-1`` will be returned and ``data`` will be ``""``.
  ##
  ## **Note**: ``data`` must be initialised.
  data.setLen(size)
  result = recv(socket, cstring(data), size)
  if result < 0:
    data.setLen(0)
    socket.socketError(async = true)
    result = -1
  data.setLen(result)

proc peekChar(socket: TSocket, c: var char): int {.tags: [FReadIO].} =
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

proc recvLine*(socket: TSocket, line: var TaintedString, timeout = -1): bool {.
  tags: [FReadIO, FTime], deprecated.} =
  ## Receive a line of data from ``socket``.
  ##
  ## If a full line is received ``\r\L`` is not
  ## added to ``line``, however if solely ``\r\L`` is received then ``line``
  ## will be set to it.
  ## 
  ## ``True`` is returned if data is available. ``False`` suggests an
  ## error, EOS exceptions are not raised and ``False`` is simply returned
  ## instead.
  ## 
  ## If the socket is disconnected, ``line`` will be set to ``""`` and ``True``
  ## will be returned.
  ##
  ## A timeout can be specified in miliseconds, if data is not received within
  ## the specified time an ETimeout exception will be raised.
  ##
  ## **Deprecated since version 0.9.2**: This function has been deprecated in
  ## favour of readLine.
  
  template addNLIfEmpty(): stmt =
    if line.len == 0:
      line.add("\c\L")

  var waited = 0.0

  setLen(line.string, 0)
  while true:
    var c: char
    discard waitFor(socket, waited, timeout, 1, "recvLine")
    var n = recv(socket, addr(c), 1)
    if n < 0: return
    elif n == 0: return true
    if c == '\r':
      discard waitFor(socket, waited, timeout, 1, "recvLine")
      n = peekChar(socket, c)
      if n > 0 and c == '\L':
        discard recv(socket, addr(c), 1)
      elif n <= 0: return false
      addNLIfEmpty()
      return true
    elif c == '\L': 
      addNLIfEmpty()
      return true
    add(line.string, c)

proc readLine*(socket: TSocket, line: var TaintedString, timeout = -1) {.
  tags: [FReadIO, FTime].} =
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
  
  template addNLIfEmpty(): stmt =
    if line.len == 0:
      line.add("\c\L")

  var waited = 0.0

  setLen(line.string, 0)
  while true:
    var c: char
    discard waitFor(socket, waited, timeout, 1, "readLine")
    var n = recv(socket, addr(c), 1)
    if n < 0: socket.socketError()
    elif n == 0: return
    if c == '\r':
      discard waitFor(socket, waited, timeout, 1, "readLine")
      n = peekChar(socket, c)
      if n > 0 and c == '\L':
        discard recv(socket, addr(c), 1)
      elif n <= 0: socket.socketError()
      addNLIfEmpty()
      return
    elif c == '\L': 
      addNLIfEmpty()
      return
    add(line.string, c)

proc recvLineAsync*(socket: TSocket, 
  line: var TaintedString): TRecvLineResult {.tags: [FReadIO], deprecated.} =
  ## Similar to ``recvLine`` but designed for non-blocking sockets.
  ##
  ## The values of the returned enum should be pretty self explanatory:
  ##
  ##   * If a full line has been retrieved; ``RecvFullLine`` is returned.
  ##   * If some data has been retrieved; ``RecvPartialLine`` is returned.
  ##   * If the socket has been disconnected; ``RecvDisconnected`` is returned.
  ##   * If call to ``recv`` failed; ``RecvFail`` is returned.
  ##
  ## **Deprecated since version 0.9.2**: This function has been deprecated in
  ## favour of readLineAsync.

  setLen(line.string, 0)
  while true:
    var c: char
    var n = recv(socket, addr(c), 1)
    if n < 0: 
      return (if line.len == 0: RecvFail else: RecvPartialLine)
    elif n == 0: 
      return (if line.len == 0: RecvDisconnected else: RecvPartialLine)
    if c == '\r':
      n = peekChar(socket, c)
      if n > 0 and c == '\L':
        discard recv(socket, addr(c), 1)
      elif n <= 0: 
        return (if line.len == 0: RecvFail else: RecvPartialLine)
      return RecvFullLine
    elif c == '\L': return RecvFullLine
    add(line.string, c)

proc readLineAsync*(socket: TSocket, 
  line: var TaintedString): TReadLineResult {.tags: [FReadIO].} =
  ## Similar to ``recvLine`` but designed for non-blocking sockets.
  ##
  ## The values of the returned enum should be pretty self explanatory:
  ##
  ##   * If a full line has been retrieved; ``ReadFullLine`` is returned.
  ##   * If some data has been retrieved; ``ReadPartialLine`` is returned.
  ##   * If the socket has been disconnected; ``ReadDisconnected`` is returned.
  ##   * If no data could be retrieved; ``ReadNone`` is returned.
  ##   * If call to ``recv`` failed; **an EOS exception is raised.**
  setLen(line.string, 0)
  
  template errorOrNone =
    socket.socketError(async = true)
    return ReadNone
  
  while true:
    var c: char
    var n = recv(socket, addr(c), 1)
    #echo(n)
    if n < 0:
      if line.len == 0: errorOrNone else: return ReadPartialLine
    elif n == 0: 
      return (if line.len == 0: ReadDisconnected else: ReadPartialLine)
    if c == '\r':
      n = peekChar(socket, c)
      if n > 0 and c == '\L':
        discard recv(socket, addr(c), 1)
      elif n <= 0: 
        if line.len == 0: errorOrNone else: return ReadPartialLine
      return ReadFullLine
    elif c == '\L': return ReadFullLine
    add(line.string, c)

proc recv*(socket: TSocket): TaintedString {.tags: [FReadIO], deprecated.} =
  ## receives all the available data from the socket.
  ## Socket errors will result in an ``EOS`` error.
  ## If socket is not a connectionless socket and socket is not connected
  ## ``""`` will be returned.
  ##
  ## **Deprecated since version 0.9.2**: This function is not safe for use.
  const bufSize = 4000
  result = newStringOfCap(bufSize).TaintedString
  var pos = 0
  while true:
    var bytesRead = recv(socket, addr(string(result)[pos]), bufSize-1)
    if bytesRead == -1: osError(osLastError())
    setLen(result.string, pos + bytesRead)
    if bytesRead != bufSize-1: break
    # increase capacity:
    setLen(result.string, result.string.len + bufSize)
    inc(pos, bytesRead)
  when false:
    var buf = newString(bufSize)
    result = TaintedString""
    while true:
      var bytesRead = recv(socket, cstring(buf), bufSize-1)
      # Error
      if bytesRead == -1: OSError(OSLastError())
      
      buf[bytesRead] = '\0' # might not be necessary
      setLen(buf, bytesRead)
      add(result.string, buf)
      if bytesRead != bufSize-1: break

{.push warning[deprecated]: off.}
proc recvTimeout*(socket: TSocket, timeout: int): TaintedString {.
  tags: [FReadIO], deprecated.} =
  ## overloaded variant to support a ``timeout`` parameter, the ``timeout``
  ## parameter specifies the amount of miliseconds to wait for data on the
  ## socket.
  ##
  ## **Deprecated since version 0.9.2**: This function is not safe for use.
  if socket.bufLen == 0:
    var s = @[socket]
    if s.select(timeout) != 1:
      raise newException(ETimeout, "Call to recv() timed out.")
  
  return socket.recv
{.pop.}

proc recvAsync*(socket: TSocket, s: var TaintedString): bool {.
  tags: [FReadIO], deprecated.} =
  ## receives all the data from a non-blocking socket. If socket is non-blocking 
  ## and there are no messages available, `False` will be returned.
  ## Other socket errors will result in an ``EOS`` error.
  ## If socket is not a connectionless socket and socket is not connected
  ## ``s`` will be set to ``""``.
  ##
  ## **Deprecated since version 0.9.2**: This function is not safe for use.
  const bufSize = 1000
  # ensure bufSize capacity:
  setLen(s.string, bufSize)
  setLen(s.string, 0)
  var pos = 0
  while true:
    var bytesRead = recv(socket, addr(string(s)[pos]), bufSize-1)
    when defined(ssl):
      if socket.isSSL:
        if bytesRead <= 0:
          var ret = SSLGetError(socket.sslHandle, bytesRead.cint)
          case ret
          of SSL_ERROR_ZERO_RETURN:
            SSLError("TLS/SSL connection failed to initiate, socket closed prematurely.")
          of SSL_ERROR_WANT_CONNECT, SSL_ERROR_WANT_ACCEPT:
            SSLError("Unexpected error occured.") # This should just not happen.
          of SSL_ERROR_WANT_WRITE, SSL_ERROR_WANT_READ:
            return false
          of SSL_ERROR_WANT_X509_LOOKUP:
            SSLError("Function for x509 lookup has been called.")
          of SSL_ERROR_SYSCALL, SSL_ERROR_SSL:
            SSLError()
          else: SSLError("Unknown Error")
          
    if bytesRead == -1 and not (when defined(ssl): socket.isSSL else: false):
      let err = osLastError()
      when defined(windows):
        if err.int32 == WSAEWOULDBLOCK:
          return false
        else: osError(err)
      else:
        if err.int32 == EAGAIN or err.int32 == EWOULDBLOCK:
          return false
        else: osError(err)

    setLen(s.string, pos + bytesRead)
    if bytesRead != bufSize-1: break
    # increase capacity:
    setLen(s.string, s.string.len + bufSize)
    inc(pos, bytesRead)
  result = true

proc recvFrom*(socket: TSocket, data: var string, length: int,
               address: var string, port: var TPort, flags = 0'i32): int {.
               tags: [FReadIO].} =
  ## Receives data from ``socket``. This function should normally be used with
  ## connection-less sockets (UDP sockets).
  ##
  ## If an error occurs the return value will be ``-1``. Otherwise the return
  ## value will be the length of data received.
  ##
  ## **Warning:** This function does not yet have a buffered implementation,
  ## so when ``socket`` is buffered the non-buffered implementation will be
  ## used. Therefore if ``socket`` contains something in its buffer this
  ## function will make no effort to return it.
  
  # TODO: Buffered sockets
  data.setLen(length)
  var sockAddress: Tsockaddr_in
  var addrLen = sizeof(sockAddress).TSocklen
  result = recvfrom(socket.fd, cstring(data), length.cint, flags.cint,
                    cast[ptr TSockAddr](addr(sockAddress)), addr(addrLen))

  if result != -1:
    data.setLen(result)
    address = $inet_ntoa(sockAddress.sin_addr)
    port = ntohs(sockAddress.sin_port).TPort

proc recvFromAsync*(socket: TSocket, data: var string, length: int,
                    address: var string, port: var TPort, 
                    flags = 0'i32): bool {.tags: [FReadIO].} =
  ## Variant of ``recvFrom`` for non-blocking sockets. Unlike ``recvFrom``,
  ## this function will raise an EOS error whenever a socket error occurs.
  ##
  ## If there is no data to be read from the socket ``False`` will be returned.
  result = true
  var callRes = recvFrom(socket, data, length, address, port, flags)
  if callRes < 0:
    let err = osLastError()
    when defined(windows):
      if err.int32 == WSAEWOULDBLOCK:
        return false
      else: osError(err)
    else:
      if err.int32 == EAGAIN or err.int32 == EWOULDBLOCK:
        return false
      else: osError(err)

proc skip*(socket: TSocket) {.tags: [FReadIO], deprecated.} =
  ## skips all the data that is pending for the socket
  ##
  ## **Deprecated since version 0.9.2**: This function is not safe for use.
  const bufSize = 1000
  var buf = alloc(bufSize)
  while recv(socket, buf, bufSize) == bufSize: discard
  dealloc(buf)

proc skip*(socket: TSocket, size: int, timeout = -1) =
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

proc send*(socket: TSocket, data: pointer, size: int): int {.
  tags: [FWriteIO].} =
  ## sends data to a socket.
  when defined(ssl):
    if socket.isSSL:
      return SSLWrite(socket.sslHandle, cast[cstring](data), size)
  
  when defined(windows) or defined(macosx):
    result = send(socket.fd, data, size.cint, 0'i32)
  else:
    when defined(solaris): 
      const MSG_NOSIGNAL = 0
    result = send(socket.fd, data, size, int32(MSG_NOSIGNAL))

proc send*(socket: TSocket, data: string) {.tags: [FWriteIO].} =
  ## sends data to a socket.
  if socket.nonblocking:
    raise newException(EInvalidValue, "This function cannot be used on non-blocking sockets.")
  let sent = send(socket, cstring(data), data.len)
  if sent < 0:
    when defined(ssl):
      if socket.isSSL:
        SSLError()
    
    osError(osLastError())

  if sent != data.len:
    raise newException(EOS, "Could not send all data.")

proc sendAsync*(socket: TSocket, data: string): int {.tags: [FWriteIO].} =
  ## sends data to a non-blocking socket.
  ## Returns ``0`` if no data could be sent, if data has been sent
  ## returns the amount of bytes of ``data`` that was successfully sent. This
  ## number may not always be the length of ``data`` but typically is.
  ##
  ## An EOS (or ESSL if socket is an SSL socket) exception is raised if an error
  ## occurs.
  result = send(socket, cstring(data), data.len)
  when defined(ssl):
    if socket.isSSL:
      if result <= 0:
          let ret = SSLGetError(socket.sslHandle, result.cint)
          case ret
          of SSL_ERROR_ZERO_RETURN:
            SSLError("TLS/SSL connection failed to initiate, socket closed prematurely.")
          of SSL_ERROR_WANT_CONNECT, SSL_ERROR_WANT_ACCEPT:
            SSLError("Unexpected error occured.") # This should just not happen.
          of SSL_ERROR_WANT_WRITE, SSL_ERROR_WANT_READ:
            return 0
          of SSL_ERROR_WANT_X509_LOOKUP:
            SSLError("Function for x509 lookup has been called.")
          of SSL_ERROR_SYSCALL, SSL_ERROR_SSL:
            SSLError()
          else: SSLError("Unknown Error")
      else:
        return
  if result == -1:
    let err = osLastError()
    when defined(windows):
      if err.int32 == WSAEINPROGRESS:
        return 0
      else: osError(err)
    else:
      if err.int32 == EAGAIN or err.int32 == EWOULDBLOCK:
        return 0
      else: osError(err)
  

proc trySend*(socket: TSocket, data: string): bool {.tags: [FWriteIO].} =
  ## safe alternative to ``send``. Does not raise an EOS when an error occurs,
  ## and instead returns ``false`` on failure.
  result = send(socket, cstring(data), data.len) == data.len

proc sendTo*(socket: TSocket, address: string, port: TPort, data: pointer,
             size: int, af: TDomain = AF_INET, flags = 0'i32): int {.
             tags: [FWriteIO].} =
  ## low-level sendTo proc. This proc sends ``data`` to the specified ``address``,
  ## which may be an IP address or a hostname, if a hostname is specified 
  ## this function will try each IP of that hostname.
  ##
  ## **Note:** This proc is not available for SSL sockets.
  var hints: Taddrinfo
  var aiList: ptr Taddrinfo = nil
  hints.ai_family = toInt(af)
  hints.ai_socktype = toInt(SOCK_STREAM)
  hints.ai_protocol = toInt(IPPROTO_TCP)
  gaiNim(address, port, hints, aiList)
  
  # try all possibilities:
  var success = false
  var it = aiList
  while it != nil:
    result = sendto(socket.fd, data, size.cint, flags.cint, it.ai_addr,
                    it.ai_addrlen.TSocklen)
    if result != -1'i32:
      success = true
      break
    it = it.ai_next

  freeaddrinfo(aiList)

proc sendTo*(socket: TSocket, address: string, port: TPort, 
             data: string): int {.tags: [FWriteIO].} =
  ## Friendlier version of the low-level ``sendTo``.
  result = socket.sendTo(address, port, cstring(data), data.len)

when defined(Windows):
  const
    IOCPARM_MASK = 127
    IOC_IN = int(-2147483648)
    FIONBIO = IOC_IN.int32 or ((sizeof(int32) and IOCPARM_MASK) shl 16) or 
                             (102 shl 8) or 126

  proc ioctlsocket(s: TSocketHandle, cmd: clong, 
                   argptr: ptr clong): cint {.
                   stdcall, importc:"ioctlsocket", dynlib: "ws2_32.dll".}

proc setBlocking(s: TSocket, blocking: bool) =
  when defined(Windows):
    var mode = clong(ord(not blocking)) # 1 for non-blocking, 0 for blocking
    if ioctlsocket(s.fd, FIONBIO, addr(mode)) == -1:
      osError(osLastError())
  else: # BSD sockets
    var x: int = fcntl(s.fd, F_GETFL, 0)
    if x == -1:
      osError(osLastError())
    else:
      var mode = if blocking: x and not O_NONBLOCK else: x or O_NONBLOCK
      if fcntl(s.fd, F_SETFL, mode) == -1:
        osError(osLastError())
  s.nonblocking = not blocking

discard """ proc setReuseAddr*(s: TSocket) =
  var blah: int = 1
  var mode = SO_REUSEADDR
  if setsockopt(s.fd, SOL_SOCKET, mode, addr blah, TSOcklen(sizeof(int))) == -1:
    OSError(OSLastError()) """

proc connect*(socket: TSocket, address: string, port = TPort(0), timeout: int,
             af: TDomain = AF_INET) {.tags: [FReadIO, FWriteIO].} =
  ## Connects to server as specified by ``address`` on port specified by ``port``.
  ##
  ## The ``timeout`` paremeter specifies the time in miliseconds to allow for
  ## the connection to the server to be made.
  let originalStatus = not socket.nonblocking
  socket.setBlocking(false)
  
  socket.connectAsync(address, port, af)
  var s: seq[TSocket] = @[socket]
  if selectWrite(s, timeout) != 1:
    raise newException(ETimeout, "Call to 'connect' timed out.")
  else:
    when defined(ssl):
      if socket.isSSL:
        socket.setBlocking(true)
        doAssert socket.handshake()
  socket.setBlocking(originalStatus)

proc isSSL*(socket: TSocket): bool = return socket.isSSL
  ## Determines whether ``socket`` is a SSL socket.

proc getFD*(socket: TSocket): TSocketHandle = return socket.fd
  ## Returns the socket's file descriptor

proc isBlocking*(socket: TSocket): bool = not socket.nonblocking
  ## Determines whether ``socket`` is blocking.

when defined(Windows):
  var wsa: TWSAData
  if wsaStartup(0x0101'i16, addr wsa) != 0: osError(osLastError())


