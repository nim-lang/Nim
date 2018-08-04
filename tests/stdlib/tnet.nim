import net, nativesockets
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

block: # "IpAddress/Sockaddr conversion"
  proc test(ipaddrstr: string) =
    var ipaddr_1 = parseIpAddress(ipaddrstr)
    # echo ipaddrstr, " ", $ipaddr_1

    doAssert($ipaddrstr == $ipaddr_1)

    var sockaddr: Sockaddr_storage
    var socklen: Socklen
    var ipaddr_2: IpAddress
    var port_2: Port

    toSockAddr(ipaddr_1, Port(0), sockaddr, socklen)
    fromSockAddr(sockaddr, socklen, ipaddr_2, port_2)

    doAssert(ipaddrstr == $ipaddr_1)

    doAssert(ipaddr_1 == ipaddr_2)
    doAssert($ipaddr_1 == $ipaddr_2)

    if sockaddr.ss_family == AF_INET.toInt:
      var sockaddr4: Sockaddr_in
      copyMem(addr sockaddr4, addr sockaddr, sizeof(sockaddr4))
      fromSockAddr(sockaddr4, socklen, ipaddr_2, port_2)
    elif sockaddr.ss_family == AF_INET6.toInt:
      var sockaddr6: Sockaddr_in6
      copyMem(addr sockaddr6, addr sockaddr, sizeof(sockaddr6))
      fromSockAddr(sockaddr6, socklen, ipaddr_2, port_2)

    doAssert(ipaddr_1 == ipaddr_2)
    doAssert($ipaddr_1 == $ipaddr_2)


  # ipv6 address of example.com
  test("2606:2800:220:1:248:1893:25c8:1946")
  # ipv6 address of localhost
  test("::1")
  # ipv4 address of example.com
  test("93.184.216.34")
  # ipv4 address of localhost
  test("127.0.0.1")
