discard """
  matrix: "--mm:arc; --mm:refc"
  joinable: false
"""

# Informational (1xx) responses such as 103 Early Hints came back as the
# response, with the final response read as their body.

import std/[asyncdispatch, asyncnet, httpclient, assertions]

proc respond(server: AsyncSocket; interim: string) {.async.} =
  let client = await server.accept()
  while (await client.recvLine()) notin ["\r\n", ""]: discard
  await client.send(interim &
                    "HTTP/1.1 200 OK\r\nContent-Length: 5\r\nX-Final: 1\r\n\r\nhello")
  client.close()

proc fetch(interim: string): Future[(HttpCode, HttpHeaders, string)] {.async.} =
  let server = newAsyncSocket()
  server.bindAddr(Port(0), "127.0.0.1")
  server.listen()
  asyncCheck respond(server, interim)
  let client = newAsyncHttpClient()
  let response = await client.get("http://127.0.0.1:" &
                                  $server.getLocalAddr()[1].uint16 & "/")
  result = (response.code, response.headers, await response.body)
  client.close()
  server.close()

for interim in [
    "HTTP/1.1 103 Early Hints\r\nLink: </style.css>; rel=preload\r\n\r\n",
    "HTTP/1.1 100 Continue\r\n\r\n",
    "HTTP/1.1 102 Processing\r\n\r\nHTTP/1.1 103 Early Hints\r\nLink: </a.css>\r\n\r\n"]:
  let (code, headers, body) = waitFor(fetch(interim))
  doAssert code == Http200, $code
  doAssert body == "hello", body
  doAssert headers["X-Final"] == "1"
  doAssert not headers.hasKey("Link")
