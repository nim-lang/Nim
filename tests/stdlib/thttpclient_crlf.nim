discard """
  matrix: "--mm:arc; --mm:refc"
  joinable: false
"""

# CR, LF and NUL in the request target or in header fields could inject
# headers or whole requests; they are rejected before anything is sent.

import std/[asynchttpserver, httpclient, asyncdispatch, assertions, uri]

proc main() {.async.} =
  let server = newAsyncHttpServer()
  server.listen(Port(0), address = "127.0.0.1")
  var requests = 0
  proc cb(req: Request) {.async, gcsafe.} =
    inc requests
    await req.respond(Http200, "ok")
  proc serve() {.async.} =
    try:
      while true: await server.acceptRequest(cb)
    except OSError: discard
  asyncCheck serve()
  let base = "http://127.0.0.1:" & $server.getPort.uint16

  proc rejected(url: Uri; headers: HttpHeaders = nil): Future[bool] {.async.} =
    let client = newAsyncHttpClient()
    try:
      discard await client.request(url, headers = headers)
      result = false
    except ValueError:
      result = true
    client.close()

  let injected = "\r\nX-Injected: 1\r\n"
  var u = parseUri(base & "/")
  u.path = "/a" & injected
  doAssert await rejected(u)
  u = parseUri(base & "/")
  u.query = "a=1 HTTP/1.1" & injected
  doAssert await rejected(u)
  u = parseUri(base & "/")
  u.path = "/a\0b"
  doAssert await rejected(u)
  u = parseUri(base & "/")
  doAssert await rejected(u, newHttpHeaders({"X-A": "v" & injected}))
  doAssert await rejected(u, newHttpHeaders({"X-A\nX-B": "v"}))
  doAssert await rejected(u, newHttpHeaders({"X-A": "v\n"}))

  block: # client.headers are checked too
    let client = newAsyncHttpClient(headers = newHttpHeaders({"X-A": "v\r\n"}))
    doAssertRaises(ValueError): discard await client.request(u)
    client.close()

  doAssert requests == 0
  # a clean request still works
  let client = newAsyncHttpClient()
  doAssert (await client.request(u)).code == Http200
  client.close()
  doAssert requests == 1
  server.close()

waitFor main()
