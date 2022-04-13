discard """
  cmd: "nim c --threads:on $file"
  exitcode: 0
  output: "OK"
  disabled: false
"""

import strutils
from net import TimeoutError

import httpclient, asynchttpserver, asyncdispatch, asyncfutures

template runTest(
    handler: proc (request: Request): Future[void] {.gcsafe.},
    request: proc (server: AsyncHttpServer): Future[AsyncResponse],
    test: proc (response: AsyncResponse, body: string): Future[void]) =

  let server = newAsyncHttpServer()

  discard server.serve(Port(64123), handler)

  let
    response = waitFor(request(server))
    body = waitFor(response.body)

  discard test(response, body)

proc test200() {.async.} =
  proc handler(request: Request) {.async.} =
    await request.respond(Http200, "Hello World, 200")

  proc request(server: AsyncHttpServer): Future[AsyncResponse] {.async.} =
    let
      client = newAsyncHttpClient()
      clientResponse = await client.request("http://localhost:64123/")

    server.close()

    return clientResponse

  proc test(response: AsyncResponse, body: string) {.async.} =
    doAssert(response.status == Http200)
    doAssert(body == "Hello World, 200")
    doAssert(response.headers.hasKey("Content-Length"))
    doAssert(response.headers["Content-Length"] == "16")

  runTest(handler, request, test)

proc test404() {.async.} =
  proc handler(request: Request) {.async.} =
    await request.respond(Http404, "Hello World, 404")

  proc request(server: AsyncHttpServer): Future[AsyncResponse] {.async.} =
    let
      client = newAsyncHttpClient()
      clientResponse = await client.request("http://localhost:64123/")

    server.close()

    return clientResponse

  proc test(response: AsyncResponse, body: string) {.async.} =
    doAssert(response.status == Http404)
    doAssert(body == "Hello World, 404")
    doAssert(response.headers.hasKey("Content-Length"))
    doAssert(response.headers["Content-Length"] == "16")

  runTest(handler, request, test)

proc testCustomEmptyHeaders() {.async.} =
  proc handler(request: Request) {.async.} =
    await request.respond(Http200, "Hello World, 200", newHttpHeaders())

  proc request(server: AsyncHttpServer): Future[AsyncResponse] {.async.} =
    let
      client = newAsyncHttpClient()
      clientResponse = await client.request("http://localhost:64123/")

    server.close()

    return clientResponse

  proc test(response: AsyncResponse, body: string) {.async.} =
    doAssert(response.status == Http200)
    doAssert(body == "Hello World, 200")
    doAssert(response.headers.hasKey("Content-Length"))
    doAssert(response.headers["Content-Length"] == "16")

  runTest(handler, request, test)

proc testCustomContentLength() {.async.} =
  proc handler(request: Request) {.async.} =
    let headers = newHttpHeaders()
    headers["Content-Length"] = "0"
    await request.respond(Http200, "Hello World, 200", headers)

  proc request(server: AsyncHttpServer): Future[AsyncResponse] {.async.} =
    let
      client = newAsyncHttpClient()
      clientResponse = await client.request("http://localhost:64123/")

    server.close()

    return clientResponse

  proc test(response: AsyncResponse, body: string) {.async.} =
    doAssert(response.status == Http200)
    doAssert(body == "")
    doAssert(response.headers.hasKey("Content-Length"))
    doAssert(response.headers["Content-Length"] == "0")

  runTest(handler, request, test)

waitFor(test200())
waitFor(test404())
waitFor(testCustomEmptyHeaders())
waitFor(testCustomContentLength())

echo "OK"
