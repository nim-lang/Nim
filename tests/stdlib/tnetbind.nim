discard """
joinable: false
"""

#[
joinable: false
otherwise:
Error: unhandled exception: Address already in use [OSError]
]#

import net

## Test for net.bindAddr

proc test() =
  # IPv4 TCP
  newSocket(AF_INET, SOCK_STREAM, IPPROTO_TCP).bindAddr(Port(1900), "0.0.0.0")
  newSocket(AF_INET, SOCK_STREAM, IPPROTO_TCP).bindAddr(Port(1901))

  # IPv6 TCP
  newSocket(AF_INET6, SOCK_STREAM, IPPROTO_TCP).bindAddr(Port(1902), "::")
  newSocket(AF_INET6, SOCK_STREAM, IPPROTO_TCP).bindAddr(Port(1903))

test()
