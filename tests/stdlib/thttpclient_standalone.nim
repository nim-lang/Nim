discard """
  cmd: "nim c --threads:on $file"
"""

import asynchttpserver, httpclient, asyncdispatch, strutils

block: # bug #16436
  proc startServer() {.async.} =
    proc cb(req: Request) {.async.} =
      let headers = { "Content-length": "15"} # Provide invalid content-length
      await req.respond(Http200, "Hello World", headers.newHttpHeaders())

    var server = newAsyncHttpServer()
    await server.serve(Port(5555), cb)

  proc runClient() {.async.} =
    let c = newAsyncHttpClient(headers = {"Connection": "close"}.newHttpHeaders)
    let r = await c.getContent("http://127.0.0.1:5555")
    doAssert false, "should fail earlier"

  asyncCheck startServer()
  doAssertRaises(ProtocolError):
    waitFor runClient()

block: # bug #14794 (And test for presence of content-length header when using postContent)
  proc startServer() {.async.} =
    var killServer = false
    proc cb(req: Request) {.async.} =
      doAssert(req.body.endsWith(httpNewLine), "Multipart body does not end with a newline.")
      # this next line is probably not required because asynchttpserver does not call
      # the callback when there is no content-length header.  It instead errors with 
      # Error: unhandled exception: 411 Length Required
      # Added for good measure in case the server becomes more permissive.
      doAssert(req.headers.hasKey("content-length"), "Content-Length header is not present.")
      killServer = true
      asyncCheck req.respond(Http200, "OK")

    var server = newAsyncHttpServer()
    server.listen(Port(5556))
    while not killServer:
      if server.shouldAcceptRequest():
        await server.acceptRequest(cb)
      else:
        poll()

  proc runClient() {.async.} =
    let c = newAsyncHttpClient()
    var data = newMultipartData()
    data.add("file.txt", "This is intended to be an example text file.\r\nThis would be the second line.\r\n")
    let r = await c.postContent("http://127.0.0.1:5556", multipart = data)
    c.close()

  asyncCheck startServer()
  waitFor runClient()
