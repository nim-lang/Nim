discard """
  cmd: "nim c --threads:on $file"
"""

import asynchttpserver, httpclient, asyncdispatch, strutils, net

block: # bug #16436
  proc startServer(): AsyncHttpServer =
    result = newAsyncHttpServer()
    result.listen(Port(0))

  proc processRequest(server: AsyncHttpServer) {.async.} =
    proc cb(req: Request) {.async.} =
      let headers = { "Content-length": "15"} # Provide invalid content-length
      await req.respond(Http200, "Hello World", headers.newHttpHeaders())

    await server.acceptRequest(cb)

  proc runClient(port: Port) {.async.} =
    let c = newAsyncHttpClient(headers = {"Connection": "close"}.newHttpHeaders)
    discard await c.getContent("http://127.0.0.1:" & $port)
    doAssert false, "should fail earlier"

  let server = startServer()
  asyncCheck processRequest(server)
  let port = server.getPort()
  doAssertRaises(ProtocolError):
    waitFor runClient(port)

block: # bug #14794 (And test for presence of content-length header when using postContent)
  proc startServer(): AsyncHttpServer =
    result = newAsyncHttpServer()
    result.listen(Port(0))

  proc runServer(server: AsyncHttpServer) {.async.} =
    proc cb(req: Request) {.async.} =
      doAssert(req.body.endsWith(httpNewLine), "Multipart body does not end with a newline.")
      # this next line is probably not required because asynchttpserver does not call
      # the callback when there is no content-length header.  It instead errors with 
      # Error: unhandled exception: 411 Length Required
      # Added for good measure in case the server becomes more permissive.
      doAssert(req.headers.hasKey("content-length"), "Content-Length header is not present.")
      asyncCheck req.respond(Http200, "OK")

    await server.acceptRequest(cb)

  proc runClient(port: Port) {.async.} =
    let c = newAsyncHttpClient()
    let data = newMultipartData()
    data.add("file.txt", "This is intended to be an example text file.\r\nThis would be the second line.\r\n")
    discard await c.postContent("http://127.0.0.1:" & $port, multipart = data)
    c.close()

  let server = startServer()
  let port = server.getPort()
  asyncCheck runServer(server)
  waitFor runClient(port)
