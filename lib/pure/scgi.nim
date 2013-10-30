#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2013 Andreas Rumpf, Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements helper procs for SCGI applications. Example:
##
## .. code-block:: Nimrod
##
##    import strtabs, sockets, scgi
##
##    var counter = 0
##    proc handleRequest(client: TSocket, input: string,
##                       headers: PStringTable): bool {.procvar.} =
##      inc(counter)
##      client.writeStatusOkTextContent()
##      client.send("Hello for the $#th time." % $counter & "\c\L")
##      return false # do not stop processing
##
##    run(handleRequest)
##
## **Warning:** The API of this module is unstable, and therefore is subject
## to change.

import sockets, strutils, os, strtabs, asyncio

type
  EScgi* = object of EIO ## the exception that is raised, if a SCGI error occurs

proc scgiError*(msg: string) {.noreturn.} =
  ## raises an EScgi exception with message `msg`.
  var e: ref EScgi
  new(e)
  e.msg = msg
  raise e

proc parseWord(inp: string, outp: var string, start: int): int =
  result = start
  while inp[result] != '\0': inc(result)
  outp = substr(inp, start, result-1)

proc parseHeaders(s: string, L: int): PStringTable =
  result = newStringTable()
  var i = 0
  while i < L:
    var key, val: string
    i = parseWord(s, key, i)+1
    i = parseWord(s, val, i)+1
    result[key] = val
  if s[i] == ',': inc(i)
  else: scgiError("',' after netstring expected")

proc recvChar(s: TSocket): char =
  var c: char
  if recv(s, addr(c), sizeof(c)) == sizeof(c):
    result = c

type
  TScgiState* = object of TObject ## SCGI state object
    server: TSocket
    bufLen: int
    client*: TSocket ## the client socket to send data to
    headers*: PStringTable ## the parsed headers
    input*: string  ## the input buffer


  # Async

  TClientMode = enum
    ClientReadChar, ClientReadHeaders, ClientReadContent

  PAsyncClient = ref object
    c: PAsyncSocket
    mode: TClientMode
    dataLen: int
    headers: PStringTable ## the parsed headers
    input: string  ## the input buffer

  TAsyncScgiState = object
    handleRequest: proc (client: PAsyncSocket,
                         input: string, headers: PStringTable) {.closure.}
    asyncServer: PAsyncSocket
    disp: PDispatcher
  PAsyncScgiState* = ref TAsyncScgiState

proc recvBuffer(s: var TScgiState, L: int) =
  if L > s.bufLen:
    s.bufLen = L
    s.input = newString(L)
  if L > 0 and recv(s.client, cstring(s.input), L) != L:
    scgiError("could not read all data")
  setLen(s.input, L)

proc open*(s: var TScgiState, port = TPort(4000), address = "127.0.0.1",
  reuseAddr = False) =
  ## opens a connection.
  s.bufLen = 4000
  s.input = newString(s.buflen) # will be reused

  s.server = socket()
  new(s.client) # Initialise s.client for `next`
  if s.server == InvalidSocket: scgiError("could not open socket")
  #s.server.connect(connectionName, port)
  if reuseAddr:
    s.server.setSockOpt(OptReuseAddr, True)
  bindAddr(s.server, port, address)
  listen(s.server)

proc close*(s: var TScgiState) =
  ## closes the connection.
  s.server.close()

proc next*(s: var TScgistate, timeout: int = -1): bool =
  ## proceed to the first/next request. Waits ``timeout`` miliseconds for a
  ## request, if ``timeout`` is `-1` then this function will never time out.
  ## Returns `True` if a new request has been processed.
  var rsocks = @[s.server]
  if select(rsocks, timeout) == 1 and rsocks.len == 0:
    new(s.client)
    accept(s.server, s.client)
    var L = 0
    while true:
      var d = s.client.recvChar()
      if d == '\0':
        s.client.close()
        return false
      if d notin strutils.digits:
        if d != ':': scgiError("':' after length expected")
        break
      L = L * 10 + ord(d) - ord('0')
    recvBuffer(s, L+1)
    s.headers = parseHeaders(s.input, L)
    if s.headers["SCGI"] != "1": scgiError("SCGI Version 1 expected")
    L = parseInt(s.headers["CONTENT_LENGTH"])
    recvBuffer(s, L)
    return True

proc writeStatusOkTextContent*(c: TSocket, contentType = "text/html") =
  ## sends the following string to the socket `c`::
  ##
  ##   Status: 200 OK\r\LContent-Type: text/html\r\L\r\L
  ##
  ## You should send this before sending your HTML page, for example.
  c.send("Status: 200 OK\r\L" &
         "Content-Type: $1\r\L\r\L" % contentType)

