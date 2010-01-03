#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a simple portable type-safe sockets layer. **Note**:
## This module is incomplete and probably buggy. It does not work on Windows
## yet. Help if you are interested.

# TODO:
# getservbyname(name, proto)
# getservbyport(port, proto)
# gethostbyname(name)
# gethostbyaddr(addr)
# shutdown(sock, how)
# connect(sock, address, port)
# select({ socket, ... }, timeout)

# sendto
# recvfrom

# bind(socket, address, port)

# getsockopt(socket, level, optname)
# setsockopt(socket, level, optname, value)

import os

when defined(Windows):
  import winlean
else:
  import posix

type
  TSocket* = distinct cint ## socket type
  TPort* = distinct int16  ## port type
  
  TDomain* = enum   ## domain, which specifies the protocol family of the
                    ## created socket. Other domains than those that are listed
                    ## here are unsupported.
    AF_UNIX,        ## for local socket (using a file).
    AF_INET,        ## for network protocol IPv4 or
    AF_INET6        ## for network protocol IPv6.

  TType* = enum     ## second argument to `socket` proc
    SOCK_STREAM,    ## reliable stream-oriented service or Stream Sockets
    SOCK_DGRAM,     ## datagram service or Datagram Sockets
    SOCK_SEQPACKET, ## reliable sequenced packet service, or
    SOCK_RAW        ## raw protocols atop the network layer.

  TProtocol* = enum ## third argument to `socket` proc
    IPPROTO_TCP,    ## Transmission control protocol. 
    IPPROTO_UDP,    ## User datagram protocol.
    IPPROTO_IP,     ## Internet protocol. 
    IPPROTO_IPV6,   ## Internet Protocol Version 6. 
    IPPROTO_RAW,    ## Raw IP Packets Protocol. 
    IPPROTO_ICMP    ## Control message protocol. 

const
  InvalidSocket* = TSocket(-1'i32) ## invalid socket number

proc `==`*(a, b: TSocket): bool {.borrow.}
proc `==`*(a, b: TPort): bool {.borrow.}

proc ToInt(domain: TDomain): cint =
  case domain
  of AF_UNIX:        result = posix.AF_UNIX
  of AF_INET:        result = posix.AF_INET
  of AF_INET6:       result = posix.AF_INET6

proc ToInt(typ: TType): cint =
  case typ
  of SOCK_STREAM:    result = posix.SOCK_STREAM
  of SOCK_DGRAM:     result = posix.SOCK_DGRAM
  of SOCK_SEQPACKET: result = posix.SOCK_SEQPACKET
  of SOCK_RAW:       result = posix.SOCK_RAW

proc ToInt(p: TProtocol): cint =
  case p
  of IPPROTO_TCP:    result = posix.IPPROTO_TCP
  of IPPROTO_UDP:    result = posix.IPPROTO_UDP
  of IPPROTO_IP:     result = posix.IPPROTO_IP
  of IPPROTO_IPV6:   result = posix.IPPROTO_IPV6
  of IPPROTO_RAW:    result = posix.IPPROTO_RAW
  of IPPROTO_ICMP:   result = posix.IPPROTO_ICMP

proc socket*(domain: TDomain = AF_INET6, typ: TType = SOCK_STREAM,
             protocol: TProtocol = IPPROTO_TCP): TSocket =
  ## creates a new socket; returns `InvalidSocket` if an error occurs.  
  result = TSocket(posix.socket(ToInt(domain), ToInt(typ), ToInt(protocol)))

proc listen*(socket: TSocket, attempts = 5) =
  ## listens to socket.
  if posix.listen(cint(socket), cint(attempts)) < 0'i32: OSError()

proc bindAddr*(socket: TSocket, port = TPort(0)) =
  var name: Tsockaddr_in
  name.sin_family = posix.AF_INET
  name.sin_port = htons(int16(port))
  name.sin_addr.s_addr = htonl(INADDR_ANY)
  if bindSocket(cint(socket), cast[ptr TSockAddr](addr(name)),
                sizeof(name)) < 0'i32:
    OSError()
  
proc getSockName*(socket: TSocket): TPort = 
  var name: Tsockaddr_in
  name.sin_family = posix.AF_INET
  #name.sin_port = htons(cint16(port))
  #name.sin_addr.s_addr = htonl(INADDR_ANY)
  var namelen: cint = sizeof(name)
  if getsockname(cint(socket), cast[ptr TSockAddr](addr(name)),
                 addr(namelen)) == -1'i32:
    OSError()
  result = TPort(ntohs(name.sin_port))

proc accept*(server: TSocket): TSocket =
  ## waits for a client and returns its socket
  var client: Tsockaddr_in
  var clientLen: TsockLen = sizeof(client)
  result = TSocket(accept(cint(server), cast[ptr TSockAddr](addr(client)),
                          addr(clientLen)))

proc close*(socket: TSocket) =
  ## closes a socket.
  when defined(windows):
    discard winlean.closeSocket(cint(socket))
  else:
    discard posix.close(cint(socket))

proc recvLine*(socket: TSocket, line: var string): bool =
  ## returns false if no further data is available.
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
  ## receive data from a socket
  result = posix.recv(cint(socket), data, size, 0'i32)

proc recv*(socket: TSocket): string =
  ## receive all the data from the socket
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
  result = posix.send(cint(socket), data, size, 0'i32)

proc send*(socket: TSocket, data: string) =
  if send(socket, cstring(data), data.len) != data.len: OSError()

proc ntohl*(x: int32): int32 = 
  ## Convert 32-bit integers from network to host byte order.
  ## On machines where the host byte order is the same as network byte order,
  ## this is a no-op; otherwise, it performs a 4-byte swap operation.
  when cpuEndian == bigEndian: result = x
  else: result = (x shr 24'i32) or
                 (x shr 8'i32 and 0xff00'i32) or
                 (x shl 8'i32 and 0xff0000'i32) or
                 (x shl 24'i32)

proc ntohs*(x: int16): int16 =
  ## Convert 16-bit integers from network to host byte order. On machines
  ## where the host byte order is the same as network byte order, this is
  ## a no-op; otherwise, it performs a 2-byte swap operation.
  when cpuEndian == bigEndian: result = x
  else: result = (x shr 8'i16) or (x shl 8'i16)

proc htonl*(x: int32): int32 =
  ## Convert 32-bit integers from host to network byte order. On machines
  ## where the host byte order is the same as network byte order, this is
  ## a no-op; otherwise, it performs a 4-byte swap operation.
  result = sockets.ntohl(x)

proc htons*(x: int16): int16 =
  ## Convert 16-bit positive integers from host to network byte order.
  ## On machines where the host byte order is the same as network byte
  ## order, this is a no-op; otherwise, it performs a 2-byte swap operation.
  result = sockets.ntohs(x)
