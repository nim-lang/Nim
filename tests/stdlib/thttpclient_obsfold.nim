discard """
  matrix: "--mm:arc; --mm:refc"
  joinable: false
"""

# A header value continued on the next line (obs-fold) kept the line break,
# so the value was "a\n  b" instead of "a b".

import std/[asyncdispatch, asyncnet, httpclient, assertions]

proc respond(server: AsyncSocket) {.async.} =
  let client = await server.accept()
  while (await client.recvLine()) notin ["\r\n", ""]: discard
  await client.send("HTTP/1.1 200 OK\r\nX-Folded: a\r\n  b\r\n\tc\r\n" &
                    "Content-Length: 5\r\n\r\nhello")
  client.close()

proc fetch(): Future[(HttpHeaders, string)] {.async.} =
  let server = newAsyncSocket()
  server.bindAddr(Port(0), "127.0.0.1")
  server.listen()
  asyncCheck respond(server)
  let client = newAsyncHttpClient()
  let response = await client.get("http://127.0.0.1:" &
                                  $server.getLocalAddr()[1].uint16 & "/")
  result = (response.headers, await response.body)
  client.close()
  server.close()

let (headers, body) = waitFor(fetch())
doAssert headers["X-Folded"] == "a b c", headers["X-Folded"]
doAssert headers["Content-Length"] == "5"
doAssert body == "hello", body
