#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2014 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a low-level cross-platform sockets interface. Look
## at the ``net`` module for the higher-level version.

import unsigned, os

when hostos == "solaris":
  {.passl: "-lsocket -lnsl".}

when defined(Windows):
  import winlean
else:
  import posix

export TSocketHandle, TSockaddr_in, TAddrinfo, INADDR_ANY, TSockAddr, TSockLen,
  inet_ntoa

type
  
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

when defined(windows):
  let
    OSInvalidSocket* = winlean.INVALID_SOCKET
else:
  let
    OSInvalidSocket* = posix.INVALID_SOCKET

proc `==`*(a, b: TPort): bool {.borrow.}
  ## ``==`` for ports.

proc `$`*(p: TPort): string {.borrow.}
  ## returns the port number as a string

proc toInt*(domain: TDomain): cint
  ## Converts the TDomain enum to a platform-dependent ``cint``.

proc toInt*(typ: TType): cint
  ## Converts the TType enum to a platform-dependent ``cint``.

proc toInt*(p: TProtocol): cint
  ## Converts the TProtocol enum to a platform-dependent ``cint``.

when defined(posix):
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
             protocol: TProtocol = IPPROTO_TCP): TSocketHandle =
  ## Creates a new socket; returns `InvalidSocket` if an error occurs.
  
  # TODO: The function which will use this will raise EOS.
  socket(toInt(domain), toInt(typ), toInt(protocol))

proc close*(socket: TSocketHandle) =
  ## closes a socket.
  when defined(windows):
    discard winlean.closeSocket(socket)
  else:
    discard posix.close(socket)
  # TODO: These values should not be discarded. An EOS should be raised.
  # http://stackoverflow.com/questions/12463473/what-happens-if-you-call-close-on-a-bsd-socket-multiple-times

proc bindAddr*(socket: TSocketHandle, name: ptr TSockAddr, namelen: TSockLen): cint =
  result = bindSocket(socket, name, namelen)

proc listen*(socket: TSocketHandle, backlog = SOMAXCONN) {.tags: [FReadIO].} =
  ## Marks ``socket`` as accepting connections. 
  ## ``Backlog`` specifies the maximum length of the 
  ## queue of pending connections.
  when defined(windows):
    if winlean.listen(socket, cint(backlog)) < 0'i32: osError(osLastError())
  else:
    if posix.listen(socket, cint(backlog)) < 0'i32: osError(osLastError())

proc getAddrInfo*(address: string, port: TPort, af: TDomain = AF_INET, typ: TType = SOCK_STREAM,
                 prot: TProtocol = IPPROTO_TCP): ptr TAddrInfo =
  ##
  ##
  ## **Warning**: The resulting ``ptr TAddrInfo`` must be freed using ``dealloc``!
  var hints: TAddrInfo
  result = nil
  hints.ai_family = toInt(af)
  hints.ai_socktype = toInt(typ)
  hints.ai_protocol = toInt(prot)
  var gaiResult = getAddrInfo(address, $port, addr(hints), result)
  if gaiResult != 0'i32:
    when defined(windows):
      OSError(OSLastError())
    else:
      raise newException(EOS, $gai_strerror(gaiResult))

proc dealloc*(ai: ptr TAddrInfo) =
  freeaddrinfo(ai)

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
  result = sockets2.ntohl(x)

proc htons*(x: int16): int16 =
  ## Converts 16-bit positive integers from host to network byte order.
  ## On machines where the host byte order is the same as network byte
  ## order, this is a no-op; otherwise, it performs a 2-byte swap operation.
  result = sockets2.ntohs(x)

when defined(Windows):
  var wsa: TWSADATA
  if WSAStartup(0x0101'i16, addr wsa) != 0: OSError(OSLastError())
