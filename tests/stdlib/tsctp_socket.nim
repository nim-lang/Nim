discard """
matrix: "--mm:refc; --mm:orc"
joinable: false
"""

#[
joinable: false
otherwise:
Error: unhandled exception: Address already in use [OSError]
]#

import net

## Test for net.bindAddr with SCTP

proc test() =
  when (defined(unix) or defined(linux)) and not defined(macosx):
    # IPv4 SCTP
    newSocket(AF_INET, SOCK_STREAM, IPPROTO_SCTP).bindAddr(Port(2900), "0.0.0.0")

    # IPv6 SCTP
    newSocket(AF_INET6, SOCK_STREAM, IPPROTO_SCTP).bindAddr(Port(2902), "::")

test()
