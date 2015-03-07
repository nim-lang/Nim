import net
import unittest

suite "isIpAddress tests":
  test "127.0.0.1 is valid":
    check isIpAddress("127.0.0.1") == true

  test "ipv6 localhost is valid":
    check isIpAddress("::1") == true

  test "fqdn is not an ip address":
    check isIpAddress("example.com") == false

  test "random string is not an ipaddress":
    check isIpAddress("foo bar") == false

  test "5127.0.0.1 is invalid":
    check isIpAddress("5127.0.0.1") == false

  test "ipv6 is valid":
    check isIpAddress("2001:cdba:0000:0000:0000:0000:3257:9652") == true

  test "invalid ipv6":
    check isIpAddress("gggg:cdba:0000:0000:0000:0000:3257:9652") == false


suite "parseIpAddress tests":
  test "127.0.0.1 is valid":
    discard parseIpAddress("127.0.0.1")

  test "ipv6 localhost is valid":
    discard parseIpAddress("::1")

  test "fqdn is not an ip address":
    expect(ValueError):
      discard parseIpAddress("example.com")

  test "random string is not an ipaddress":
    expect(ValueError):
      discard parseIpAddress("foo bar")

  test "ipv6 is valid":
    discard parseIpAddress("2001:cdba:0000:0000:0000:0000:3257:9652")

  test "invalid ipv6":
    expect(ValueError):
      discard parseIpAddress("gggg:cdba:0000:0000:0000:0000:3257:9652")
