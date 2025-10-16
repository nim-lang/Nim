discard """
  output: '''230000'''
  cmd: '''nim c --gc:orc -d:useMalloc $file'''
  valgrind: "leaks"
"""

# bug #14402

import asynchttpserver, asyncdispatch, httpclient, strutils

proc cb(req: Request) {.async, gcsafe.} =
  const html = " ".repeat(230000)
  await req.respond(Http200, html)

var server = newAsyncHttpServer()
asyncCheck server.serve(Port(0), cb)
let port = server.getPort

proc test {.async.} =
  var
    client = newAsyncHttpClient()
    resp = await client.get("http://localhost:" & $port)

  let x = (await resp.body).len
  echo x # crash

waitFor test()
