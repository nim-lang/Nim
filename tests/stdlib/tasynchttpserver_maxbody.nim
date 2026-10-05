# SPDX-License-Identifier: ISC
discard """
  matrix: "--mm:arc; --mm:arc -d:danger; --mm:refc"
  joinable: false
"""

import asynchttpserver
import std/[asyncdispatch, asyncnet, assertions, strutils]

# Real HTTP requests on an ephemeral loopback port, one connection at a time.
# The largest body/declared chunk is nine bytes; each read has a two-second bound.
proc checkBodyLimit(framing, body: string; maximum: int; expected: HttpCode;
                    expectedBody = "") {.async.} =
  let server = newAsyncHttpServer(maxBody = maximum)
  var handled = false
  var observedBody = ""
  proc handler(request: Request) {.async, gcsafe.} =
    handled = true
    observedBody = request.body
    await request.respond(Http200, "ok")

  server.listen(Port(0), address = "127.0.0.1")
  defer: server.close()
  let client = newAsyncSocket()
  defer: client.close()
  let accepted = server.acceptRequest(handler)
  let connected = client.connect("127.0.0.1", server.getPort())
  doAssert await connected.withTimeout(2000)
  await connected
  doAssert await accepted.withTimeout(2000)
  await accepted
  await client.send("POST / HTTP/1.1\r\nHost: localhost\r\n" & framing &
    "\r\nConnection: close\r\n\r\n" & body)

  let status = client.recvLine()
  doAssert await status.withTimeout(2000)
  let statusLine = await status
  # The server must close rejected requests instead of parsing unread body bytes
  # as another request. Drain the bounded response to verify closure as well.
  var responseBytes = 0
  while true:
    let pending = client.recv(256)
    doAssert await pending.withTimeout(2000)
    let chunk = await pending
    if chunk.len == 0: break
    responseBytes += chunk.len
    doAssert responseBytes <= 1024
  doAssert statusLine.startsWith("HTTP/1.1 " & $expected),
    "Expected " & $expected & "; received " & statusLine
  doAssert handled == (expected == Http200)
  if handled: doAssert observedBody == expectedBody

block: # Chunked bodies below and exactly at the limit remain valid.
  waitFor checkBodyLimit("Transfer-Encoding: chunked",
    "3\r\nabc\r\n0\r\n\r\n", 8, Http200, "abc")
  waitFor checkBodyLimit("Transfer-Encoding: chunked",
    "4\r\nabcd\r\n4\r\nefgh\r\n0\r\n\r\n", 8, Http200, "abcdefgh")

block: # Reject a single chunk or cumulative body exceeding the limit.
  waitFor checkBodyLimit("Transfer-Encoding: chunked",
    "9\r\nabcdefghi\r\n0\r\n\r\n", 8, Http413)
  waitFor checkBodyLimit("Transfer-Encoding: chunked",
    "4\r\nabcd\r\n5\r\nefghi\r\n0\r\n\r\n", 8, Http413)

block: # Reject oversized declarations before waiting for their chunk data.
  waitFor checkBodyLimit("Transfer-Encoding: chunked", "9\r\n", 8, Http413)
  waitFor checkBodyLimit("Transfer-Encoding: chunked",
    "4\r\nabcd\r\n5\r\n", 8, Http413)

block: # A zero body limit accepts only an empty body.
  waitFor checkBodyLimit("Transfer-Encoding: chunked", "0\r\n\r\n", 0, Http200)
  waitFor checkBodyLimit("Transfer-Encoding: chunked", "1\r\n", 0, Http413)

block: # Content-Length boundary behavior remains unchanged.
  waitFor checkBodyLimit("Content-Length: 8", "abcdefgh", 8, Http200, "abcdefgh")
  waitFor checkBodyLimit("Content-Length: 9", "", 8, Http413)
