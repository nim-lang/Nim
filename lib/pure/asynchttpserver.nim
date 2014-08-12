#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2014 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a high performance asynchronous HTTP server.
##
## **Note:** This module is still largely experimental.

import strtabs, asyncnet, asyncdispatch, parseutils, uri, strutils
type
  TRequest* = object
    client*: PAsyncSocket # TODO: Separate this into a Response object?
    reqMethod*: string
    headers*: PStringTable
    protocol*: tuple[orig: string, major, minor: int]
    url*: TUri
    hostname*: string ## The hostname of the client that made the request.
    body*: string

  PAsyncHttpServer* = ref object
    socket: PAsyncSocket

  THttpCode* = enum
    Http200 = "200 OK",
    Http303 = "303 Moved",
    Http400 = "400 Bad Request",
    Http404 = "404 Not Found",
    Http500 = "500 Internal Server Error",
    Http502 = "502 Bad Gateway"

  THttpVersion* = enum
    HttpVer11,
    HttpVer10

proc `==`*(protocol: tuple[orig: string, major, minor: int],
           ver: THttpVersion): bool =
  let major =
    case ver
    of HttpVer11, HttpVer10: 1
  let minor =
    case ver
    of HttpVer11: 1
    of HttpVer10: 0
  result = protocol.major == major and protocol.minor == minor

proc newAsyncHttpServer*(): PAsyncHttpServer =
  new result

proc addHeaders(msg: var string, headers: PStringTable) =
  for k, v in headers:
    msg.add(k & ": " & v & "\c\L")

proc sendHeaders*(req: TRequest, headers: PStringTable): PFuture[void] =
  ## Sends the specified headers to the requesting client.
  var msg = ""
  addHeaders(msg, headers)
  return req.client.send(msg)

proc respond*(req: TRequest, code: THttpCode,
        content: string, headers: PStringTable = newStringTable()) {.async.} =
  ## Responds to the request with the specified ``HttpCode``, headers and
  ## content.
  ##
  ## This procedure will **not** close the client socket.
  var customHeaders = headers
  customHeaders["Content-Length"] = $content.len
  var msg = "HTTP/1.1 " & $code & "\c\L"
  msg.addHeaders(customHeaders)
  await req.client.send(msg & "\c\L" & content)

proc newRequest(): TRequest =
  result.headers = newStringTable(modeCaseInsensitive)

proc parseHeader(line: string): tuple[key, value: string] =
  var i = 0
  i = line.parseUntil(result.key, ':')
  inc(i) # skip :
  i += line.skipWhiteSpace(i)
  i += line.parseUntil(result.value, {'\c', '\L'}, i)

proc parseProtocol(protocol: string): tuple[orig: string, major, minor: int] =
  var i = protocol.skipIgnoreCase("HTTP/")
  if i != 5:
    raise newException(EInvalidValue, "Invalid request protocol. Got: " &
        protocol)
  result.orig = protocol
  i.inc protocol.parseInt(result.major, i)
  i.inc # Skip .
  i.inc protocol.parseInt(result.minor, i)

proc sendStatus(client: PAsyncSocket, status: string): PFuture[void] =
  client.send("HTTP/1.1 " & status & "\c\L")

proc processClient(client: PAsyncSocket, address: string,
                 callback: proc (request: TRequest): PFuture[void]) {.async.} =
  while true:
    # GET /path HTTP/1.1
    # Header: val
    # \n
    var request = newRequest()
    request.hostname = address
    assert client != nil
    request.client = client

    # First line - GET /path HTTP/1.1
    let line = await client.recvLine() # TODO: Timeouts.
    if line == "":
      client.close()
      return
    let lineParts = line.split(' ')
    if lineParts.len != 3:
      await request.respond(Http400, "Invalid request. Got: " & line)
      continue

    let reqMethod = lineParts[0]
    let path = lineParts[1]
    let protocol = lineParts[2]

    # Headers
    var i = 0
    while true:
      i = 0
      let headerLine = await client.recvLine()
      if headerLine == "":
        client.close(); return
      if headerLine == "\c\L": break
      # TODO: Compiler crash
      #let (key, value) = parseHeader(headerLine)
      let kv = parseHeader(headerLine)
      request.headers[kv.key] = kv.value

    request.reqMethod = reqMethod
    request.url = parseUri(path)
    try:
      request.protocol = protocol.parseProtocol()
    except EInvalidValue:
      asyncCheck request.respond(Http400, "Invalid request protocol. Got: " &
          protocol)
      continue

    if reqMethod.normalize == "post":
      # Check for Expect header
      if request.headers.hasKey("Expect"):
        if request.headers["Expect"].toLower == "100-continue":
          await client.sendStatus("100 Continue")
        else:
          await client.sendStatus("417 Expectation Failed")
    
      # Read the body
      # - Check for Content-length header
      if request.headers.hasKey("Content-Length"):
        var contentLength = 0
        if parseInt(request.headers["Content-Length"], contentLength) == 0:
          await request.respond(Http400, "Bad Request. Invalid Content-Length.")
        else:
          request.body = await client.recv(contentLength)
          assert request.body.len == contentLength
      else:
        await request.respond(Http400, "Bad Request. No Content-Length.")
        continue

    case reqMethod.normalize
    of "get", "post", "head", "put", "delete", "trace", "options", "connect", "patch":
      await callback(request)
    else:
      await request.respond(Http400, "Invalid request method. Got: " & reqMethod)

    # Persistent connections
    if (request.protocol == HttpVer11 and
        request.headers["connection"].normalize != "close") or
       (request.protocol == HttpVer10 and
        request.headers["connection"].normalize == "keep-alive"):
      # In HTTP 1.1 we assume that connection is persistent. Unless connection
      # header states otherwise.
      # In HTTP 1.0 we assume that the connection should not be persistent.
      # Unless the connection header states otherwise.
    else:
      request.client.close()
      break

proc serve*(server: PAsyncHttpServer, port: TPort,
            callback: proc (request: TRequest): PFuture[void] {.gcsafe.},
            address = "") {.async.} =
  ## Starts the process of listening for incoming HTTP connections on the
  ## specified address and port.
  ##
  ## When a request is made by a client the specified callback will be called.
  server.socket = newAsyncSocket()
  server.socket.bindAddr(port, address)
  server.socket.listen()
  
  while true:
    # TODO: Causes compiler crash.
    #var (address, client) = await server.socket.acceptAddr()
    var fut = await server.socket.acceptAddr()
    asyncCheck processClient(fut.client, fut.address, callback)
    #echo(f.isNil)
    #echo(f.repr)

proc close*(server: PAsyncHttpServer) =
  ## Terminates the async http server instance.
  server.socket.close()

when isMainModule:
  proc main =
    var server = newAsyncHttpServer()
    proc cb(req: TRequest) {.async.} =
      #echo(req.reqMethod, " ", req.url)
      #echo(req.headers)
      let headers = {"Date": "Tue, 29 Apr 2014 23:40:08 GMT",
          "Content-type": "text/plain; charset=utf-8"}
      await req.respond(Http200, "Hello World", headers.newStringTable())

    asyncCheck server.serve(TPort(5555), cb)
    runForever()
  main()
