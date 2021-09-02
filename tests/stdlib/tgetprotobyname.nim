import nativesockets

when not defined(netbsd):
  # Ref: https://github.com/nim-lang/Nim/issues/15452 - NetBSD doesn't define an `ip` protocol
  doAssert getProtoByName("ip") == 0

doAssert getProtoByName("ipv6") == 41
doAssert getProtoByName("tcp") == 6
doAssert getProtoByName("udp") == 17
doAssert getProtoByName("icmp") == 1
doAssert getProtoByName("ipv6-icmp") == 58

when defined(windows):
  doAssertRaises(OSError):
    discard getProtoByName("raw")

doAssertRaises(OSError):
  discard getProtoByName("Error")
