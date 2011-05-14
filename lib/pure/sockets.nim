#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a simple portable type-safe sockets layer.

import os, parseutils

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

else:
  proc toInt(domain: TDomain): cint = 
    result = toU16(ord(domain))

  proc ToInt(typ: TType): cint =
    result = cint(ord(typ))
  
  proc ToInt(p: TProtocol): cint =
    result = cint(ord(p))

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

proc invalidIp4(s: string) {.noreturn, noinline.} =
  raise newException(EInvalidValue, "invalid ip4 address: " & s)

proc parseIp4*(s: string): int32 = 
  ## parses an IP version 4 in dotted decimal form like "a.b.c.d".
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
  result = int32(a shl 24 or b shl 16 or c shl 8 or d)

proc bindAddr*(socket: TSocket, port = TPort(0), address = "") =
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
    if bindSocket(cint(socket), cast[ptr TSockAddr](addr(name)),
                  sizeof(name)) < 0'i32:
      OSError()
  else:
    var hints: TAddrInfo
    var aiList: ptr TAddrInfo = nil
    hints.ai_family = toInt(AF_INET)
    hints.ai_socktype = toInt(SOCK_STREAM)
    hints.ai_protocol = toInt(IPPROTO_TCP)
    if getAddrInfo(address, $port, addr(hints), aiList) != 0'i32: OSError()
    if bindSocket(cint(socket), aiList.ai_addr, aiList.ai_addrLen) < 0'i32:
      OSError()

when false:
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
  ## waits for a client and returns its socket. ``InvalidSocket`` is returned
  ## if an error occurs, or if ``server`` is non-blocking and there are no 
  ## clients connecting.
  var client: Tsockaddr_in
  var clientLen: cint = sizeof(client)
  result = TSocket(accept(cint(server), cast[ptr TSockAddr](addr(client)),
                          addr(clientLen)))

proc acceptAddr*(server: TSocket): tuple[sock: TSocket, address: string] =
  ## waits for a client and returns its socket and IP address
  var address: Tsockaddr_in
  var addrLen: cint = sizeof(address)
  var sock = TSocket(accept(cint(server), cast[ptr TSockAddr](addr(address)),
                          addr(addrLen)))
  return (sock, $inet_ntoa(address.sin_addr))

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

proc getHostByAddr*(ip: string): THostEnt =
  ## This function will lookup the hostname of an IP Address.
  var myaddr: TInAddr
  myaddr.s_addr = inet_addr(ip)
  
  when defined(windows):
    var s = winlean.gethostbyaddr(addr(myaddr), sizeof(myaddr),
                                  cint(sockets.AF_INET))
    if s == nil: OSError()
  else:
    var s = posix.gethostbyaddr(addr(myaddr), sizeof(myaddr), 
                                cint(posix.AF_INET))
    if s == nil:
      raise newException(EOS, $hStrError(h_errno))
  
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
  ## Connects socket to ``name``:``port``. ``Name`` can be an IP address or a
  ## host name. If ``name`` is a host name, this function will try each IP
  ## of that host name. ``htons`` is already performed on ``port`` so you must
  ## not do it.
  var hints: TAddrInfo
  var aiList: ptr TAddrInfo = nil
  hints.ai_family = toInt(af)
  hints.ai_socktype = toInt(SOCK_STREAM)
  hints.ai_protocol = toInt(IPPROTO_TCP)
  if getAddrInfo(name, $port, addr(hints), aiList) != 0'i32: OSError()
  # try all possibilities:
  var success = false
  var it = aiList
  while it != nil:
    if connect(cint(socket), it.ai_addr, it.ai_addrlen) == 0'i32:
      success = true
      break
    it = it.ai_next

  freeaddrinfo(aiList)
  if not success: OSError()
  
  when false:
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

proc connectAsync*(socket: TSocket, name: string, port = TPort(0),
                     af: TDomain = AF_INET) =
  ## A variant of ``connect`` for non-blocking sockets.
  var hints: TAddrInfo
  var aiList: ptr TAddrInfo = nil
  hints.ai_family = toInt(af)
  hints.ai_socktype = toInt(SOCK_STREAM)
  hints.ai_protocol = toInt(IPPROTO_TCP)
  if getAddrInfo(name, $port, addr(hints), aiList) != 0'i32: OSError()
  # try all possibilities:
  var success = false
  var it = aiList
  while it != nil:
    var ret = connect(cint(socket), it.ai_addr, it.ai_addrlen)
    if ret == 0'i32:
      success = true
      break
    else:
      # TODO: Test on Windows.
      when defined(windows):
        var err = WSAGetLastError()
        # Windows EINTR doesn't behave same as POSIX.
        if err == WSAEWOULDBLOCK:
          return
      else:
        if errno == EINTR or errno == EINPROGRESS:
          return
        
    it = it.ai_next

  freeaddrinfo(aiList)
  if not success: OSError()


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
  ## Specify -1 for no timeout.
  var tv: TTimeVal
  tv.tv_sec = 0
  tv.tv_usec = timeout * 1000
  
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
             timeout = 500): int = 
  ## select with a sensible Nimrod interface. `timeout` is in miliseconds.
  ## Specify -1 for no timeout.
  var tv: TTimeVal
  tv.tv_sec = 0
  tv.tv_usec = timeout * 1000
  
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
                  timeout = 500): int = 
  ## select with a sensible Nimrod interface. `timeout` is in miliseconds.
  ## Specify -1 for no timeout.
  var tv: TTimeVal
  tv.tv_sec = 0
  tv.tv_usec = timeout * 1000
  
  var wr: TFdSet
  var m = 0
  createFdSet((wr), writefds, m)
  
  if timeout != -1:
    result = int(select(cint(m+1), nil, addr(wr), nil, addr(tv)))
  else:
    result = int(select(cint(m+1), nil, addr(wr), nil, nil))
  
  pruneSocketSet(writefds, (wr))


