import nativesockets
export nativesockets

{.warning: "rawsockets module is deprecated, use nativesockets instead".}

template newRawSocket*(domain, sockType, protocol: cint): expr =
  {.warning: "newRawSocket is deprecated, use newNativeSocket instead".}
  newNativeSocket(domain, sockType, protocol)

template newRawSocket*(domain: Domain = AF_INET,
                       sockType: SockType = SOCK_STREAM,
                       protocol: Protocol = IPPROTO_TCP): expr =
  {.warning: "newRawSocket is deprecated, use newNativeSocket instead".}
  newNativeSocket(domain, sockType, protocol)
