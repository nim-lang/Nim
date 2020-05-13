discard """
output: "Finished"
"""

import asyncdispatch, asyncnet

var port: Port
proc createServer() {.async.} =
  var server = newAsyncSocket()
  server.setSockOpt(OptReuseAddr, true)
  bindAddr(server)
  port = getLocalAddr(server)[1]
  server.listen()
  while true:
    let client = await server.accept()
    discard await client.recvLine()

asyncCheck createServer()

proc f(): Future[void] {.async.} =
  let s = createAsyncNativeSocket()
  await s.connect("localhost", port)
  await s.send("123")
  echo "Finished"

waitFor f()
