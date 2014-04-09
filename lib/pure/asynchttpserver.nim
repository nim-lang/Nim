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

import strtabs, asyncnet, asyncdispatch, parseutils, parseurl, strutils
type
  TRequest* = object
    client: PAsyncSocket # TODO: Separate this into a Response object?
    reqMethod*: string
    headers*: PStringTable
    protocol*: tuple[orig: string, major, minor: int]
    url*: TURL
    hostname*: string ## The hostname of the client that made the request.

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

proc sendHeaders*(req: TRequest, headers: PStringTable) {.async.} =
  ## Sends the specified headers to the requesting client.
  for k, v in headers:
    await req.client.send(k & ": " & v & "\c\L")

proc respond*(req: TRequest, code: THttpCode,
        content: string, headers: PStringTable = newStringTable()) {.async.} =
  ## Responds to the request with the specified ``HttpCode``, headers and
  ## content.
  ##
  ## This procedure will **not** close the client socket.
  var customHeaders = headers
  customHeaders["Content-Length"] = $content.len
  await req.client.send("HTTP/1.1 " & $code & "\c\L")
  await sendHeaders(req, headers)
  await req.client.send("\c\L" & content)

proc newRequest(): TRequest =
  result.headers = newStringTable(modeCaseInsensitive)

proc parseHeader(line: string): tuple[key, value: string] =
  var i = 0
  i = line.parseUntil(result.key, ':')
  inc(i) # skip :
  i += line.skipWhiteSpace(i)
  i += line.parseUntil(result.value, {'\c', '\L'}, i)

proc parseProtocol(protocol: string):  tuple[orig: string, major, minor: int] =
  var i = protocol.skipIgnoreCase("HTTP/")
  if i != 5:
    raise newException(EInvalidValue, "Invalid request protocol. Got: " &
        protocol)
  result.orig = protocol
  i.inc protocol.parseInt(result.major, i)
  i.inc # Skip .
  i.inc protocol.parseInt(result.minor, i)

proc processClient(client: PAsyncSocket, address: string,
                 callback: proc (request: TRequest): PFuture[void]) {.async.} =
  # GET /path HTTP/1.1
  # Header: val
  # \n

  var request = newRequest()
  # First line - GET /path HTTP/1.1
  let line = await client.recvLine() # TODO: Timeouts.
  if line == "":
    client.close()
    return
  let lineParts = line.split(' ')
  if lineParts.len != 3:
    request.respond(Http400, "Invalid request. Got: " & line)

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
  request.url = parseUrl(path)
  try:
    request.protocol = protocol.parseProtocol()
  except EInvalidValue:
    request.respond(Http400, "Invalid request protocol. Got: " & protocol)
    return
  request.hostname = address
  request.client = client
  
  case reqMethod.normalize
  of "get":
    await callback(request)
  else:
    echo(reqMethod.repr)
    echo(line.repr)
    request.respond(Http400, "Invalid request method. Got: " & reqMethod)

  # Persistent connections
  if (request.protocol == HttpVer11 and
      request.headers["connection"].normalize != "close") or
     (request.protocol == HttpVer10 and
      request.headers["connection"].normalize == "keep-alive"):
    # In HTTP 1.1 we assume that connection is persistent. Unless connection
    # header states otherwise.
    # In HTTP 1.0 we assume that the connection should not be persistent.
    # Unless the connection header states otherwise.
    await processClient(client, address, callback)
  else:
    request.client.close()

proc serve*(server: PAsyncHttpServer, port: TPort,
            callback: proc (request: TRequest): PFuture[void],
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
    processClient(fut.client, fut.address, callback)

when isMainModule:
  var server = newAsyncHttpServer()
  proc cb(req: TRequest) {.async.} =
    #echo(req.reqMethod, " ", req.url)
    #echo(req.headers)
    await req.respond(Http200, "Hello World")

  server.serve(TPort(5555), cb)
  runForever()
