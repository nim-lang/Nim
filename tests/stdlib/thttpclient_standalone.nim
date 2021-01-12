discard """
  cmd: "nim c --threads:on $file"
  output: "OK"
"""

import asynchttpserver, httpclient, asyncdispatch

block: # issue #16436
  proc startServer() {.async.} =
    proc cb(req: Request) {.async.} =
      let headers = { "Content-length": "15"} # Provide invalid content-length
      await req.respond(Http200, "Hello World", headers.newHttpHeaders())

    var server = newAsyncHttpServer()
    await server.serve(Port(5555), cb)

  proc runClient() {.async.} =
    let c = newAsyncHttpClient(headers = {"Connection": "close"}.newHttpHeaders)
    let r = await c.getContent("http://127.0.0.1:5555")
    echo r

  asyncCheck startServer()

  var gotException = false
  try:
    waitFor runClient()
  except ProtocolError:
    gotException = true

  doAssert(gotException)

echo "OK"
