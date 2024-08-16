discard """
  action: "compile"
"""

import std/[asynchttpserver, asyncdispatch]
import std/[strformat]

proc main() =
  let local = "123"

  proc serveIndex(req: Request) {.async, gcsafe.} =
    await req.respond(Http200, &"{local}")

  proc serve404(req: Request) {.async, gcsafe.} =
    echo req.url.path
    await req.respond(Http404, "not found")

  proc serve(req: Request) {.async, gcsafe.} =
    let handler = case req.url.path:
      of "/":
        serveIndex
      else:
        serve404
    await handler(req)

  let server = newAsyncHttpServer()
  waitFor server.serve(Port(8080), serve, address = "127.0.0.1")

when isMainModule:
  main()
