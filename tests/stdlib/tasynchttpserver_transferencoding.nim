discard """
  matrix: "--gc:arc --threads:on; --gc:arc --threads:on -d:danger; --threads:on"
  disabled: "freebsd"
"""

import httpclient, asynchttpserver, asyncdispatch, asyncfutures
import net

import std/asyncnet
import std/nativesockets

const postBegin = """
POST / HTTP/1.1
Transfer-Encoding:chunked

"""

template genTest(input, expected: string) =
  proc handler(request: Request, future: Future[bool]) {.async, gcsafe.} =
    doAssert(request.body == expected)
    doAssert(request.headers.hasKey("Transfer-Encoding"))
    doAssert(not request.headers.hasKey("Content-Length"))
    future.complete(true)
    await request.respond(Http200, "Good")

  proc sendData(data: string, port: Port) {.async.} =
    var socket = newSocket()
    defer: socket.close()

    socket.connect("127.0.0.1", port)
    socket.send(data)

  proc runTest(): Future[bool] {.async.} =
    var handlerFuture = newFuture[bool]("runTest")
    let data = postBegin & input
    let server = newAsyncHttpServer()
    server.listen(Port(0))

    proc wrapper(request: Request): Future[void] {.gcsafe, closure.} =
      handler(request, handlerFuture)
    
    asyncCheck sendData(data, server.getPort)
    asyncCheck server.acceptRequest(wrapper)
    doAssert await handlerFuture
    
    server.close()
    return true

  doAssert waitFor runTest()

block:
  const expected = "hello=world"
  const input = ("b\r\n" &
                 "hello=world\r\n" &
                 "0\r\n" &
                 "\r\n")
  genTest(input, expected)
block:
  const expected = "hello encoding"
  const input = ("e\r\n" &
                 "hello encoding\r\n" &
                 "0\r\n" &
                 "\r\n")
  genTest(input, expected)
block:
  # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Transfer-Encoding
  const expected = "MozillaDeveloperNetwork"
  const input = ("7\r\n" &
                "Mozilla\r\n" &
                "9\r\n" &
                "Developer\r\n" &
                "7\r\n" &
                "Network\r\n" &
                "0\r\n" &
                "\r\n")
  genTest(input, expected)
block:
  # https://en.wikipedia.org/wiki/Chunked_transfer_encoding#Example
  const expected = "Wikipedia in \r\n\r\nchunks."
  const input = ("4\r\n" &
                "Wiki\r\n" &
                "6\r\n" &
                "pedia \r\n" &
                "E\r\n" &
                "in \r\n" &
                "\r\n" &
                "chunks.\r\n" &
                "0\r\n" &
                "\r\n")
  genTest(input, expected)
