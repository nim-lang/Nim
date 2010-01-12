#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a simple portable type-safe sockets layer.

import os

when defined(Windows):
  import winlean
else:
  import posix

# Note: The enumerations are mapped to Window's constants.

type
  TSocket* = distinct cint ## socket type
  TPort* = distinct int16  ## port type
  
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
    SOCK_SEQPACKET = 5 ## reliable sequenced packet service, or

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

const
  InvalidSocket* = TSocket(-1'i32) ## invalid socket number

proc `==`*(a, b: TSocket): bool {.borrow.}
  ## ``==`` for sockets. 

proc `==`*(a, b: TPort): bool {.borrow.}
  ## ``==`` for ports.

proc `$`*(p: TPort): string = 
  ## returns the port number as a string
  result = $ze(int16(p))

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
  proc ToInt(domain: TDomain): cint =
    case domain
    of AF_UNIX:        result = posix.AF_UNIX
    of AF_INET:        result = posix.AF_INET
    of AF_INET6:       result = posix.AF_INET6
    else: nil

  proc ToInt(typ: TType): cint =
    case typ
    of SOCK_STREAM:    result = posix.SOCK_STREAM
    of SOCK_DGRAM:     result = posix.SOCK_DGRAM
    of SOCK_SEQPACKET: result = posix.SOCK_SEQPACKET
    of SOCK_RAW:       result = posix.SOCK_RAW
    else: nil

  proc ToInt(p: TProtocol): cint =
    case p
    of IPPROTO_TCP:    result = posix.IPPROTO_TCP
    of IPPROTO_UDP:    result = posix.IPPROTO_UDP
    of IPPROTO_IP:     result = posix.IPPROTO_IP
    of IPPROTO_IPV6:   result = posix.IPPROTO_IPV6
    of IPPROTO_RAW:    result = posix.IPPROTO_RAW
    of IPPROTO_ICMP:   result = posix.IPPROTO_ICMP
    else: nil

proc socket*(domain: TDomain = AF_INET, typ: TType = SOCK_STREAM,
             protocol: TProtocol = IPPROTO_TCP): TSocket =
  ## creates a new socket; returns `InvalidSocket` if an error occurs.  
  when defined(Windows):
    result = TSocket(winlean.socket(ord(domain), ord(typ), ord(protocol)))
  else:
    result = TSocket(posix.socket(ToInt(domain), ToInt(typ), ToInt(protocol)))

proc listen*(socket: TSocket, attempts = 5) =
  ## listens to socket.
  if listen(cint(socket), cint(attempts)) < 0'i32: OSError()

proc bindAddr*(socket: TSocket, port = TPort(0)) =
  ## binds a port number to a socket.
  var name: Tsockaddr_in
  when defined(Windows):
    name.sin_family = int16(ord(AF_INET))
  else:
    name.sin_family = posix.AF_INET
  name.sin_port = sockets.htons(int16(port))
  name.sin_addr.s_addr = sockets.htonl(INADDR_ANY)
  if bindSocket(cint(socket), cast[ptr TSockAddr](addr(name)),
                sizeof(name)) < 0'i32:
    OSError()
  
proc getSockName*(socket: TSocket): TPort = 
  ## returns the socket's associated port number.
  var name: Tsockaddr_in
  when defined(Windows):
    name.sin_family = int16(ord(AF_INET))
  else:
    name.sin_family = posix.AF_INET
  #name.sin_port = htons(cint16(port))
  #name.sin_addr.s_addr = htonl(INADDR_ANY)
  var namelen: cint = sizeof(name)
  if getsockname(cint(socket), cast[ptr TSockAddr](addr(name)),
                 addr(namelen)) == -1'i32:
    OSError()
  result = TPort(sockets.ntohs(name.sin_port))

proc accept*(server: TSocket): TSocket =
  ## waits for a client and returns its socket
  var client: Tsockaddr_in
  var clientLen: cint = sizeof(client)
  result = TSocket(accept(cint(server), cast[ptr TSockAddr](addr(client)),
                          addr(clientLen)))

proc close*(socket: TSocket) =
  ## closes a socket.
  when defined(windows):
    discard winlean.closeSocket(cint(socket))
  else:
    discard posix.close(cint(socket))

proc getServByName*(name, proto: string): TServent =
  ## well-known getservbyname proc.
  when defined(Windows):
    var s = winlean.getservbyname(name, proto)
  else:
    var s = posix.getservbyname(name, proto)
  if s == nil: OSError()
  result.name = $s.s_name
  result.aliases = cstringArrayToSeq(s.s_aliases)
  result.port = TPort(s.s_port)
  result.proto = $s.s_proto
  
proc getServByPort*(port: TPort, proto: string): TServent = 
  ## well-known getservbyport proc.
  when defined(Windows):
    var s = winlean.getservbyport(ze(int16(port)), proto)
  else:
    var s = posix.getservbyport(ze(int16(port)), proto)
  if s == nil: OSError()
  result.name = $s.s_name
  result.aliases = cstringArrayToSeq(s.s_aliases)
  result.port = TPort(s.s_port)
  result.proto = $s.s_proto

proc getHostByName*(name: string): THostEnt = 
  ## well-known gethostbyname proc.
  when defined(Windows):
    var s = winlean.gethostbyname(name)
  else:
    var s = posix.gethostbyname(name)
  if s == nil: OSError()
  result.name = $s.h_name
  result.aliases = cstringArrayToSeq(s.h_aliases)
  when defined(windows): 
    result.addrType = TDomain(s.h_addrtype)
  else:
    if s.h_addrtype == posix.AF_INET:
      result.addrType = AF_INET
    elif s.h_addrtype == posix.AF_INET6:
      result.addrType = AF_INET6
    else:
      OSError("unknown h_addrtype")
  result.addrList = cstringArrayToSeq(s.h_addr_list)
  result.length = int(s.h_length)

proc getSockOptInt*(socket: TSocket, level, optname: int): int = 
  ## getsockopt for integer options.
  var res: cint
  var size: cint = sizeof(res)
  if getsockopt(cint(socket), cint(level), cint(optname), 
                addr(res), addr(size)) < 0'i32:
    OSError()
  result = int(res)

proc setSockOptInt*(socket: TSocket, level, optname, optval: int) =
  ## setsockopt for integer options.
  var value = cint(optval)
  if setsockopt(cint(socket), cint(level), cint(optname), addr(value),  
                sizeof(value)) < 0'i32:
    OSError()

proc connect*(socket: TSocket, name: string, port = TPort(0), 
              af: TDomain = AF_INET) =
  ## well-known connect operation. Already does ``htons`` on the port number,
  ## so you shouldn't do it.
  var s: TSockAddrIn
  s.sin_addr.s_addr = inet_addr(name)
  s.sin_port = sockets.htons(int16(port))
  when defined(windows):
    s.sin_family = toU16(ord(af))
  else:
    case af 
    of AF_UNIX: s.sin_family = posix.AF_UNIX
    of AF_INET: s.sin_family = posix.AF_INET
    of AF_INET6: s.sin_family = posix.AF_INET6
    else: nil
  if connect(cint(socket), cast[ptr TSockAddr](addr(s)), sizeof(s)) < 0'i32:
    OSError()

#proc recvfrom*(s: TWinSocket, buf: cstring, len, flags: cint, 
#               fromm: ptr TSockAddr, fromlen: ptr cint): cint 

#proc sendto*(s: TWinSocket, buf: cstring, len, flags: cint,
#             to: ptr TSockAddr, tolen: cint): cint

proc createFdSet(fd: var TFdSet, s: seq[TSocket], m: var int) = 
  FD_ZERO(fd)
  for i in items(s): 
    m = max(m, int(i))
    FD_SET(cint(i), fd)
   
proc pruneSocketSet(s: var seq[TSocket], fd: var TFdSet) = 
  var i = 0
  var L = s.len
  while i < L:
    if FD_ISSET(cint(s[i]), fd) != 0'i32:
      s[i] = s[L-1]
      dec(L)
    else:
      inc(i)
  setLen(s, L)

proc select*(readfds, writefds, exceptfds: var seq[TSocket], 
             timeout = 500): int = 
  ## select with a sensible Nimrod interface. `timeout` is in miliseconds.
  var tv: TTimeVal
  tv.tv_sec = 0
  tv.tv_usec = timeout * 1000
  
  var rd, wr, ex: TFdSet
  var m = 0
  createFdSet((rd), readfds, m)
  createFdSet((wr), writefds, m)
  createFdSet((ex), exceptfds, m)
  
  result = int(select(cint(m), addr(rd), addr(wr), addr(ex), addr(tv)))
  
  pruneSocketSet(readfds, (rd))
  pruneSocketSet(writefds, (wr))
  pruneSocketSet(exceptfds, (ex))

proc select*(readfds, writefds: var seq[TSocket], 
             timeout = 500): int = 
  ## select with a sensible Nimrod interface. `timeout` is in miliseconds.
  var tv: TTimeVal
  tv.tv_sec = 0
  tv.tv_usec = timeout * 1000
  
  var rd, wr: TFdSet
  var m = 0
  createFdSet((rd), readfds, m)
  createFdSet((wr), writefds, m)
  
  result = int(select(cint(m), addr(rd), addr(wr), nil, addr(tv)))
  
  pruneSocketSet(readfds, (rd))
  pruneSocketSet(writefds, (wr))


proc select*(readfds: var seq[TSocket], timeout = 500): int = 
  ## select with a sensible Nimrod interface. `timeout` is in miliseconds.
  var tv: TTimeVal
  tv.tv_sec = 0
  tv.tv_usec = timeout * 1000
  
  var rd: TFdSet
  var m = 0
  createFdSet((rd), readfds, m)
  
  result = int(select(cint(m), addr(rd), nil, nil, addr(tv)))
  
  pruneSocketSet(readfds, (rd))


proc recvLine*(socket: TSocket, line: var string): bool =
  ## returns false if no further data is available. `line` must be initalized
  ## and not nil!
  setLen(line, 0)
  while true:
    var c: char
    var n = recv(cint(socket), addr(c), 1, 0'i32)
    if n <= 0: return
    if c == '\r':
      n = recv(cint(socket), addr(c), 1, MSG_PEEK)
      if n > 0 and c == '\L':
        discard recv(cint(socket), addr(c), 1, 0'i32)
      elif n <= 0: return false
      return true
    elif c == '\L': return true
    add(line, c)

proc recv*(socket: TSocket, data: pointer, size: int): int =
  ## receives data from a socket
  result = recv(cint(socket), data, size, 0'i32)

proc recv*(socket: TSocket): string =
  ## receives all the data from the socket
  const bufSize = 200
  var buf = newString(bufSize)
  result = ""
  while true:
    var bytesRead = recv(socket, cstring(buf), bufSize-1)
    buf[bytesRead] = '\0' # might not be necessary
    setLen(buf, bytesRead)
    add(result, buf)
    if bytesRead != bufSize-1: break
  
proc skip*(socket: TSocket) =
  ## skips all the data that is pending for the socket
  const bufSize = 200
  var buf = alloc(bufSize)
  while recv(socket, buf, bufSize) == bufSize: nil
  dealloc(buf)

proc send*(socket: TSocket, data: pointer, size: int): int =
  ## sends data to a socket.
  result = send(cint(socket), data, size, 0'i32)

proc send*(socket: TSocket, data: string) =
  ## sends data to a socket.
  if send(socket, cstring(data), data.len) != data.len: OSError()

when defined(Windows):
  var wsa: TWSADATA
  if WSAStartup(0x0101'i16, wsa) != 0: OSError()


