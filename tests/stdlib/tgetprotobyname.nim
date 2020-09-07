discard """
  cmd:      "nim c -r --styleCheck:hint --panics:on $options $file"
  targets:  "c"
  nimout:   ""
  action:   "run"
  exitcode: 0
  timeout:  60.0
"""

import nativesockets


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
