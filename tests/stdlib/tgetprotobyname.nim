discard """
  matrix: "--mm:refc; --mm:orc"
"""

import nativesockets
import std/assertions

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
