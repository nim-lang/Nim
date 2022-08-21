import std/nativesockets
import stdtest/testutils

block:
  let hostname = getHostname()
  doAssert hostname.len > 0

when defined(windows):
  assertAll:
    toInt(IPPROTO_IP) == 0
    toInt(IPPROTO_ICMP) == 1
    toInt(IPPROTO_TCP) == 6
    toInt(IPPROTO_UDP) == 17
    toInt(IPPROTO_IPV6) == 41
    toInt(IPPROTO_ICMPV6) == 58
    toInt(IPPROTO_RAW) == 20

    # no changes to enum value
    ord(IPPROTO_TCP) == 6
    ord(IPPROTO_UDP) == 17
    ord(IPPROTO_IP) == 18
    ord(IPPROTO_IPV6) == 19
    ord(IPPROTO_RAW) == 20
    ord(IPPROTO_ICMP) == 21
    ord(IPPROTO_ICMPV6) == 22
