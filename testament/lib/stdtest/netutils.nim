import std/[nativesockets, asyncdispatch, os]

proc bindAvailablePort*(port = Port(0)): (AsyncFD, Port) =
  var server = createAsyncNativeSocket()
  block:
    var name: Sockaddr_in
    name.sin_family = typeof(name.sin_family)(toInt(AF_INET))
    name.sin_port = htons(uint16(port))
    name.sin_addr.s_addr = htonl(INADDR_ANY)
    if bindAddr(server.SocketHandle, cast[ptr SockAddr](addr(name)),
                sizeof(name).Socklen) < 0'i32:
      raiseOSError(osLastError())
  let port = getLocalAddr(server.SocketHandle, AF_INET)[1]
  result = (server, port)

