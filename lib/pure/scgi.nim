#
#
#            Nim's Runtime Library
#        (c) Copyright 2013 Andreas Rumpf, Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements helper procs for SCGI applications. Example:
##
## .. code-block:: Nim
##
##    import strtabs, sockets, scgi
##
##    var counter = 0
##    proc handleRequest(client: Socket, input: string,
##                       headers: StringTableRef): bool {.procvar.} =
##      inc(counter)
##      client.writeStatusOkTextContent()
##      client.send("Hello for the $#th time." % $counter & "\c\L")
##      return false # do not stop processing
##
##    run(handleRequest)
##
## **Warning:** The API of this module is unstable, and therefore is subject
## to change.
##
## **Warning:** This module only supports the old asynchronous interface.
## You may wish to use the `asynchttpserver <asynchttpserver.html>`_
## instead for web applications.

include "system/inclrtl"

import sockets, strutils, os, strtabs, asyncio

type
  ScgiError* = object of IOError ## the exception that is raised, if a SCGI error occurs

proc raiseScgiError*(msg: string) {.noreturn.} =
  ## raises an ScgiError exception with message `msg`.
  var e: ref ScgiError
  new(e)
  e.msg = msg
  raise e

proc parseWord(inp: string, outp: var string, start: int): int =
  result = start
  while inp[result] != '\0': inc(result)
  outp = substr(inp, start, result-1)

proc parseHeaders(s: string, L: int): StringTableRef =
  result = newStringTable()
  var i = 0
  while i < L:
    var key, val: string
    i = parseWord(s, key, i)+1
    i = parseWord(s, val, i)+1
    result[key] = val
  if s[i] == ',': inc(i)
  else: raiseScgiError("',' after netstring expected")

proc recvChar(s: Socket): char =
  var c: char
  if recv(s, addr(c), sizeof(c)) == sizeof(c):
    result = c

type
  ScgiState* = object of RootObj ## SCGI state object
    server: Socket
    bufLen: int
    client*: Socket ## the client socket to send data to
    headers*: StringTableRef ## the parsed headers
    input*: string  ## the input buffer


  # Async

  ClientMode = enum
    ClientReadChar, ClientReadHeaders, ClientReadContent

  AsyncClient = ref object
    c: AsyncSocket
    mode: ClientMode
    dataLen: int
    headers: StringTableRef ## the parsed headers
    input: string  ## the input buffer

  AsyncScgiStateObj = object
    handleRequest: proc (client: AsyncSocket,
                         input: string,
                         headers: StringTableRef) {.closure, gcsafe.}
    asyncServer: AsyncSocket
    disp: Dispatcher
  AsyncScgiState* = ref AsyncScgiStateObj

proc recvBuffer(s: var ScgiState, L: int) =
  if L > s.bufLen:
    s.bufLen = L
    s.input = newString(L)
  if L > 0 and recv(s.client, cstring(s.input), L) != L:
    raiseScgiError("could not read all data")
  setLen(s.input, L)

proc open*(s: var ScgiState, port = Port(4000), address = "127.0.0.1",
           reuseAddr = false) =
  ## opens a connection.
  s.bufLen = 4000
  s.input = newString(s.bufLen) # will be reused

  s.server = socket()
  if s.server == invalidSocket: raiseOSError(osLastError())
  new(s.client) # Initialise s.client for `next`
  if s.server == invalidSocket: raiseScgiError("could not open socket")
  #s.server.connect(connectionName, port)
  if reuseAddr:
    s.server.setSockOpt(OptReuseAddr, true)
  bindAddr(s.server, port, address)
  listen(s.server)

proc close*(s: var ScgiState) =
  ## closes the connection.
  s.server.close()

proc next*(s: var ScgiState, timeout: int = -1): bool =
  ## proceed to the first/next request. Waits ``timeout`` milliseconds for a
  ## request, if ``timeout`` is `-1` then this function will never time out.
  ## Returns `true` if a new request has been processed.
  var rsocks = @[s.server]
  if select(rsocks, timeout) == 1 and rsocks.len == 1:
    new(s.client)
    accept(s.server, s.client)
    var L = 0
    while true:
      var d = s.client.recvChar()
      if d == '\0':
        s.client.close()
        return false
      if d notin strutils.Digits:
        if d != ':': raiseScgiError("':' after length expected")
        break
      L = L * 10 + ord(d) - ord('0')
    recvBuffer(s, L+1)
    s.headers = parseHeaders(s.input, L)
    if s.headers.getOrDefault("SCGI") != "1": raiseScgiError("SCGI Version 1 expected")
    L = parseInt(s.headers.getOrDefault("CONTENT_LENGTH"))
    recvBuffer(s, L)
    return true

proc writeStatusOkTextContent*(c: Socket, contentType = "text/html") =
  ## sends the following string to the socket `c`::
  ##
  ##   Status: 200 OK\r\LContent-Type: text/html\r\L\r\L
  ##
  ## You should send this before sending your HTML page, for example.
  c.send("Status: 200 OK\r\L" &
         "Content-Type: $1\r\L\r\L" % contentType)

