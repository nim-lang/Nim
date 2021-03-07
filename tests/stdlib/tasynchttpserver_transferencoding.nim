import httpclient, asynchttpserver, asyncdispatch, asyncfutures
import net

import std/asyncnet
import std/nativesockets

const postBegin = """
POST / HTTP/1.1
Transfer-Encoding:chunked

"""

template genTest(input, expected) =
  var sanity = false
  proc handler(request: Request) {.async.} =
      doAssert(request.body == expected)
      doAssert(request.headers.hasKey("Transfer-Encoding"))
      doAssert(not request.headers.hasKey("Content-Length"))
      sanity = true
      await request.respond(Http200, "Good")

  proc runSleepLoop(server: AsyncHttpServer) {.async.} = 
    server.listen(Port(0))
    proc wrapper() = 
      waitFor server.acceptRequest(handler)
    asyncdispatch.callSoon wrapper

  let server = newAsyncHttpServer()
  waitFor runSleepLoop(server)
  let port = getLocalAddr(server.getSocket.getFd, AF_INET)[1]
  let data = postBegin & input
  var socket = newSocket()
  socket.connect("127.0.0.1", port)
  socket.send(data)
  waitFor sleepAsync(10)
  socket.close()
  server.close()

  # Verify we ran the handler and its asserts
  doAssert(sanity)

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