proc run*(handleRequest: proc (client: TSocket, input: string,
                               headers: PStringTable): bool {.nimcall.},
          port = TPort(4000)) =
  ## encapsulates the SCGI object and main loop.
  var s: TScgiState
  s.open(port)
  var stop = false
  while not stop:
    if next(s):
      stop = handleRequest(s.client, s.input, s.headers)
      s.client.close()
  s.close()

# -- AsyncIO start

proc recvBufferAsync(client: PAsyncClient, L: int): TReadLineResult =
  result = ReadPartialLine
  var data = ""
  if L < 1:
    scgiError("Cannot read negative or zero length: " & $L)
  let ret = recvAsync(client.c, data, L)
  if ret == 0 and data == "":
    client.c.close()
    return ReadDisconnected
  if ret == -1:
    return ReadNone # No more data available
  client.input.add(data)
  if ret == L:
    return ReadFullLine

proc checkCloseSocket(client: PAsyncClient) =
  if not client.c.isClosed:
    if client.c.isSendDataBuffered:
      client.c.setHandleWrite do (s: PAsyncSocket):
        if not s.isClosed and not s.isSendDataBuffered:
          s.close()
          s.delHandleWrite()
    else: client.c.close()

proc handleClientRead(client: PAsyncClient, s: PAsyncScgiState) =
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
      if d[0] notin strutils.digits:
        if d[0] != ':': scgiError("':' after length expected")
        break
      client.dataLen = client.dataLen * 10 + ord(d[0]) - ord('0')
    client.mode = ClientReadHeaders
    handleClientRead(client, s) # Allow progression
  of ClientReadHeaders:
    let ret = recvBufferAsync(client, (client.dataLen+1)-client.input.len)
    case ret
    of ReadFullLine:
      client.headers = parseHeaders(client.input, client.input.len-1)
      if client.headers["SCGI"] != "1": scgiError("SCGI Version 1 expected")
      client.input = "" # For next part

      let contentLen = parseInt(client.headers["CONTENT_LENGTH"])
      if contentLen > 0:
        client.mode = ClientReadContent
      else:
        s.handleRequest(client.c, client.input, client.headers)
        checkCloseSocket(client)
    of ReadPartialLine, ReadDisconnected, ReadNone: return
  of ClientReadContent:
    let L = parseInt(client.headers["CONTENT_LENGTH"])-client.input.len
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

proc handleAccept(sock: PAsyncSocket, s: PAsyncScgiState) =
  var client: PAsyncSocket
  new(client)
  accept(s.asyncServer, client)
  var asyncClient = PAsyncClient(c: client, mode: ClientReadChar, dataLen: 0,
                                 headers: newStringTable(), input: "")
  client.handleRead =
    proc (sock: PAsyncSocket) =
      handleClientRead(asyncClient, s)
  s.disp.register(client)

proc open*(handleRequest: proc (client: PAsyncSocket,
                                input: string, headers: PStringTable) {.closure.},
           port = TPort(4000), address = "127.0.0.1",
           reuseAddr = false): PAsyncScgiState =
  ## Creates an ``PAsyncScgiState`` object which serves as a SCGI server.
  ##
  ## After the execution of ``handleRequest`` the client socket will be closed
  ## automatically unless it has already been closed.
  var cres: PAsyncScgiState
  new(cres)
  cres.asyncServer = AsyncSocket()
  cres.asyncServer.handleAccept = proc (s: PAsyncSocket) = handleAccept(s, cres)
  if reuseAddr:
    cres.asyncServer.setSockOpt(OptReuseAddr, True)
  bindAddr(cres.asyncServer, port, address)
  listen(cres.asyncServer)
  cres.handleRequest = handleRequest
  result = cres

proc register*(d: PDispatcher, s: PAsyncScgiState): PDelegate {.discardable.} =
  ## Registers ``s`` with dispatcher ``d``.
  result = d.register(s.asyncServer)
  s.disp = d

proc close*(s: PAsyncScgiState) =
  ## Closes the ``PAsyncScgiState``.
  s.asyncServer.close()

when false:
  var counter = 0
  proc handleRequest(client: TSocket, input: string,
                     headers: PStringTable): bool {.procvar.} =
    inc(counter)
    client.writeStatusOkTextContent()
    client.send("Hello for the $#th time." % $counter & "\c\L")
    return false # do not stop processing

  run(handleRequest)

