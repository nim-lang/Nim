import strutils, os, osproc, strtabs, streams, sockets

const
  wwwNL* = "\r\L"
  ServerSig = "Server: httpserver.nim/1.0.0" & wwwNL

type
  TRequestMethod = enum reqGet, reqPost
  TServer* = object       ## contains the current server state
    s: Socket
    job: seq[TJob]
  TJob* = object
    client: Socket
    process: Process

# --------------- output messages --------------------------------------------

proc sendTextContentType(client: Socket) =
  send(client, "Content-type: text/html" & wwwNL)
  send(client, wwwNL)

proc badRequest(client: Socket) =
  # Inform the client that a request it has made has a problem.
  send(client, "HTTP/1.0 400 BAD REQUEST" & wwwNL)
  sendTextContentType(client)
  send(client, "<p>Your browser sent a bad request, " &
               "such as a POST without a Content-Length.</p>" & wwwNL)


proc cannotExec(client: Socket) =
  send(client, "HTTP/1.0 500 Internal Server Error" & wwwNL)
  sendTextContentType(client)
  send(client, "<P>Error prohibited CGI execution.</p>" & wwwNL)


proc headers(client: Socket, filename: string) =
  # XXX could use filename to determine file type
  send(client, "HTTP/1.0 200 OK" & wwwNL)
  send(client, ServerSig)
  sendTextContentType(client)

proc notFound(client: Socket, path: string) =
  send(client, "HTTP/1.0 404 NOT FOUND" & wwwNL)
  send(client, ServerSig)
  sendTextContentType(client)
  send(client, "<html><title>Not Found</title>" & wwwNL)
  send(client, "<body><p>The server could not fulfill" & wwwNL)
  send(client, "your request because the resource <b>" & path & "</b>" & wwwNL)
  send(client, "is unavailable or nonexistent.</p>" & wwwNL)
  send(client, "</body></html>" & wwwNL)


proc unimplemented(client: Socket) =
  send(client, "HTTP/1.0 501 Method Not Implemented" & wwwNL)
  send(client, ServerSig)
  sendTextContentType(client)
  send(client, "<html><head><title>Method Not Implemented" &
               "</title></head>" &
               "<body><p>HTTP request method not supported.</p>" &
               "</body></HTML>" & wwwNL)


# ----------------- file serving ---------------------------------------------

proc discardHeaders(client: Socket) = skip(client)

proc serveFile(client: Socket, filename: string) =
  discardHeaders(client)

  var f: File
  if open(f, filename):
    headers(client, filename)
    const bufSize = 8000 # != 8K might be good for memory manager
    var buf = alloc(bufsize)
    while true:
      var bytesread = readBuffer(f, buf, bufsize)
      if bytesread > 0:
        var byteswritten = send(client, buf, bytesread)
        if bytesread != bytesWritten:
          let err = osLastError()
          dealloc(buf)
          close(f)
          raiseOSError(err)
      if bytesread != bufSize: break
    dealloc(buf)
    close(f)
    client.close()
  else:
    notFound(client, filename)

# ------------------ CGI execution -------------------------------------------

proc executeCgi(server: var TServer, client: Socket, path, query: string,
                meth: TRequestMethod) =
  var env = newStringTable(modeCaseInsensitive)
  var contentLength = -1
  case meth
  of reqGet:
    discardHeaders(client)

    env["REQUEST_METHOD"] = "GET"
    env["QUERY_STRING"] = query
  of reqPost:
    var buf = ""
    var dataAvail = true
    while dataAvail:
      dataAvail = recvLine(client, buf)
      if buf.len == 0:
        break
      var L = toLowerAscii(buf)
      if L.startsWith("content-length:"):
        var i = len("content-length:")
        while L[i] in Whitespace: inc(i)
        contentLength = parseInt(substr(L, i))

    if contentLength < 0:
      badRequest(client)
      return

    env["REQUEST_METHOD"] = "POST"
    env["CONTENT_LENGTH"] = $contentLength

  send(client, "HTTP/1.0 200 OK" & wwwNL)

  var process = startProcess(command=path, env=env)

  var job: TJob
  job.process = process
  job.client = client
  server.job.add(job)

  if meth == reqPost:
    # get from client and post to CGI program:
    var buf = alloc(contentLength)
    if recv(client, buf, contentLength) != contentLength:
      let err = osLastError()
      dealloc(buf)
      raiseOSError(err)
    var inp = process.inputStream
    inp.writeData(buf, contentLength)
    dealloc(buf)

proc animate(server: var TServer) =
  # checks list of jobs, removes finished ones (pretty sloppy by seq copying)
  var active_jobs: seq[TJob] = @[]
  for i in 0..server.job.len-1:
    var job = server.job[i]
    if running(job.process):
      active_jobs.add(job)
    else:
      # read process output stream and send it to client
      var outp = job.process.outputStream
      while true:
        var line = outp.readstr(1024)
        if line.len == 0:
          break
        else:
          try:
            send(job.client, line)
          except:
            echo("send failed, client diconnected")
      close(job.client)

  server.job = active_jobs

# --------------- Server Setup -----------------------------------------------

proc acceptRequest(server: var TServer, client: Socket) =
  var cgi = false
  var query = ""
  var buf = ""
  discard recvLine(client, buf)
  var path = ""
  var data = buf.split()
  var meth = reqGet
  var q = find(data[1], '?')

  # extract path
  if q >= 0:
    # strip "?..." from path, this may be found in both POST and GET
    path = data[1].substr(0, q-1)
  else:
    path = data[1]
  # path starts with "/", by adding "." in front of it we serve files from cwd
  path = "." & path

  echo("accept: " & path)

  if cmpIgnoreCase(data[0], "GET") == 0:
    if q >= 0:
      cgi = true
      query = data[1].substr(q+1)
  elif cmpIgnoreCase(data[0], "POST") == 0:
    cgi = true
    meth = reqPost
  else:
    unimplemented(client)

  if path[path.len-1] == '/' or existsDir(path):
    path = path / "index.html"

  if not existsFile(path):
    discardHeaders(client)
    notFound(client, path)
    client.close()
  else:
    when defined(Windows):
      var ext = splitFile(path).ext.toLowerAscii
      if ext == ".exe" or ext == ".cgi":
        # XXX: extract interpreter information here?
        cgi = true
    else:
      if {fpUserExec, fpGroupExec, fpOthersExec} * path.getFilePermissions != {}:
        cgi = true
    if not cgi:
      serveFile(client, path)
    else:
      executeCgi(server, client, path, query, meth)

when isMainModule:
  var port = 80

  var server: TServer
  server.job = @[]
  server.s = socket(AF_INET)
  if server.s == invalidSocket: raiseOSError(osLastError())
  server.s.bindAddr(port=Port(port))
  listen(server.s)
  echo("server up on port " & $port)

  while true:
    # check for new new connection & handle it
    var list: seq[Socket] = @[server.s]
    if select(list, 10) > 0:
      var client: Socket
      new(client)
      accept(server.s, client)
      try:
        acceptRequest(server, client)
      except:
        echo("failed to accept client request")

    # pooling events
    animate(server)
    # some slack for CPU
    sleep(10)
  server.s.close()
