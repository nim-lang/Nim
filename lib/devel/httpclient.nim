#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2010 Dominik Picheta, Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a simple HTTP client that can be used to retrieve
## webpages/other data.

# neuer Code:
import sockets, strutils, parseurl, pegs, os, parseutils

type
  TResponse* = tuple[
    version: string, status: string, headers: seq[THeader],
    body: string]
  THeader* = tuple[htype: string, hvalue: string]

  EInvalidHttp* = object of EBase ## exception that is raised when server does
                                  ## not conform to the implemented HTTP
                                  ## protocol

  EHttpRequestErr* = object of EBase ## Thrown in the ``getContent`` proc,
                                     ## when the server returns an error

template newException(exceptn, message: expr): expr =
  block: # open a new scope
    var
      e: ref exceptn
    new(e)
    e.msg = message
    e

proc httpError(msg: string) =
  var e: ref EInvalidHttp
  new(e)
  e.msg = msg
  raise e
  
proc fileError(msg: string) =
  var e: ref EIO
  new(e)
  e.msg = msg
  raise e

proc getHeaderValue*(headers: seq[THeader], name: string): string =
  ## Retrieves a header by ``name``, from ``headers``.
  ## Returns "" if a header is not found
  for i in low(headers)..high(headers):
    if cmpIgnoreCase(headers[i].htype, name) == 0:
      return headers[i].hvalue
  return ""

proc parseBody(data: var string, start: int, s: TSocket,
               headers: seq[THeader]): string =
  if getHeaderValue(headers, "Transfer-Encoding") == "chunked":
    # get chunks:
    var i = start
    result = ""
    while true:
      var chunkSize = 0
      var j = parseHex(data, chunkSize, i)
      if j <= 0: break
      inc(i, j)
      while data[i] notin {'\C', '\L', '\0'}: inc(i)
      if data[i] == '\C': inc(i)
      if data[i] == '\L': inc(i)
      echo "ChunkSize: ", chunkSize
      if chunkSize <= 0: break
      
      var x = copy(data, i, i+chunkSize-1)
      var size = x.len
      result.add(x)
      
      if size < chunkSize:
        # read in the rest:
        var missing = chunkSize - size
        var L = result.len
        setLen(result, L + missing)
        discard s.recv(addr(result[L]), missing)
      
      # next chunk:
      data = s.recv()
      echo data
      i = 0
      
      # skip trailing CR-LF:
      while data[i] in {'\C', '\L'}: inc(i)
            
  else:
    result = copy(data, start)
    # -REGION- Content-Length
    # (http://tools.ietf.org/html/rfc2616#section-4.4) NR.3
    var contentLengthHeader = getHeaderValue(headers, "Content-Length")
    if contentLengthHeader != "":
      var length = contentLengthHeader.parseint()
      while result.len() < length: result.add(s.recv())
    else:
      # (http://tools.ietf.org/html/rfc2616#section-4.4) NR.4 TODO
      
      # -REGION- Connection: Close
      # (http://tools.ietf.org/html/rfc2616#section-4.4) NR.5
      if getHeaderValue(headers, "Connection") == "close":
        while True:
          var moreData = recv(s)
          if moreData.len == 0: break
          result.add(moreData)

proc parseResponse(s: TSocket): TResponse =
  var data = s.recv()
  var i = 0

  # Parse the version
  # Parses the first line of the headers
  # ``HTTP/1.1`` 200 OK

  var matches: array[0..1, string]
  var L = data.matchLen(peg"\i 'HTTP/' {'1.1'/'1.0'} \s+ {(!\n .)*}\n",
                        matches, i)
  if L < 0: httpError("invalid HTTP header")
  
  result.version = matches[0]
  result.status = matches[1]
  inc(i, L)
  
  # Parse the headers
  # Everything after the first line leading up to the body
  # htype: hvalue

  result.headers = @[]
  while true:
    var key = ""
    while data[i] != ':':
      if data[i] == '\0': httpError("invalid HTTP header, ':' expected")
      key.add(data[i])
      inc(i)
    inc(i) # skip ':'
    if data[i] == ' ': inc(i) # skip if the character is a space
    var val = ""
    while data[i] notin {'\C', '\L', '\0'}:
      val.add(data[i])
      inc(i)
    
    result.headers.add((key, val))
    
    if data[i] == '\C': inc(i)
    if data[i] == '\L': inc(i)
    else: httpError("invalid HTTP header, CR-LF expected")
    
    if data[i] == '\C': inc(i)
    if data[i] == '\L':
      inc(i)
      break
    
  result.body = parseBody(data, i, s, result.headers) 

proc request*(url: string): TResponse =
  var r = parse(url)
  
  var headers: string
  if r.path != "":
    headers = "GET " & r.path & " HTTP/1.1\c\L"
  else:
    headers = "GET / HTTP/1.1\c\L"
  
  add(headers, "Host: " & r.hostname & "\c\L\c\L")

  var s = socket()
  s.connect(r.hostname, TPort(80))
  s.send(headers)
  result = parseResponse(s)
  s.close()
  
proc redirection(status: string): bool =
  const redirectionNRs = ["301", "302", "303", "307"]
  for i in items(redirectionNRs):
    if status.startsWith(i):
      return True
  
proc get*(url: string, maxRedirects = 5): TResponse =
  ## low-level proc similar to ``request`` which handles redirection
  result = request(url)
  for i in 1..maxRedirects:
    if result.status.redirection():
      var locationHeader = getHeaderValue(result.headers, "Location")
      if locationHeader == "": httpError("location header expected")
      result = request(locationHeader)
      
proc getContent*(url: string): string =
  ## GET's the body and returns it as a string
  ## Raises exceptions for the status codes ``4xx`` and ``5xx``
  var r = get(url)
  if r.status[0] in {'4','5'}:
    raise newException(EHTTPRequestErr, r.status)
  else:
    return r.body
  
proc downloadFile*(url: string, outputFilename: string) =
  var f: TFile
  if open(f, outputFilename, fmWrite):
    f.write(getContent(url))
    f.close()
  else:
    fileError("Unable to open file")


when isMainModule:
  downloadFile("http://www.google.com", "GoogleTest.html")
