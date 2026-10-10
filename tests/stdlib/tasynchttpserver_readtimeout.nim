discard """
  matrix: "--mm:arc; --mm:arc -d:danger; --mm:refc"
  joinable: false
"""

import std/[asyncdispatch, asyncnet, assertions, strutils, monotimes, times]
import asynchttpserver

# Real HTTP requests on an ephemeral loopback port. Every client-side wait is
# bounded by `patience`, which a passing run never reaches; the timeout under
# test is `readTimeout`.
const
  readTimeout = 300
  patience = 3000
  # The server starts its clock when it accepts, a moment before the client
  # sends, so a connection can look slightly younger than `readTimeout`.
  slack = 100

type Handler = proc (request: Request): Future[void] {.closure, gcsafe.}

proc within[T](fut: Future[T]): Future[T] {.async.} =
  doAssert await fut.withTimeout(patience), "the awaited operation hung"
  when T is void:
    await fut
  else:
    return await fut

proc okHandler(request: Request): Future[void] {.gcsafe.} =
  request.respond(Http200, "ok")

proc connectTo(server: AsyncHttpServer, handler: Handler): Future[AsyncSocket] {.async.} =
  let client = newAsyncSocket()
  let accepted = server.acceptRequest(handler)
  await within client.connect("127.0.0.1", server.getPort())
  await within accepted
  return client

proc startServer(timeout: int): AsyncHttpServer =
  result = newAsyncHttpServer(readTimeout = timeout)
  result.listen(Port(0), address = "127.0.0.1")

proc readResponse(client: AsyncSocket): Future[tuple[status, body: string]] {.async.} =
  ## One response with a `Content-Length` body, as `okHandler` writes it.
  result.status = await within client.recvLine()
  var length = 0
  while true:
    let line = await within client.recvLine()
    if line == "\c\L": break
    if line.toLowerAscii.startsWith("content-length:"):
      length = parseInt(line.split(':')[1].strip)
  if length > 0:
    result.body = await within client.recv(length)

proc drain(client: AsyncSocket): Future[string] {.async.} =
  ## Everything the server sends until it closes the connection.
  while true:
    let chunk = await within client.recv(256)
    if chunk.len == 0: break
    result.add chunk

proc elapsedMs(since: MonoTime): int =
  int (getMonoTime() - since).inMilliseconds

proc stalledAfter(prefix: string): Future[tuple[reply: string, waitedMs: int]] {.async.} =
  ## Sends `prefix` of a request, then nothing, and reports what the server
  ## did and when it let go of the connection.
  var handled = false
  proc handler(request: Request): Future[void] {.closure, gcsafe.} =
    handled = true
    request.respond(Http200, "ok")
  let server = startServer(readTimeout)
  defer: server.close()
  let client = await connectTo(server, handler)
  defer: client.close()
  await client.send(prefix)
  let sent = getMonoTime()
  result.reply = await drain(client)
  result.waitedMs = elapsedMs(sent)
  doAssert not handled, "a request that never finished reached the handler"

proc expectClosedAfterTimeout(prefix, expectedReply: string) =
  let (reply, waitedMs) = waitFor stalledAfter(prefix)
  doAssert waitedMs >= readTimeout - slack,
    "closed after " & $waitedMs & "ms, before the " & $readTimeout & "ms timeout"
  if expectedReply.len == 0:
    doAssert reply.len == 0, "expected a silent close, got: " & reply
  else:
    doAssert reply.startsWith(expectedReply),
      "expected " & expectedReply & ", got: " & reply

block: # a request line that stops half way is dropped without a reply
  expectClosedAfterTimeout("GET /sl", "")

block: # headers that stop half way get a 408 and the connection is closed
  expectClosedAfterTimeout("GET / HTTP/1.1\r\nHost: loca", "HTTP/1.1 408")
  expectClosedAfterTimeout("GET / HTTP/1.1\r\nHost: localhost\r\n", "HTTP/1.1 408")

block: # a declared body that never arrives gets a 408
  expectClosedAfterTimeout(
    "POST / HTTP/1.1\r\nHost: localhost\r\nContent-Length: 10\r\n\r\nabc",
    "HTTP/1.1 408")

block: # a chunked body that stops after a chunk gets a 408
  expectClosedAfterTimeout(
    "POST / HTTP/1.1\r\nHost: localhost\r\nTransfer-Encoding: chunked\r\n\r\n" &
      "3\r\nabc\r\n",
    "HTTP/1.1 408")

