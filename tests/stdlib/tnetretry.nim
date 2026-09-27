discard """
  matrix: "--mm:refc; --mm:orc"
  disabled: windows
"""

import std/[net, os, posix, typedthreads, assertions]

block: # data cut short by a partial write is sent once, from where it stopped
  proc readAll(fd: SocketHandle) {.thread.} =
    # start late so the sender fills the buffers and its writes get cut short
    sleep(200)
    var received = ""
    var buf = newString(65536)
    while true:
      let n = recv(fd, buf.cstring, buf.len, 0)
      if n <= 0: break
      received.add buf[0 ..< n]
    var expected = ""
    for i in 0 ..< 4_000_000: expected.add char(ord('a') + i mod 26)
    doAssert received == expected

  let server = newSocket()
  server.bindAddr(Port(0), "localhost")
  server.listen()
  let client = newSocket()
  client.connect("localhost", server.getLocalAddr()[1])
  var peer: Socket
  server.accept(peer)
  # a send timeout and a small buffer make a blocking send return after
  # writing only part of the data
  var timeout = Timeval(tv_sec: posix.Time(0), tv_usec: Suseconds(50_000))
  doAssert setsockopt(client.getFd, SOL_SOCKET, SO_SNDTIMEO, addr timeout,
    sizeof(timeout).SockLen) == 0
  var bufSize: cint = 4096
  doAssert setsockopt(client.getFd, SOL_SOCKET, SO_SNDBUF, addr bufSize,
    sizeof(bufSize).SockLen) == 0
  var reader: Thread[SocketHandle]
  createThread(reader, readAll, peer.getFd)
  var data = ""
  for i in 0 ..< 4_000_000: data.add char(ord('a') + i mod 26)
  client.send(data)
  client.close()
  joinThread(reader)
  peer.close()
  server.close()
