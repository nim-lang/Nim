discard """
output: "Finished"
"""

import asyncdispatch, asyncnet

proc createServer(port: Port) {.async.} =
  var server = newAsyncSocket()
  server.setSockOpt(OptReuseAddr, true)
  bindAddr(server, port)
  server.listen()
  while true:
    let client = await server.accept()
    discard await client.recvLine()

asyncCheck createServer(10335.Port)

proc f(): Future[void] {.async.} =
  let s = newAsyncNativeSocket()
  await s.connect("localhost", 10335.Port)
  await s.send("123")
  echo "Finished"

waitFor f()
