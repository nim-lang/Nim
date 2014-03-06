#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2014 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a high-level cross-platform sockets interface.

import sockets2, os

type
  TSocket* = TSocketHandle

proc bindAddr*(socket: TSocket, port = TPort(0), address = "") {.
  tags: [FReadIO].} =

  ## binds an address/port number to a socket.
  ## Use address string in dotted decimal form like "a.b.c.d"
  ## or leave "" for any address.

  if address == "":
    var name: TSockaddr_in
    when defined(windows):
      name.sin_family = toInt(AF_INET).int16
    else:
      name.sin_family = toInt(AF_INET)
    name.sin_port = htons(int16(port))
    name.sin_addr.s_addr = htonl(INADDR_ANY)
    if bindAddr(socket, cast[ptr TSockAddr](addr(name)),
                  sizeof(name).TSocklen) < 0'i32:
      osError(osLastError())
  else:
    var aiList = getAddrInfo(address, port, AF_INET)
    if bindAddr(socket, aiList.ai_addr, aiList.ai_addrlen.TSocklen) < 0'i32:
      dealloc(aiList)
      osError(osLastError())
    dealloc(aiList)

proc setBlocking*(s: TSocket, blocking: bool) {.tags: [].} =
  ## Sets blocking mode on socket
  when defined(Windows):
    var mode = clong(ord(not blocking)) # 1 for non-blocking, 0 for blocking
    if ioctlsocket(s, FIONBIO, addr(mode)) == -1:
      osError(osLastError())
  else: # BSD sockets
    var x: int = fcntl(s, F_GETFL, 0)
    if x == -1:
      osError(osLastError())
    else:
      var mode = if blocking: x and not O_NONBLOCK else: x or O_NONBLOCK
      if fcntl(s, F_SETFL, mode) == -1:
        osError(osLastError())