block: # a connection that never sends anything is dropped without a reply
  expectClosedAfterTimeout("", "")

block: # trickling bytes does not extend the deadline
  proc trickle() {.async.} =
    let server = startServer(readTimeout)
    defer: server.close()
    let client = await connectTo(server, okHandler)
    defer: client.close()
    await client.send("GET / HTTP/1.1\r\n")
    let started = getMonoTime()
    let closed = drain(client)
    # An endless header, one byte every 50ms: far longer than the timeout.
    var header = "X-Slow: " & repeat('a', 40)
    for c in header:
      if closed.finished: break
      await client.send($c)
      await sleepAsync(50)
    let reply = await closed
    let waitedMs = elapsedMs(started)
    doAssert reply.startsWith("HTTP/1.1 408"), "got: " & reply
    doAssert waitedMs < 4 * readTimeout,
      "kept the connection for " & $waitedMs & "ms by trickling"
  waitFor trickle()

block: # a request that arrives in time is served, and so is the next one
  proc ordinary() {.async.} =
    let server = startServer(readTimeout)
    defer: server.close()
    let client = await connectTo(server, okHandler)
    defer: client.close()
    for i in 1 .. 2:
      await client.send("GET / HTTP/1.1\r\nHost: localhost\r\n")
      await sleepAsync(readTimeout div 3)
      await client.send("\r\n")
      let (status, body) = await readResponse(client)
      doAssert status.startsWith("HTTP/1.1 200"), "got: " & status
      doAssert body == "ok"
  waitFor ordinary()

block: # each request gets a fresh deadline, so a busy connection is not cut off
  proc busy() {.async.} =
    let server = startServer(readTimeout)
    defer: server.close()
    let client = await connectTo(server, okHandler)
    defer: client.close()
    for i in 1 .. 5:
      await sleepAsync(readTimeout div 2)
      await client.send("GET / HTTP/1.1\r\nHost: localhost\r\n\r\n")
      let (status, _) = await readResponse(client)
      doAssert status.startsWith("HTTP/1.1 200"), "request " & $i & " got: " & status
  waitFor busy()

block: # a keep-alive connection that stays idle is closed without a reply
  proc idle() {.async.} =
    let server = startServer(readTimeout)
    defer: server.close()
    let client = await connectTo(server, okHandler)
    defer: client.close()
    await client.send("GET / HTTP/1.1\r\nHost: localhost\r\n\r\n")
    let (status, _) = await readResponse(client)
    doAssert status.startsWith("HTTP/1.1 200")
    let idleSince = getMonoTime()
    let reply = await drain(client)
    doAssert reply.len == 0, "expected a silent close, got: " & reply
    doAssert elapsedMs(idleSince) >= readTimeout - slack
  waitFor idle()

block: # a handler that runs longer than the timeout is not interrupted
  proc slowHandler() {.async.} =
    proc handler(request: Request): Future[void] {.closure, gcsafe.} =
      proc respondLate(): Future[void] {.async.} =
        await sleepAsync(3 * readTimeout)
        await request.respond(Http200, "ok")
      respondLate()
    let server = startServer(readTimeout)
    defer: server.close()
    let client = await connectTo(server, handler)
    defer: client.close()
    await client.send("GET / HTTP/1.1\r\nHost: localhost\r\n\r\n")
    let (status, body) = await readResponse(client)
    doAssert status.startsWith("HTTP/1.1 200"), "got: " & status
    doAssert body == "ok"
  waitFor slowHandler()

block: # without a readTimeout a stalled request is waited for, as before
  proc patient() {.async.} =
    let server = startServer(0)
    defer: server.close()
    let client = await connectTo(server, okHandler)
    defer: client.close()
    await client.send("GET / HTTP/1.1\r\nHost: localhost\r\n")
    await sleepAsync(3 * readTimeout)
    await client.send("\r\n")
    let (status, body) = await readResponse(client)
    doAssert status.startsWith("HTTP/1.1 200"), "got: " & status
    doAssert body == "ok"
  waitFor patient()

block: # the abandoned reads settle without disturbing the event loop
  # Everything above left pending reads behind on closed sockets. Let them run.
  waitFor sleepAsync(2 * readTimeout)

echo "OK"