proc run*(handleRequest: proc (client: Socket, input: string,
                               headers: StringTableRef): bool {.nimcall,gcsafe.},
          port = Port(4000)) =
  ## encapsulates the SCGI object and main loop.
  var s: ScgiState
  s.open(port)
  var stop = false
  while not stop:
    if next(s):
      stop = handleRequest(s.client, s.input, s.headers)
      s.client.close()
  s.close()

# -- AsyncIO start

proc recvBufferAsync(client: AsyncClient, L: int): ReadLineResult =
  result = ReadPartialLine
  var data = ""
  if L < 1:
    raiseScgiError("Cannot read negative or zero length: " & $L)
  let ret = recvAsync(client.c, data, L)
  if ret == 0 and data == "":
    client.c.close()
    return ReadDisconnected
  if ret == -1:
    return ReadNone # No more data available
  client.input.add(data)
  if ret == L:
    return ReadFullLine

proc checkCloseSocket(client: AsyncClient) =
  if not client.c.isClosed:
    if client.c.isSendDataBuffered:
      client.c.setHandleWrite do (s: AsyncSocket):
        if not s.isClosed and not s.isSendDataBuffered:
          s.close()
          s.delHandleWrite()
    else: client.c.close()

proc handleClientRead(client: AsyncClient, s: AsyncScgiState) =
  case client.mode
  of ClientReadChar:
    while true:
      var d = ""
      let ret = client.c.recvAsync(d, 1)
      if d == "" and ret == 0:
        # Disconnected
        client.c.close()
        return
      if ret == -1:
        return # No more data available
      if d[0] notin strutils.Digits:
        if d[0] != ':': raiseScgiError("':' after length expected")
        break
      client.dataLen = client.dataLen * 10 + ord(d[0]) - ord('0')
    client.mode = ClientReadHeaders
    handleClientRead(client, s) # Allow progression
  of ClientReadHeaders:
    let ret = recvBufferAsync(client, (client.dataLen+1)-client.input.len)
    case ret
    of ReadFullLine:
      client.headers = parseHeaders(client.input, client.input.len-1)
      if client.headers.getOrDefault("SCGI") != "1": raiseScgiError("SCGI Version 1 expected")
      client.input = "" # For next part

      let contentLen = parseInt(client.headers.getOrDefault("CONTENT_LENGTH"))
      if contentLen > 0:
        client.mode = ClientReadContent
      else:
        s.handleRequest(client.c, client.input, client.headers)
        checkCloseSocket(client)
    of ReadPartialLine, ReadDisconnected, ReadNone: return
  of ClientReadContent:
    let L = parseInt(client.headers.getOrDefault("CONTENT_LENGTH")) -
               client.input.len
    if L > 0:
      let ret = recvBufferAsync(client, L)
      case ret
      of ReadFullLine:
        s.handleRequest(client.c, client.input, client.headers)
        checkCloseSocket(client)
      of ReadPartialLine, ReadDisconnected, ReadNone: return
    else:
      s.handleRequest(client.c, client.input, client.headers)
      checkCloseSocket(client)

proc handleAccept(sock: AsyncSocket, s: AsyncScgiState) =
  var client: AsyncSocket
  new(client)
  accept(s.asyncServer, client)
  var asyncClient = AsyncClient(c: client, mode: ClientReadChar, dataLen: 0,
                                 headers: newStringTable(), input: "")
  client.handleRead =
    proc (sock: AsyncSocket) =
      handleClientRead(asyncClient, s)
  s.disp.register(client)

proc open*(handleRequest: proc (client: AsyncSocket,
                                input: string, headers: StringTableRef) {.
                                closure, gcsafe.},
           port = Port(4000), address = "127.0.0.1",
           reuseAddr = false): AsyncScgiState =
  ## Creates an ``AsyncScgiState`` object which serves as a SCGI server.
  ##
  ## After the execution of ``handleRequest`` the client socket will be closed
  ## automatically unless it has already been closed.
  var cres: AsyncScgiState
  new(cres)
  cres.asyncServer = asyncSocket()
  cres.asyncServer.handleAccept = proc (s: AsyncSocket) = handleAccept(s, cres)
  if reuseAddr:
    cres.asyncServer.setSockOpt(OptReuseAddr, true)
  bindAddr(cres.asyncServer, port, address)
  listen(cres.asyncServer)
  cres.handleRequest = handleRequest
  result = cres

proc register*(d: Dispatcher, s: AsyncScgiState): Delegate {.discardable.} =
  ## Registers ``s`` with dispatcher ``d``.
  result = d.register(s.asyncServer)
  s.disp = d

proc close*(s: AsyncScgiState) =
  ## Closes the ``AsyncScgiState``.
  s.asyncServer.close()

when false:
  var counter = 0
  proc handleRequest(client: Socket, input: string,
                     headers: StringTableRef): bool {.procvar.} =
    inc(counter)
    client.writeStatusOkTextContent()
    client.send("Hello for the $#th time." % $counter & "\c\L")
    return false # do not stop processing

  run(handleRequest)

