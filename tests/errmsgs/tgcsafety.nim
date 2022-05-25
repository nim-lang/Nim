discard """
cmd: "nim check $file"
errormsg: "type mismatch: got <AsyncHttpServer, Port, proc (req: Request): Future[system.void]{.locks: <unknown>.}>"
nimout: '''
tgcsafety.nim(31, 18) Error: type mismatch: got <AsyncHttpServer, Port, proc (req: Request): Future[system.void]{.locks: <unknown>.}>
but expected one of:
proc serve(server: AsyncHttpServer; port: Port;
           callback: proc (request: Request): Future[void] {.closure, gcsafe.};
           address = ""; assumedDescriptorsPerRequest = -1; domain = AF_INET): owned(
    Future[void])
  first type mismatch at position: 3
  required type for callback: proc (request: Request): Future[system.void]{.closure, gcsafe.}
  but expression 'cb' is of type: proc (req: Request): Future[system.void]{.locks: <unknown>.}
  This expression is not GC-safe. Annotate the proc with {.gcsafe.} to get extended error information.

expression: serve(server, Port(7898), cb)
'''
"""

# bug #6186

import asyncdispatch, asynchttpserver

var server = newAsyncHttpServer()

var foo = "foo"
proc cb(req: Request) {.async.} =
  var baa = foo & "asds"
  await req.respond(Http200, baa)

asyncCheck server.serve(Port(7898), cb )
runForever()
