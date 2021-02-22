discard """
  cmd: "nim c -r -d:ssl $file"
  exitcode: 0
"""

import std/net

# Issue 15215 - https://github.com/nim-lang/Nim/issues/15215
proc test() =
  var
    ctx = newContext()
    socket = newSocket()

  wrapSocket(ctx, socket)

  connect(socket, "www.nim-lang.org", Port(443), 5000)

  send(socket, "GET / HTTP/1.0\nHost: www.nim-lang.org\nConnection: close\n\n")

  close(socket)

test()
