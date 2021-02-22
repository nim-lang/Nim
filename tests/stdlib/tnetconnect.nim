import std/net

# Issue 15215 - https://github.com/nim-lang/Nim/issues/15215
proc test() =
  var
    ctx = newContext()
    socket = newSocket()

  wrapSocket(ctx, socket)

  connect(socket, "www.nim-lang.org", Port(443), 5000)

  close(socket)

test()