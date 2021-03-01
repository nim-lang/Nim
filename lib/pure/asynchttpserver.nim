#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a high performance asynchronous HTTP server.
##
## This HTTP server has not been designed to be used in production, but
## for testing applications locally. Because of this, when deploying your
## application in production you should use a reverse proxy (for example nginx)
## instead of allowing users to connect directly to this server.

runnableExamples:
  # This example will create an HTTP server on port 8080. The server will
  # respond to all requests with a `200 OK` response code and "Hello World"
  # as the response body. Run locally with:
  # `nim doc --doccmd:-d:nimAsyncHttpServerEnableTest --lib:lib lib/pure/asynchttpserver.nim`
  import std/asyncdispatch
  if defined(nimAsyncHttpServerEnableTest):
    proc main {.async.} =
      const port = 8080
      var server = newAsyncHttpServer()
      proc cb(req: Request) {.async.} =
        echo (req.reqMethod, req.url, req.headers)
        let headers = {"Content-type": "text/plain; charset=utf-8"}
        await req.respond(Http200, "Hello World", headers.newHttpHeaders())

      echo "test this with: curl localhost:" & $port & "/"
      server.listen(Port(port))
      while true:
        if server.shouldAcceptRequest():
          await server.acceptRequest(cb)
        else:
          # too many concurrent connections, `maxFDs` exceeded
          # wait 500ms for FDs to be closed
          await sleepAsync(500)

    waitFor main()

import asyncnet, asyncdispatch, parseutils, uri, strutils
import httpcore
import std/private/since

export httpcore except parseHeader

const
  maxLine = 8*1024

# TODO: If it turns out that the decisions that asynchttpserver makes
# explicitly, about whether to close the client sockets or upgrade them are
# wrong, then add a return value which determines what to do for the callback.
# Also, maybe move `client` out of `Request` object and into the args for
# the proc.
type
  Request* = object
    client*: AsyncSocket # TODO: Separate this into a Response object?
    reqMethod*: HttpMethod
    headers*: HttpHeaders
    protocol*: tuple[orig: string, major, minor: int]
    url*: Uri
    hostname*: string    ## The hostname of the client that made the request.
    body*: string

  AsyncHttpServer* = ref object
    socket: AsyncSocket
    reuseAddr: bool
    reusePort: bool
    maxBody: int ## The maximum content-length that will be read for the body.
    maxFDs: int

func getSocket*(a: AsyncHttpServer): AsyncSocket {.since: (1, 5, 1).} =
  ## Returns the `AsyncHttpServer`s internal `AsyncSocket` instance.
  ## 
  ## Useful for identifying what port the AsyncHttpServer is bound to, if it
  ## was chosen automatically.
  runnableExamples:
    from std/asyncdispatch import Port
    from std/asyncnet import getFd
    from std/nativesockets import getLocalAddr, AF_INET
    let server = newAsyncHttpServer()
    server.listen(Port(0)) # Socket is not bound until this point
    let port = getLocalAddr(server.getSocket.getFd, AF_INET)[1]
    doAssert uint16(port) > 0
    server.close()
  a.socket

proc newAsyncHttpServer*(reuseAddr = true, reusePort = false,
                         maxBody = 8388608): AsyncHttpServer =
  ## Creates a new `AsyncHttpServer` instance.
  result = AsyncHttpServer(reuseAddr: reuseAddr, reusePort: reusePort, maxBody: maxBody)

proc addHeaders(msg: var string, headers: HttpHeaders) =
  for k, v in headers:
    msg.add(k & ": " & v & "\c\L")

proc sendHeaders*(req: Request, headers: HttpHeaders): Future[void] =
  ## Sends the specified headers to the requesting client.
  var msg = ""
  addHeaders(msg, headers)
  return req.client.send(msg)

proc respond*(req: Request, code: HttpCode, content: string,
              headers: HttpHeaders = nil): Future[void] =
  ## Responds to the request with the specified `HttpCode`, headers and
  ## content.
  ##
  ## This procedure will **not** close the client socket.
  ##
  ## Example:
  ##
  ## .. code-block::nim
  ##    import std/json
  ##    proc handler(req: Request) {.async.} =
  ##      if req.url.path == "/hello-world":
  ##        let msg = %* {"message": "Hello World"}
  ##        let headers = newHttpHeaders([("Content-Type","application/json")])
  ##        await req.respond(Http200, $msg, headers)
  ##      else:
  ##        await req.respond(Http404, "Not Found")
  var msg = "HTTP/1.1 " & $code & "\c\L"

  if headers != nil:
    msg.addHeaders(headers)

  # If the headers did not contain a Content-Length use our own
  if headers.isNil() or not headers.hasKey("Content-Length"):
    msg.add("Content-Length: ")
    # this particular way saves allocations:
    msg.addInt content.len
    msg.add "\c\L"

  msg.add "\c\L"
  msg.add(content)
  result = req.client.send(msg)

proc respondError(req: Request, code: HttpCode): Future[void] =
  ## Responds to the request with the specified `HttpCode`.
  let content = $code
  var msg = "HTTP/1.1 " & content & "\c\L"

  msg.add("Content-Length: " & $content.len & "\c\L\c\L")
  msg.add(content)
  result = req.client.send(msg)

