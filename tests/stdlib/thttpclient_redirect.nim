discard """
  matrix: "--mm:arc; --mm:refc"
  joinable: false
"""

# Credentials are not sent to another origin when following a redirect.

import std/[asynchttpserver, httpclient, asyncdispatch, assertions, strutils]

type Seen = ref object
  requests: seq[(string, HttpHeaders)]

proc serveForever(server: AsyncHttpServer; seen: Seen; target: ref string) {.async.} =
  proc cb(req: Request) {.async, gcsafe.} =
    # `req.headers` is reused for the next request on the connection
    let headers = newHttpHeaders()
    headers.table[] = req.headers.table[]
    seen.requests.add (req.url.path, headers)
    if req.url.path == "/redirect":
      await req.respond(Http302, "", newHttpHeaders({"Location": target[]}))
    elif req.url.path == "/back":
      await req.respond(Http302, "", newHttpHeaders({"Location": target[] & "/final"}))
    else:
      await req.respond(Http200, "ok")
  try:
    while true:
      await server.acceptRequest(cb)
  except OSError:
    discard # the server was closed

proc main() {.async.} =
  let a = newAsyncHttpServer()
  a.listen(Port(0), address = "127.0.0.1")
  let b = newAsyncHttpServer()
  b.listen(Port(0), address = "127.0.0.1")
  let urlA = "http://127.0.0.1:" & $a.getPort.uint16
  let urlB = "http://127.0.0.1:" & $b.getPort.uint16
  let seenA = Seen()
  let seenB = Seen()
  let targetA = new string
  let targetB = new string
  asyncCheck serveForever(a, seenA, targetA)
  asyncCheck serveForever(b, seenB, targetB)

  proc newClient(): AsyncHttpClient =
    newAsyncHttpClient(headers = newHttpHeaders({
      "Authorization": "Bearer client", "Cookie": "sid=client"}))

  block: # same origin keeps the credentials
    targetA[] = urlA & "/final"
    let client = newClient()
    let resp = await client.get(urlA & "/redirect")
    doAssert resp.code == Http200
    client.close()
    doAssert seenA.requests.len == 2
    let h = seenA.requests[1][1]
    doAssert h["Authorization"] == "Bearer client"
    doAssert h["Cookie"] == "sid=client"
    seenA.requests.setLen 0

  block: # another origin (here: another port) gets neither
    targetA[] = urlB & "/final"
    let client = newClient()
    let perRequest = newHttpHeaders({"Authorization": "Bearer request",
                                     "Cookie": "sid=request", "X-Keep": "1"})
    let resp = await client.request(urlA & "/redirect", headers = perRequest)
    doAssert resp.code == Http200
    client.close()
    doAssert seenA.requests.len == 1
    doAssert seenA.requests[0][1]["Authorization"] == "Bearer request"
    doAssert seenB.requests.len == 1
    let h = seenB.requests[0][1]
    doAssert not h.hasKey("Authorization"), $h
    doAssert not h.hasKey("Cookie"), $h
    doAssert h["X-Keep"] == "1"
    doAssert h["Host"] == urlB.substr("http://".len)
    # the caller's headers are not modified
    doAssert perRequest["Authorization"] == "Bearer request"
    doAssert perRequest["Cookie"] == "sid=request"
    seenA.requests.setLen 0
    seenB.requests.setLen 0

  block: # and a redirect back to the original origin does not restore them
    targetA[] = urlB & "/back"
    targetB[] = urlA
    let client = newClient()
    let resp = await client.get(urlA & "/redirect")
    doAssert resp.code == Http200
    client.close()
    doAssert seenA.requests.len == 2
    doAssert seenA.requests[0][1]["Authorization"] == "Bearer client"
    let h = seenA.requests[1][1]
    doAssert seenA.requests[1][0] == "/final"
    doAssert not h.hasKey("Authorization"), $h
    doAssert not h.hasKey("Cookie"), $h

  a.close()
  b.close()

waitFor main()
