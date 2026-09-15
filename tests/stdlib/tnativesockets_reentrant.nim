discard """
  matrix: "--mm:refc -d:testReentrantBufs; --mm:orc -d:testReentrantBufs"
  joinable: false
"""

## Tests that the _r network calls handle ERANGE buffer resizing correctly.
## Compiled with -d:testReentrantBufs which sets initial buffers to 1 byte,
## forcing the while-loop to grow buffers through several ERANGE iterations.

import std/nativesockets
import std/assertions

when defined(linux):
  block: # getProtoByName
    doAssert getProtoByName("tcp") == 6
    doAssert getProtoByName("udp") == 17

  block: # getServByName
    let s = getServByName("http", "tcp")
    doAssert s.name == "http"
    doAssert s.proto == "tcp"

  block: # getServByPort
    let s = getServByPort(Port(htons(80)), "tcp")
    doAssert s.name == "http"
    doAssert s.proto == "tcp"

  block: # getHostByName
    let he = getHostByName("localhost")
    doAssert he.name.len > 0
    doAssert he.addrList.len > 0

  block: # getHostByAddr
    let he = getHostByAddr("127.0.0.1")
    doAssert he.name.len > 0
