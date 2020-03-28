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
    var ip4 = 0x10111213
    var buff: array[0..255, char]
    let r = inet_ntop(AF_INET, ip4.addr, buff.toCstring, buff.sizeof.int32)
    let res = if r == nil: "" else: $r
    check: res == "19.18.17.16"
      

  test "IP V6":
    when defined(windows):
      let ipv6Support = (getVersion() and 0xff) > 0x5
    else:
      let ipv6Support = true
          
    var ip6 = [0x1000'u16, 0x1001, 0x2000, 0x2001, 0x3000, 0x3001, 0x4000, 0x4001]
    var buff: array[0..255, char]
    let r = inet_ntop(AF_INET6, ip6[0].addr, buff.toCstring, buff.sizeof.int32)
    let res = if r == nil: "" else: $r
    check: not ipv6Support or res == "10:110:20:120:30:130:40:140"
