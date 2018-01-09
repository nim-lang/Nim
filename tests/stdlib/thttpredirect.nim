discard """
  cmd: "nim c --threads:on -d:ssl $file"
  output: '''302 Found
301 Moved Permanently
200 OK
302 Found
redirect to: http://localhost:9897/redirect/1
'''
"""

import os, strutils, cgi
import httpclient, asynchttpserver, asyncdispatch

const server_address = "http://localhost:9897"

proc test_redirect() =
  var client = newHTTPClient(maxRedirects = 1)
  let data = client.get(server_address & "/redirect/2")
  echo $data.status

proc test_redirect_1(max_r: int) =
  var client = newHTTPClient(maxRedirects = max_r)
  let data = client.get(server_address & "/redirect-to?url=http://localhost:9897/redirect-to?url=http://nim-lang.org")
  echo $data.status

proc test_redirect_deprecated() =
  let data = get(server_address & "/redirect/2", maxRedirects = 1)
  echo $data.status

proc test_redirect_download() =
  var fname = "localhost.txt"
  var client = newHTTPClient(maxRedirects = 1)
  client.downloadFile(server_address & "/redirect/3", fname)
  let fp = open(fname, fmRead)
  echo fp.readAll()
  fp.close()
  os.removeFile(fname)

proc test_redirect_download_async() {.async.} =
  var fname = "localhost.txt"
  var client = newAsyncHTTPClient(maxRedirects = 1)
  await client.downloadFile(server_address & "/redirect/2", fname)
  let fp = open(fname, fmRead)
  echo fp.readAll()
  fp.close()
  os.removeFile(fname)

proc start_server() =
  var server = newAsyncHttpServer()

  proc cb(req: Request) {.async.} =
    let (head, tail) = splitPath(req.url.path)
    if head.startsWith("/redirect"):
      if tail != "":
        var r = parseInt(tail)
        if r > 0:
          let redirectUrl = server_address & "/redirect/" & $(r - 1)
          let headers =  newHttpHeaders([("Location", redirectUrl)])
          await req.respond(Http302, "redirect to: " & redirectUrl & "\c\L", headers)
        else:
          await req.respond(Http200, "Hello World\c\L")
        return
    elif tail.startsWith("redirect-to"):
      if req.url.query != "":
        for k, v in decodeData(req.url.query):
          if k == "url":
            let headers =  newHttpHeaders([("Location", v)])
            await req.respond(Http302, "redirect to: " & v & "\c\L", headers)
            return
    await req.respond(Http404, "Not found\c\L")

  proc threadFunc(server: AsyncHttpServer) =
    asyncCheck(server.serve(Port(9897), cb))
    runForever()

  var thr: Thread[AsyncHttpServer]
  createThread[AsyncHttpServer](thr, threadFunc, server)
  # the server needs to warm up..."
  sleep(1000)

proc main() =
  start_server()

  test_redirect()
  test_redirect_1(2)
  test_redirect_1(3)
  test_redirect_deprecated()
  test_redirect_download()

  # this test fails because of
  # defer:
  #   client.getBody = true
  # in httpclient.downloadFile
  #
  # waitFor(test_redirect_download_async())

main()
