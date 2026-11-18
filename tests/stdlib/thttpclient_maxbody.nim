discard """
  matrix: "--mm:arc; --mm:refc"
  joinable: false
"""

# The client used to buffer any response body in full, so a hostile server
# could exhaust memory. `maxBodySize` caps it for every way of framing a body.

import std/[asyncdispatch, asyncnet, httpclient, assertions, strutils]

proc respond(server: AsyncSocket; response: string) {.async.} =
  let client = await server.accept()
  while (await client.recvLine()) notin ["\r\n", ""]: discard
  try:
    await client.send(response)
  except OSError: discard # the client may hang up early
  client.close()

proc fetch(response: string; maxBodySize: int): Future[string] {.async.} =
  let server = newAsyncSocket()
  server.bindAddr(Port(0), "127.0.0.1")
  server.listen()
  asyncCheck respond(server, response)
  let client = newAsyncHttpClient(maxBodySize = maxBodySize)
  try:
    result = await client.getContent("http://127.0.0.1:" &
                                     $server.getLocalAddr()[1].uint16 & "/")
  except ProtocolError as e:
    result = "error: " & e.msg
  client.close()
  server.close()

let body = "x".repeat(100)
let sized = "HTTP/1.1 200 OK\r\nContent-Length: 100\r\n\r\n" & body
let chunked = "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n" &
              "32\r\n" & body[0..49] & "\r\n32\r\n" & body[0..49] & "\r\n0\r\n\r\n"
let untilClose = "HTTP/1.1 200 OK\r\nConnection: close\r\n\r\n" & body

for response in [sized, chunked, untilClose]:
  doAssert waitFor(fetch(response, -1)) == body
  doAssert waitFor(fetch(response, 100)) == body
  let r = waitFor(fetch(response, 99))
  doAssert r.startsWith("error: Response body exceeds"), r

# a huge declared length is refused before any of it is read
let r = waitFor(fetch("HTTP/1.1 200 OK\r\nContent-Length: 1000000000000\r\n\r\n",
                      1 shl 20))
doAssert r.startsWith("error: Response body exceeds"), r
