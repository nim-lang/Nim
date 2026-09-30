discard """
  matrix: "--mm:refc; --mm:orc"
  exitcode: 0
  output: ""
"""

# bug: https://github.com/nim-lang/Nim/issues/10198

import nativesockets
import std/assertions

block DGRAM_UDP:
  let aiList = getAddrInfo("127.0.0.1", 999.Port, AF_INET, SOCK_DGRAM, IPPROTO_UDP)
  doAssert aiList != nil
  doAssert aiList.ai_addr != nil
  doAssert aiList.ai_addrlen.SockLen == sizeof(Sockaddr_in).SockLen
  doAssert aiList.ai_next == nil
  freeAddrInfo aiList

when defined(posix) and not defined(haiku) and not defined(freebsd) and not defined(openbsd) and not defined(netbsd):

  block RAW_ICMP:
    # the port will be ignored
    let aiList = getAddrInfo("127.0.0.1", 999.Port, AF_INET, SOCK_RAW, IPPROTO_ICMP)
    doAssert aiList != nil
    doAssert aiList.ai_addr != nil
    doAssert aiList.ai_addrlen.SockLen == sizeof(Sockaddr_in).SockLen
    doAssert aiList.ai_next == nil
    doAssert cast[ptr Sockaddr_in](aiList.ai_addr).sin_port == 0
    freeAddrInfo aiList

  block RAW_ICMPV6:
    # the port will be ignored
    let aiList = getAddrInfo("::1", 999.Port, AF_INET6, SOCK_RAW, IPPROTO_ICMPV6)
    doAssert aiList != nil
    doAssert aiList.ai_addr != nil
    doAssert aiList.ai_addrlen.SockLen == sizeof(Sockaddr_in6).SockLen
    doAssert aiList.ai_next == nil
    doAssert cast[ptr Sockaddr_in6](aiList.ai_addr).sin6_port == 0
    freeAddrInfo aiList

  block rawHints:
    let
      hints = AddrInfo(
        ai_family: toInt(AF_INET),
        ai_socktype: toInt(SOCK_RAW),
        ai_protocol: toInt(IPPROTO_ICMP)
      )
      infos = getAddrInfo("127.0.0.1", 999.Port, hints)
    defer: freeAddrInfo(infos)
    doAssert infos != nil
    doAssert cast[ptr Sockaddr_in](infos.ai_addr).sin_port == 0
