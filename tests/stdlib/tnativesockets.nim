discard """
  cmd:      "nim c -r --styleCheck:hint --panics:on $options $file"
  targets:  "c"
  nimout:   ""
  action:   "run"
  exitcode: 0
  timeout:  60.0
"""

import nativesockets


when defined(windows):
  doAssert toInt(IPPROTO_IP) == 0.cint
  doAssert toInt(IPPROTO_ICMP) == 1.cint
  doAssert toInt(IPPROTO_TCP) == 6.cint
  doAssert toInt(IPPROTO_UDP) == 17.cint
  doAssert toInt(IPPROTO_IPV6) == 41.cint
  doAssert toInt(IPPROTO_ICMPV6) == 58.cint
  doAssert toInt(IPPROTO_RAW) == 20.cint

  # no changes to enum value
  doAssert ord(IPPROTO_TCP) == 6
  doAssert ord(IPPROTO_UDP) == 17
  doAssert ord(IPPROTO_IP) == 18
  doAssert ord(IPPROTO_IPV6) == 19
  doAssert ord(IPPROTO_RAW) == 20
  doAssert ord(IPPROTO_ICMP) == 21
  doAssert ord(IPPROTO_ICMPV6) == 22
