discard """
  cmd: "nim c --threads:on $file"
  exitcode: 0
  output: "[Suite] asynchttpserver"
  disabled: false
"""

import strutils
from net import TimeoutError

import unittest, httpclient, asynchttpserver, asyncdispatch, asyncfutures

template runTest(
    handler: proc (request: Request): Future[void] {.gcsafe.},
    request: proc (server: AsyncHttpServer): Future[AsyncResponse],
    test: proc (response: AsyncResponse, body: string): Future[void]) =

  let server = newAsyncHttpServer()

  discard server.serve(Port(64123), handler)

  let
    response = waitFor(request(server))
    body = waitFor(response.body)

  waitFor(test(response, body))


suite "asynchttpserver":

  test "HTTP 200":
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
        assert response.status == Http200
        assert body == "Hello World, 200"
        assert response.headers.hasKey("Content-Length")
        assert response.headers["Content-Length"] == "16"

      runTest(handler, request, test)

    waitfor(test200())


  test "HTTP 404":
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
        assert response.status == Http404
        assert body == "Hello World, 404"
        assert response.headers.hasKey("Content-Length")
        assert response.headers["Content-Length"] == "16"

      runTest(handler, request, test)

    waitfor(test404())


  test "Custom Empty Headers":
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
        assert response.status == Http200
        assert body == "Hello World, 200"
        assert response.headers.hasKey("Content-Length")
        assert response.headers["Content-Length"] == "16"

      runTest(handler, request, test)

    waitfor(testCustomEmptyHeaders())

  test "Custom Content-Length":
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
        assert response.status == Http200
        assert body == ""
        assert response.headers.hasKey("Content-Length")
        assert response.headers["Content-Length"] == "0"

      runTest(handler, request, test)

    waitfor(testCustomContentLength())

  test "User-Agent is split wrongly":
    # This testcase exposes asynchttpserver wrongly handling a header with a
    # comma in it.

    proc testUserAgentSplit() {.async.} =
      proc handler(request: Request) {.async.} =
        assert request.headers.hasKey("User-Agent")
        assert request.headers["User-Agent"] == "foo"

        let headers = newHttpHeaders()
        await request.respond(Http200, "Hello World, 200", headers)

      proc request(server: AsyncHttpServer): Future[AsyncResponse] {.async.} =
        let
          client = newAsyncHttpClient(userAgent = "foo, bar")
          clientResponse = await client.request("http://localhost:64123/")

        server.close()

        return clientResponse

      proc test(response: AsyncResponse, body: string) {.async.} =
        assert response.status == Http200

      runTest(handler, request, test)

    waitfor(testUserAgentSplit())

  test "Custom header":
    proc testCustomHeader() {.async.} =
      proc handler(request: Request) {.async.} =
        assert request.headers.hasKey("X-Test")
        assert request.headers["X-Test", 0] == "foo"
        assert request.headers["X-Test", 1] == "bar"

        let headers = newHttpHeaders()
        await request.respond(Http200, "Hello World, 200", headers)

      proc request(server: AsyncHttpServer): Future[AsyncResponse] {.async.} =
        let headers = newHttpHeaders()
        headers["X-Test"] = "foo, bar"

        let
          client = newAsyncHttpClient(userAgent = "foo, bar")
          clientResponse = await client.request("http://localhost:64123/", headers = headers)

        server.close()

        return clientResponse

      proc test(response: AsyncResponse, body: string) {.async.} =
        assert response.status == Http200

      runTest(handler, request, test)

    waitfor(testCustomHeader())
