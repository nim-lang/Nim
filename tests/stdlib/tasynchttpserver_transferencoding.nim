import httpclient, asynchttpserver, asyncdispatch, asyncfutures
import net

import std/nativesockets
import std/threadpool

template genTest(input, expected: string) =
  var sanity = false
  proc my_handler(request: Request) {.async.} =
      doAssert(request.body == expected)
      doAssert(request.headers.hasKey("Transfer-Encoding"))
      # TODO: This assert depends on client-side code, not server-side code
      # Currently, the Nim Http Client does not support Transfer-Encoding-style
      # requests
      # doAssert(not request.headers.hasKey("Content-Length"))
      sanity = true
      await request.respond(Http200, "Good")

  proc send_request(server: AsyncHttpServer): Future[AsyncResponse] {.async.} =
    let client = newAsyncHttpClient()
    let headers = newHttpHeaders({"Transfer-Encoding": "chunked"})
    let  clientResponse = await client.request("http://localhost:64123/", body=input, headers=headers, httpMethod=HttpPost)
    server.close()
    return clientResponse

  proc run_server(): void =
    let server = newAsyncHttpServer()
    discard server.serve(Port(64123), my_handler)
    discard waitFor server.send_request

  spawn run_server()
  sync()
  doAssert sanity

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
