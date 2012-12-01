#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
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
  
  TAsyncScgiState* = object of TScgiState
    handleRequest: proc (server: var TAsyncScgiState, client: TSocket, 
                         input: string, headers: PStringTable) {.closure.}
    asyncServer: PAsyncSocket
  PAsyncScgiState* = ref TAsyncScgiState
    
proc recvBuffer(s: var TScgiState, L: int) =
  if L > s.bufLen: 
    s.bufLen = L
    s.input = newString(L)
  if L > 0 and recv(s.client, cstring(s.input), L) != L: 
    scgiError("could not read all data")
  setLen(s.input, L)
  
proc open*(s: var TScgiState, port = TPort(4000), address = "127.0.0.1") = 
  ## opens a connection.
  s.bufLen = 4000
  s.input = newString(s.buflen) # will be reused
  
  s.server = socket()
  new(s.client) # Initialise s.client for `next`
  if s.server == InvalidSocket: scgiError("could not open socket")
  #s.server.connect(connectionName, port)
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
proc handleAccept(sock: PAsyncSocket, s: PAsyncScgiState) =
  new(s.client)
  accept(getSocket(s.asyncServer), s.client)
  var L = 0
  while true:
    var d = s.client.recvChar()
    if d == '\0':
      # Disconnected
      s.client.close()
      return
    if d notin strutils.digits: 
      if d != ':': scgiError("':' after length expected")
      break
    L = L * 10 + ord(d) - ord('0')  
  recvBuffer(s[], L+1)
  s.headers = parseHeaders(s.input, L)
  if s.headers["SCGI"] != "1": scgiError("SCGI Version 1 expected")
  L = parseInt(s.headers["CONTENT_LENGTH"])
  recvBuffer(s[], L)

  s.handleRequest(s[], s.client, s.input, s.headers)

proc open*(handleRequest: proc (server: var TAsyncScgiState, client: TSocket, 
                                input: string, headers: PStringTable) {.closure.},
           port = TPort(4000), address = "127.0.0.1"): PAsyncScgiState =
  ## Alternative of ``open`` for asyncio compatible SCGI.
  var cres: PAsyncScgiState
  new(cres)
  cres.bufLen = 4000
  cres.input = newString(cres.buflen) # will be reused

  cres.asyncServer = AsyncSocket()
  cres.asyncServer.handleAccept = proc (s: PAsyncSocket) = handleAccept(s, cres)
  bindAddr(cres.asyncServer, port, address)
  listen(cres.asyncServer)
  cres.handleRequest = handleRequest
  result = cres

proc register*(d: PDispatcher, s: PAsyncScgiState): PDelegate {.discardable.} =
  ## Registers ``s`` with dispatcher ``d``.
  result = d.register(s.asyncServer)

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

