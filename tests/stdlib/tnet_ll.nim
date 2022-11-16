discard """
  action: run
  output: '''

[Suite] inet_ntop tests
'''
"""

when defined(windows):
  import winlean
elif defined(posix):
  import posix
else:
  {.error: "Unsupported OS".}

import unittest, strutils

suite "inet_ntop tests":

  setup:
    when defined(windows):
      var wsa: WSAData
      discard wsaStartup(0x101'i16, wsa.addr)

  test "IP V4":
    # regular
    var ip4 = InAddr()
    ip4.s_addr = 0x10111213'u32
    check: ip4.s_addr == 0x10111213'u32

    var buff: array[0..255, char]
    let r = inet_ntop(AF_INET, cast[pointer](ip4.s_addr.addr), cast[cstring](buff[0].addr), buff.len.int32)
    let res = if r == nil: "" else: $r
    check: res == "19.18.17.16"

  test "IP V6":
    when defined(windows):
      let ipv6Support = (getVersion() and 0xff) > 0x5
    else:
      let ipv6Support = true

    var ip6 = [0x1000'u16, 0x1001, 0x2000, 0x2001, 0x3000, 0x3001, 0x4000, 0x4001]
    var buff: array[0..255, char]
    when defined(zephyr):
      let r = inet_ntop(AF_INET6, cast[pointer](ip6[0].addr), cast[cstring](buff[0].addr), buff.len.int32)
    else:
      let r = inet_ntop(AF_INET6, ip6[0].addr, cast[cstring](buff[0].addr), buff.sizeof.int32)
    let res = if r == nil: "" else: $r
    check: not ipv6Support or res == "10:110:20:120:30:130:40:140"

  test "InAddr":
    # issue 19244
    var ip4 = InAddr(s_addr: 0x10111213'u32)
    check: ip4.s_addr == 0x10111213'u32