proc select*(readfds: var seq[TSocket], timeout = 500): int = 
  ## select with a sensible Nimrod interface. `timeout` is in miliseconds.
  ## Specify -1 for no timeout.
  var tv: TTimeVal
  tv.tv_sec = 0
  tv.tv_usec = timeout * 1000
  
  var rd: TFdSet
  var m = 0
  createFdSet((rd), readfds, m)
  
  if timeout != -1:
    result = int(select(cint(m+1), addr(rd), nil, nil, addr(tv)))
  else:
    result = int(select(cint(m+1), addr(rd), nil, nil, nil))
  
  pruneSocketSet(readfds, (rd))


proc recvLine*(socket: TSocket, line: var string): bool =
  ## returns false if no further data is available. `Line` must be initialized
  ## and not nil! This does not throw an EOS exception, therefore
  ## it can be used in both blocking and non-blocking sockets.
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
  ## receives all the data from the socket.
  ## Socket errors will result in an ``EOS`` error.
  ## If socket is not a connectionless socket and socket is not connected
  ## ``""`` will be returned.
  const bufSize = 200
  var buf = newString(bufSize)
  result = ""
  while true:
    var bytesRead = recv(socket, cstring(buf), bufSize-1)
    # Error
    if bytesRead == -1: OSError()
    
    buf[bytesRead] = '\0' # might not be necessary
    setLen(buf, bytesRead)
    add(result, buf)
    if bytesRead != bufSize-1: break

proc recvAsync*(socket: TSocket, s: var string): bool =
  ## receives all the data from a non-blocking socket. If socket is non-blocking 
  ## and there are no messages available, `False` will be returned.
  ## Other socket errors will result in an ``EOS`` error.
  ## If socket is not a connectionless socket and socket is not connected
  ## ``s`` will be set to ``""``.
  const bufSize = 200
  var buf = newString(bufSize)
  s = ""
  while true:
    var bytesRead = recv(socket, cstring(buf), bufSize-1)
    # Error
    if bytesRead == -1:
      when defined(windows):
        # TODO: Test on Windows
        var err = WSAGetLastError()
        if err == WSAEWOULDBLOCK:
          return False
        else: OSError()
      else:
        if errno == EAGAIN or errno == EWOULDBLOCK:
          return False
        else: OSError()
    
    buf[bytesRead] = '\0' # might not be necessary
    setLen(buf, bytesRead)
    add(s, buf)
    if bytesRead != bufSize-1: break
  result = True
  
proc skip*(socket: TSocket) =
  ## skips all the data that is pending for the socket
  const bufSize = 200
  var buf = alloc(bufSize)
  while recv(socket, buf, bufSize) == bufSize: nil
  dealloc(buf)

proc send*(socket: TSocket, data: pointer, size: int): int =
  ## sends data to a socket.
  when defined(windows):
    result = send(cint(socket), data, size, 0'i32)
  else:
    result = send(cint(socket), data, size, int32(MSG_NOSIGNAL))

proc send*(socket: TSocket, data: string) =
  ## sends data to a socket.
  if send(socket, cstring(data), data.len) != data.len: OSError()

proc sendAsync*(socket: TSocket, data: string) =
  ## sends data to a non-blocking socket.
  var bytesSent = send(socket, cstring(data), data.len)
  if bytesSent == -1:
    when defined(windows):
      var err = WSAGetLastError()
      # TODO: Test on windows.
      if err == WSAEINPROGRESS:
        return
      else: OSError()
    else:
      if errno == EAGAIN or errno == EWOULDBLOCK:
        return
      else: OSError()

when defined(Windows):
  const 
    SOCKET_ERROR = -1
    IOCPARM_MASK = 127
    IOC_IN = int(-2147483648)
    FIONBIO = int(IOC_IN or ((sizeof(int) and IOCPARM_MASK) shl 16) or 
                             (102 shl 8) or 126)

  proc ioctlsocket(s: TWinSocket, cmd: clong, 
                   argptr: ptr clong): cint {.
                   stdcall, importc:"ioctlsocket", dynlib: "ws2_32.dll".}

proc setBlocking*(s: TSocket, blocking: bool) =
  ## sets blocking mode on socket
  when defined(Windows):
    var mode = clong(ord(not blocking)) # 1 for non-blocking, 0 for blocking
    if SOCKET_ERROR == ioctlsocket(TWinSocket(s), FIONBIO, addr(mode)):
      OSError()
  else: # BSD sockets
    var x: int = fcntl(cint(s), F_GETFL, 0)
    if x == -1:
      OSError()
    else:
      var mode = if blocking: x and not O_NONBLOCK else: x or O_NONBLOCK
      if fcntl(cint(s), F_SETFL, mode) == -1:
        OSError()

when defined(Windows):
  var wsa: TWSADATA
  if WSAStartup(0x0101'i16, wsa) != 0: OSError()


