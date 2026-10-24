discard """
  matrix: "--mm:arc; --mm:refc"
  joinable: false
"""

# Request bodies must be read completely, whatever the request method, so that
# no part of a body is parsed as another request on the same connection.

import std/[asynchttpserver, asyncdispatch, asyncnet, assertions, strutils]

proc serve(data: string): Future[(seq[string], string)] {.async.} =
  ## Sends `data` on one connection and returns the "METHOD path body" of
  ## every request the callback saw plus the raw response bytes.
  let server = newAsyncHttpServer()
  var seen: seq[string] = @[]
  proc handler(request: Request) {.async, gcsafe.} =
    seen.add $request.reqMethod & " " & request.url.path & " " & request.body
    await request.respond(Http200, "ok")

  server.listen(Port(0), address = "127.0.0.1")
  defer: server.close()
  let client = newAsyncSocket()
  defer: client.close()
  let accepted = server.acceptRequest(handler)
  await client.connect("127.0.0.1", server.getPort())
  await accepted
  await client.send(data)
  var response = ""
  while true:
    let pending = client.recv(4096)
    doAssert await pending.withTimeout(2000)
    let chunk = await pending
    if chunk.len == 0: break
    response.add chunk
  result = (seen, response)

const smuggled = "GET /admin HTTP/1.1\r\nHost: x\r\n\r\n"
const last = "GET /last HTTP/1.1\r\nHost: x\r\nConnection: close\r\n\r\n"

block: # chunked bodies are read for every method, not only POST
  for meth in ["PUT", "PATCH", "DELETE", "GET", "OPTIONS"]:
    let body = smuggled
    let (seen, response) = waitFor serve(meth & " /a HTTP/1.1\r\nHost: x\r\n" &
      "Transfer-Encoding: chunked\r\n\r\n" &
      toHex(body.len) & "\r\n" & body & "\r\n0\r\n\r\n" & last)
    doAssert seen == @[meth & " /a " & smuggled, "GET /last "], $seen & response

block: # chunk extensions are ignored, not a reason to misparse
  let (seen, _) = waitFor serve("POST /a HTTP/1.1\r\nHost: x\r\n" &
    "Transfer-Encoding: chunked\r\n\r\n" &
    "3;name=value\r\nabc\r\n0;x=y\r\n\r\n" & last)
  doAssert seen == @["POST /a abc", "GET /last "], $seen

block: # trailer fields are consumed
  let (seen, _) = waitFor serve("POST /a HTTP/1.1\r\nHost: x\r\n" &
    "Transfer-Encoding: chunked\r\n\r\n" &
    "3\r\nabc\r\n0\r\n" & smuggled & last)
  # the trailer section ends at the first empty line, i.e. the smuggled
  # request's header lines are trailers and `last` is the next request
  doAssert seen == @["POST /a abc", "GET /last "], $seen

block: # case of the transfer coding does not matter
  let (seen, _) = waitFor serve("POST /a HTTP/1.1\r\nHost: x\r\n" &
    "Transfer-Encoding: Chunked\r\n\r\n" &
    "3\r\nabc\r\n0\r\n\r\n" & last)
  doAssert seen == @["POST /a abc", "GET /last "], $seen

block: # malformed chunk sizes close the connection
  for size in ["0x3", "+3", "3_", "-1", "", "1111111111111111111"]:
    let (seen, response) = waitFor serve("POST /a HTTP/1.1\r\nHost: x\r\n" &
      "Transfer-Encoding: chunked\r\n\r\n" &
      size & "\r\nabc\r\n0\r\n\r\n" & smuggled)
    doAssert seen.len == 0, $seen
    doAssert response.startsWith("HTTP/1.1 400") or
             response.startsWith("HTTP/1.1 413"), response
    doAssert response.count("HTTP/1.1") == 1, response

block: # a malformed request line closes the connection
  let (seen, response) = waitFor serve("FOO / HTTP/1.1\r\n" & smuggled)
  doAssert seen.len == 0, $seen
  doAssert response.count("HTTP/1.1") == 1, response

block: # an invalid Content-Length closes the connection
  let (seen, response) = waitFor serve("POST /a HTTP/1.1\r\nHost: x\r\n" &
    "Content-Length: x\r\n\r\n" & smuggled)
  doAssert seen.len == 0, $seen
  doAssert response.count("HTTP/1.1") == 1, response
