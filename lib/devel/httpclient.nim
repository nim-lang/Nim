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
import sockets, strutils, parseurl, pegs, parseutils

type
  TResponse* = tuple[
    version: string, status: string, headers: seq[THeader],
    body: string]
  THeader* = tuple[htype, hvalue: string]

  EInvalidProtocol* = object of EBase ## exception that is raised when server
                                      ## does not conform to the implemented
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
  var e: ref EInvalidProtocol
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

proc charAt(d: var string, i: var int, s: TSocket): char {.inline.} = 
  result = d[i]
  while result == '\0':
    d = s.recv()
    i = 0
    result = d[i]

proc parseChunks(d: var string, start: int, s: TSocket): string =
  # get chunks:
  var i = start
  result = ""
  while true:
    var chunkSize = 0
    var digitFound = false
    echo "number: ", copy(d, i, i + 10)
    while true: 
      case d[i]
      of '0'..'9': 
        digitFound = true
        chunkSize = chunkSize shl 4 or (ord(d[i]) - ord('0'))
      of 'a'..'f': 
        digitFound = true
        chunkSize = chunkSize shl 4 or (ord(d[i]) - ord('a') + 10)
      of 'A'..'F': 
        digitFound = true
        chunkSize = chunkSize shl 4 or (ord(d[i]) - ord('A') + 10)
      of '\0': 
        d = s.recv()
        i = -1
      else: break
      inc(i)
    
    echo "chunksize: ", chunkSize
    if chunkSize <= 0:       
      echo copy(d, i)
      assert digitFound
      break
    while charAt(d, i, s) notin {'\C', '\L', '\0'}: inc(i)
    if charAt(d, i, s) == '\C': inc(i)
    if charAt(d, i, s) == '\L': inc(i)
    else: httpError("CR-LF after chunksize expected")
    
    var x = copy(d, i, i+chunkSize-1)
    var size = x.len
    result.add(x)
    
    if size < chunkSize:
      # read in the rest:
      var missing = chunkSize - size
      var L = result.len
      setLen(result, L + missing)
      while missing > 0:
        var bytesRead = s.recv(addr(result[L]), missing)
        inc(L, bytesRead)
        dec(missing, bytesRead)
    
    # next chunk:
    d = s.recv()
    i = 0
    # skip trailing CR-LF:
    while charAt(d, i, s) in {'\C', '\L'}: inc(i)
  
proc parseBody(d: var string, start: int, s: TSocket,
               headers: seq[THeader]): string =
  if getHeaderValue(headers, "Transfer-Encoding") == "chunked":
    result = parseChunks(d, start, s)
  else:
    result = copy(d, start)
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
  var d = s.recv()
  var i = 0

  # Parse the version
  # Parses the first line of the headers
  # ``HTTP/1.1`` 200 OK

  var matches: array[0..1, string]
  var L = d.matchLen(peg"\i 'HTTP/' {'1.1'/'1.0'} \s+ {(!\n .)*}\n",
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
    while d[i] != ':':
      if d[i] == '\0': httpError("invalid HTTP header, ':' expected")
      key.add(d[i])
      inc(i)
    inc(i) # skip ':'
    if d[i] == ' ': inc(i) # skip if the character is a space
    var val = ""
    while d[i] notin {'\C', '\L', '\0'}:
      val.add(d[i])
      inc(i)
    
    result.headers.add((key, val))
    
    if d[i] == '\C': inc(i)
    if d[i] == '\L': inc(i)
    else: httpError("invalid HTTP header, CR-LF expected")
    
    if d[i] == '\C': inc(i)
    if d[i] == '\L':
      inc(i)
      break
    
  result.body = parseBody(d, i, s, result.headers) 

proc request*(url: string): TResponse =
  var r = parse(url)
  
  var headers: string
  if r.path != "":
    headers = "GET " & r.path & " HTTP/1.1\c\L"
  else:
    headers = "GET / HTTP/1.1\c\L"
  
  add(headers, "Host: " & r.hostname & "\c\L\c\L")
  add(headers, "User-Agent: Mozilla/5.0 (Windows; U; Windows NT 6.1; pl;" &
               " rv:1.9.2) Gecko/20100115 Firefox/3.6")

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
  #downloadFile("http://force7.de/nimrod/index.html", "nimrodindex.html")
  #downloadFile("http://www.httpwatch.com/", "ChunkTest.html")
  downloadFile("http://www.httpwatch.com/httpgallery/chunked/", "ChunkTest.html")
  
