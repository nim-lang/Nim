discard """
  matrix: "--mm:arc; --mm:arc -d:danger; --mm:refc"
  joinable: false
"""

import std/[asyncdispatch, asyncnet, assertions, strutils]
import asynchttpserver

# Real HTTP requests on an ephemeral loopback port. Every client-side wait is
# bounded by `patience`, which a passing run never reaches.
const patience = 3000

proc within[T](fut: Future[T]): Future[T] {.async.} =
  doAssert await fut.withTimeout(patience), "the awaited operation hung"
  when T is void:
    await fut
  else:
    return await fut

proc drain(client: AsyncSocket): Future[string] {.async.} =
  ## Everything the server sends until it closes the connection.
  while true:
    let chunk = await within client.recv(256)
    if chunk.len == 0: break
    result.add chunk

proc fieldsOf(head: string): Future[seq[tuple[name, value: string]]] {.async.} =
  ## The `headerFields` the handler sees for a request with this head.
  var seen: seq[tuple[name, value: string]]
  proc handler(request: Request): Future[void] {.closure, gcsafe.} =
    seen = request.headerFields
    request.respond(Http200, "ok")
  let server = newAsyncHttpServer()
  server.listen(Port(0), address = "127.0.0.1")
  defer: server.close()
  let client = newAsyncSocket()
  defer: client.close()
  let accepted = server.acceptRequest(handler)
  await within client.connect("127.0.0.1", server.getPort())
  await client.send("GET / HTTP/1.0\c\L" & head & "\c\L")
  await within accepted
  discard await drain(client)
  return seen

proc main() {.async.} =
  block: # a value with commas arrives whole, as sent
    let fields = await fieldsOf("Host: example\c\LX-Region: us-west1,eu-west1\c\LX-Text: a, b\c\L")
    doAssert fields == @[("Host", "example"), ("X-Region", "us-west1,eu-west1"),
                         ("X-Text", "a, b")], $fields

  block: # repeated lines are all kept, in order
    let fields = await fieldsOf("Accept: text/html\c\LAccept: application/json\c\L")
    doAssert fields == @[("Accept", "text/html"), ("Accept", "application/json")], $fields

  block: # the whitespace around a value is not part of it; inner whitespace is
    let fields = await fieldsOf("X-Pad: \t inner  space \t\c\LX-Empty:\c\L")
    doAssert fields == @[("X-Pad", "inner  space"), ("X-Empty", "")], $fields

  block: # `headers` still splits at commas, as before
    var accept: seq[string]
    proc handler(request: Request): Future[void] {.closure, gcsafe.} =
      accept = seq[string](request.headers["Accept"])
      request.respond(Http200, "ok")
    let server = newAsyncHttpServer()
    server.listen(Port(0), address = "127.0.0.1")
    defer: server.close()
    let client = newAsyncSocket()
    defer: client.close()
    let accepted = server.acceptRequest(handler)
    await within client.connect("127.0.0.1", server.getPort())
    await client.send("GET / HTTP/1.0\c\LAccept: text/html, application/json\c\L\c\L")
    await within accepted
    discard await drain(client)
    doAssert accept == @["text/html", "application/json"], $accept

  block: # a request is not given the lines of the one before it on the connection
    var counts: seq[int]
    proc handler(request: Request): Future[void] {.closure, gcsafe.} =
      counts.add request.headerFields.len
      request.respond(Http200, "ok")
    let server = newAsyncHttpServer()
    server.listen(Port(0), address = "127.0.0.1")
    defer: server.close()
    let client = newAsyncSocket()
    defer: client.close()
    let accepted = server.acceptRequest(handler)
    await within client.connect("127.0.0.1", server.getPort())
    await client.send("GET /a HTTP/1.1\c\LX-A: 1\c\LX-B: 2\c\L\c\L" &
                      "GET /b HTTP/1.1\c\LX-C: 3\c\LConnection: close\c\L\c\L")
    await within accepted
    discard await drain(client)
    doAssert counts == @[2, 2], $counts

  block: # repeated lines of one name are limited like distinct names
    var handled = false
    proc handler(request: Request): Future[void] {.closure, gcsafe.} =
      handled = true
      request.respond(Http200, "ok")
    let server = newAsyncHttpServer()
    server.listen(Port(0), address = "127.0.0.1")
    defer: server.close()
    let client = newAsyncSocket()
    defer: client.close()
    let accepted = server.acceptRequest(handler)
    await within client.connect("127.0.0.1", server.getPort())
    await client.send("GET / HTTP/1.0\c\L" & "X-Same: v\c\L".repeat(10_001) & "\c\L")
    await within accepted
    let reply = await drain(client)
    doAssert reply.startsWith("HTTP/1.1 400"), reply
    doAssert not handled, "a request over the header limit reached the handler"

waitFor main()