proc parseProtocol(protocol: string): tuple[orig: string, major, minor: int] =
  var i = protocol.skipIgnoreCase("HTTP/")
  if i != 5:
    raise newException(ValueError, "Invalid request protocol. Got: " &
        protocol)
  result.orig = protocol
  i.inc protocol.parseSaturatedNatural(result.major, i)
  i.inc # Skip .
  i.inc protocol.parseSaturatedNatural(result.minor, i)

proc sendStatus(client: AsyncSocket, status: string): Future[void] =
  client.send("HTTP/1.1 " & status & "\c\L\c\L")

func hasChunkedEncoding(request: Request): bool = 
  ## Searches for a chunked transfer encoding
  const transferEncoding = "Transfer-Encoding"

  if request.headers.hasKey(transferEncoding):
    for encoding in seq[string](request.headers[transferEncoding]):
      if "chunked" == encoding.strip:
        # Returns true if it is both an HttpPost and has chunked encoding
        return request.reqMethod == HttpPost
  return false

proc processRequest(
  server: AsyncHttpServer,
  req: FutureVar[Request],
  client: AsyncSocket,
  address: string,
  lineFut: FutureVar[string],
  callback: proc (request: Request): Future[void] {.closure, gcsafe.},
): Future[bool] {.async.} =

  # Alias `request` to `req.mget()` so we don't have to write `mget` everywhere.
  template request(): Request =
    req.mget()

  # GET /path HTTP/1.1
  # Header: val
  # \n
  request.headers.clear()
  request.body = ""
  request.hostname.shallowCopy(address)
  assert client != nil
  request.client = client

  # We should skip at least one empty line before the request
  # https://tools.ietf.org/html/rfc7230#section-3.5
  for i in 0..1:
    lineFut.mget().setLen(0)
    lineFut.clean()
    await client.recvLineInto(lineFut, maxLength = maxLine) # TODO: Timeouts.

    if lineFut.mget == "":
      client.close()
      return false

    if lineFut.mget.len > maxLine:
      await request.respondError(Http413)
      client.close()
      return false
    if lineFut.mget != "\c\L":
      break

  # First line - GET /path HTTP/1.1
  var i = 0
  for linePart in lineFut.mget.split(' '):
    case i
    of 0:
      case linePart
      of "GET": request.reqMethod = HttpGet
      of "POST": request.reqMethod = HttpPost
      of "HEAD": request.reqMethod = HttpHead
      of "PUT": request.reqMethod = HttpPut
      of "DELETE": request.reqMethod = HttpDelete
      of "PATCH": request.reqMethod = HttpPatch
      of "OPTIONS": request.reqMethod = HttpOptions
      of "CONNECT": request.reqMethod = HttpConnect
      of "TRACE": request.reqMethod = HttpTrace
      else:
        asyncCheck request.respondError(Http400)
        return true # Retry processing of request
    of 1:
      try:
        parseUri(linePart, request.url)
      except ValueError:
        asyncCheck request.respondError(Http400)
        return true
    of 2:
      try:
        request.protocol = parseProtocol(linePart)
      except ValueError:
        asyncCheck request.respondError(Http400)
        return true
    else:
      await request.respondError(Http400)
      return true
    inc i

  # Headers
  while true:
    i = 0
    lineFut.mget.setLen(0)
    lineFut.clean()
    await client.recvLineInto(lineFut, maxLength = maxLine)

    if lineFut.mget == "":
      client.close(); return false
    if lineFut.mget.len > maxLine:
      await request.respondError(Http413)
      client.close(); return false
    if lineFut.mget == "\c\L": break
    let (key, value) = parseHeader(lineFut.mget)
    request.headers[key] = value
    # Ensure the client isn't trying to DoS us.
    if request.headers.len > headerLimit:
      await client.sendStatus("400 Bad Request")
      request.client.close()
      return false

  if request.reqMethod == HttpPost:
    # Check for Expect header
    if request.headers.hasKey("Expect"):
      if "100-continue" in request.headers["Expect"]:
        await client.sendStatus("100 Continue")
      else:
        await client.sendStatus("417 Expectation Failed")

  # Read the body
  # - Check for Content-length header
  if request.headers.hasKey("Content-Length"):
    var contentLength = 0
    if parseSaturatedNatural(request.headers["Content-Length"], contentLength) == 0:
      await request.respond(Http400, "Bad Request. Invalid Content-Length.")
      return true
    else:
      if contentLength > server.maxBody:
        await request.respondError(Http413)
        return false
      request.body = await client.recv(contentLength)
      if request.body.len != contentLength:
        await request.respond(Http400, "Bad Request. Content-Length does not match actual.")
        return true
  elif hasChunkedEncoding(request):
    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Transfer-Encoding
    var sizeOrData = 0
    var bytesToRead = 0
    request.body = ""

    while true:
      lineFut.mget.setLen(0)
      lineFut.clean()
      
      # The encoding format alternates between specifying a number of bytes to read
      # and the data to be read, of the previously specified size
      if sizeOrData mod 2 == 0:
        # Expect a number of chars to read
        await client.recvLineInto(lineFut, maxLength = maxLine)
        try:
          bytesToRead = lineFut.mget.parseHexInt
        except ValueError:
          # Malformed request
          await request.respond(Http411, ("Invalid chunked transfer encoding - " &
                                          "chunk data size must be hex encoded"))
          return true
      else:
        if bytesToRead == 0:
          # Done reading chunked data
          break

        # Read bytesToRead and add to body
        let chunk = await client.recv(bytesToRead)
        request.body.add(chunk)
        # Skip \r\n (chunk terminating bytes per spec)
        let separator = await client.recv(2)
        if separator != "\r\n":
          await request.respond(Http400, "Bad Request. Encoding separator must be \\r\\n")
          return true

      inc sizeOrData
  elif request.reqMethod == HttpPost:
    await request.respond(Http411, "Content-Length required.")
    return true

  # Call the user's callback.
  await callback(request)

  if "upgrade" in request.headers.getOrDefault("connection"):
    return false

  # The request has been served, from this point on returning `true` means the
  # connection will not be closed and will be kept in the connection pool.

  # Persistent connections
  if (request.protocol == HttpVer11 and
      cmpIgnoreCase(request.headers.getOrDefault("connection"), "close") != 0) or
     (request.protocol == HttpVer10 and
      cmpIgnoreCase(request.headers.getOrDefault("connection"), "keep-alive") == 0):
    # In HTTP 1.1 we assume that connection is persistent. Unless connection
    # header states otherwise.
    # In HTTP 1.0 we assume that the connection should not be persistent.
    # Unless the connection header states otherwise.
    return true
  else:
    request.client.close()
    return false

