import asyncdispatch, net, asyncnet

proc recvTwice(socket: Socket | AsyncSocket,
               size: int): Future[string] {.multisync.} =
  var x = await socket.recv(size)
  var y = await socket.recv(size+1)
  return x & "aboo" & y

