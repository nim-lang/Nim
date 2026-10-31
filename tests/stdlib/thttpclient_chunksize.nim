discard """
  matrix: "--mm:arc; --mm:refc"
  joinable: false
"""

# A chunk size with more hex digits than fit into an int wrapped around, so
# "10000000000000005" was read as 5 and the rest of the body was misframed.

import std/[asyncdispatch, asyncnet, httpclient, assertions, strutils]

proc respond(server: AsyncSocket; chunkSize: string) {.async.} =
  let client = await server.accept()
  while (await client.recvLine()) notin ["\r\n", ""]: discard
  await client.send("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n" &
                    chunkSize & "\r\nhello\r\n0\r\n\r\n")
  client.close()

proc fetch(chunkSize: string): Future[string] {.async.} =
  let server = newAsyncSocket()
  server.bindAddr(Port(0), "127.0.0.1")
  server.listen()
  asyncCheck respond(server, chunkSize)
  let client = newAsyncHttpClient()
  try:
    result = await client.getContent("http://127.0.0.1:" &
                                     $server.getLocalAddr()[1].uint16 & "/")
  except ProtocolError as e:
    result = "error: " & e.msg
  client.close()
  server.close()

doAssert waitFor(fetch("5")) == "hello"
doAssert waitFor(fetch("0000000000000000005")) == "hello"
for size in ["10000000000000005", "FFFFFFFFFFFFFFFFF"]:
  let r = waitFor(fetch(size))
  doAssert r.startsWith("error: Invalid chunk size"), r