proc processClient(server: AsyncHttpServer, client: AsyncSocket, address: string,
                   callback: proc (request: Request):
                      Future[void] {.closure, gcsafe.}) {.async.} =
  var request = newFutureVar[Request]("asynchttpserver.processClient")
  request.mget().url = initUri()
  request.mget().headers = newHttpHeaders()
  var lineFut = newFutureVar[string]("asynchttpserver.processClient")
  lineFut.mget() = newStringOfCap(80)

  while not client.isClosed:
    let retry = await processRequest(
      server, request, client, address, lineFut, callback
    )
    if not retry: break

const
  nimMaxDescriptorsFallback* {.intdefine.} = 16_000 ## fallback value for \
    ## when `maxDescriptors` is not available.
    ## This can be set on the command line during compilation
    ## via `-d:nimMaxDescriptorsFallback=N`

proc listen*(server: AsyncHttpServer; port: Port; address = "") =
  ## Listen to the given port and address.
  when declared(maxDescriptors):
    server.maxFDs = try: maxDescriptors() except: nimMaxDescriptorsFallback
  else:
    server.maxFDs = nimMaxDescriptorsFallback
  server.socket = newAsyncSocket()
  if server.reuseAddr:
    server.socket.setSockOpt(OptReuseAddr, true)
  if server.reusePort:
    server.socket.setSockOpt(OptReusePort, true)
  server.socket.bindAddr(port, address)
  server.socket.listen()

proc shouldAcceptRequest*(server: AsyncHttpServer;
                          assumedDescriptorsPerRequest = 5): bool {.inline.} =
  ## Returns true if the process's current number of opened file
  ## descriptors is still within the maximum limit and so it's reasonable to
  ## accept yet another request.
  result = assumedDescriptorsPerRequest < 0 or
    (activeDescriptors() + assumedDescriptorsPerRequest < server.maxFDs)

proc acceptRequest*(server: AsyncHttpServer,
            callback: proc (request: Request): Future[void] {.closure, gcsafe.}) {.async.} =
  ## Accepts a single request. Write an explicit loop around this proc so that
  ## errors can be handled properly.
  var (address, client) = await server.socket.acceptAddr()
  asyncCheck processClient(server, client, address, callback)

proc serve*(server: AsyncHttpServer, port: Port,
            callback: proc (request: Request): Future[void] {.closure, gcsafe.},
            address = "";
            assumedDescriptorsPerRequest = -1) {.async.} =
  ## Starts the process of listening for incoming HTTP connections on the
  ## specified address and port.
  ##
  ## When a request is made by a client the specified callback will be called.
  ##
  ## If `assumedDescriptorsPerRequest` is 0 or greater the server cares about
  ## the process's maximum file descriptor limit. It then ensures that the
  ## process still has the resources for `assumedDescriptorsPerRequest`
  ## file descriptors before accepting a connection.
  ##
  ## You should prefer to call `acceptRequest` instead with a custom server
  ## loop so that you're in control over the error handling and logging.
  listen server, port, address
  while true:
    if shouldAcceptRequest(server, assumedDescriptorsPerRequest):
      var (address, client) = await server.socket.acceptAddr()
      asyncCheck processClient(server, client, address, callback)
    else:
      poll()
    #echo(f.isNil)
    #echo(f.repr)

proc close*(server: AsyncHttpServer) =
  ## Terminates the async http server instance.
  server.socket.close()
