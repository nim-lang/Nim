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
##
## Retrieving a website
## ====================
## 
## This example uses HTTP GET to retrieve
## ``http://google.com``
## 
## .. code-block:: nimrod
##   echo(getContent("http://google.com"))
## 
## Using HTTP POST
## ===============
## 
## This example demonstrates the usage of the W3 HTML Validator, it 
## uses ``multipart/form-data`` as the ``Content-Type`` to send the HTML to
## the server. 
## 
## .. code-block:: nimrod
##   var headers: string = "Content-Type: multipart/form-data; boundary=xyz\c\L"
##   var body: string = "--xyz\c\L"
##   # soap 1.2 output
##   body.add("Content-Disposition: form-data; name=\"output\"\c\L")
##   body.add("\c\Lsoap12\c\L")
##    
##   # html
##   body.add("--xyz\c\L")
##   body.add("Content-Disposition: form-data; name=\"uploaded_file\";" &
##            " filename=\"test.html\"\c\L")
##   body.add("Content-Type: text/html\c\L")
##   body.add("\c\L<html><head></head><body><p>test</p></body></html>\c\L")
##   body.add("--xyz--")
##    
##   echo(postContent("http://validator.w3.org/check", headers, body))
##
## SSL/TLS support
## ===============
## This requires the OpenSSL library, fortunately it's widely used and installed
## on many operating systems. httpclient will use SSL automatically if you give
## any of the functions a url with the ``https`` schema, for example:
## ``https://github.com/``, you also have to compile with ``ssl`` defined like so:
## ``nimrod c -d:ssl ...``.

import sockets, strutils, parseurl, parseutils, strtabs

type
  TResponse* = tuple[
    version: string, 
    status: string, 
    headers: PStringTable,
    body: string]

  EInvalidProtocol* = object of ESynch ## exception that is raised when server
                                       ## does not conform to the implemented
                                       ## protocol

  EHttpRequestErr* = object of ESynch ## Thrown in the ``getContent`` proc 
                                      ## and ``postContent`` proc,
                                      ## when the server returns an error

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

proc parseChunks(s: TSocket): string =
  result = ""
  var ri = 0
  while true:
    var chunkSizeStr = ""
    var chunkSize = 0
    if s.recvLine(chunkSizeStr):
      var i = 0
      if chunkSizeStr == "":
        httpError("Server terminated connection prematurely")
      while true:
        case chunkSizeStr[i]
        of '0'..'9':
          chunkSize = chunkSize shl 4 or (ord(chunkSizeStr[i]) - ord('0'))
        of 'a'..'f':
          chunkSize = chunkSize shl 4 or (ord(chunkSizeStr[i]) - ord('a') + 10)
        of 'A'..'F':
          chunkSize = chunkSize shl 4 or (ord(chunkSizeStr[i]) - ord('A') + 10)
        of '\0':
          break
        of ';':
          # http://tools.ietf.org/html/rfc2616#section-3.6.1
          # We don't care about chunk-extensions.
          break
        else:
          httpError("Invalid chunk size: " & chunkSizeStr)
        inc(i)
    if chunkSize <= 0: break
    result.setLen(ri+chunkSize)
    var bytesRead = 0
    while bytesRead != chunkSize:
      let ret = recv(s, addr(result[ri]), chunkSize-bytesRead)
      ri += ret
      bytesRead += ret
    s.skip(2) # Skip \c\L
    # Trailer headers will only be sent if the request specifies that we want
    # them: http://tools.ietf.org/html/rfc2616#section-3.6.1
  
proc parseBody(s: TSocket,
               headers: PStringTable): string =
  result = ""
  if headers["Transfer-Encoding"] == "chunked":
    result = parseChunks(s)
  else:
    # -REGION- Content-Length
    # (http://tools.ietf.org/html/rfc2616#section-4.4) NR.3
    var contentLengthHeader = headers["Content-Length"]
    if contentLengthHeader != "":
      var length = contentLengthHeader.parseint()
      result = newString(length)
      var received = 0
      while true:
        if received >= length: break
        let r = s.recv(addr(result[received]), length-received)
        if r == 0: break
        received += r
      if received != length:
        httpError("Got invalid content length. Expected: " & $length &
                  " got: " & $received)
    else:
      # (http://tools.ietf.org/html/rfc2616#section-4.4) NR.4 TODO
      
      # -REGION- Connection: Close
      # (http://tools.ietf.org/html/rfc2616#section-4.4) NR.5
      if headers["Connection"] == "close":
        var buf = ""
        while True:
          buf = newString(4000)
          let r = s.recv(addr(buf[0]), 4000)
          if r == 0: break
          buf.setLen(r)
          result.add(buf)

proc parseResponse(s: TSocket, getBody: bool): TResponse =
  var parsedStatus = false
  var linei = 0
  var fullyRead = false
  var line = ""
  result.headers = newStringTable(modeCaseInsensitive)
  while True:
    line = ""
    linei = 0
    if s.recvLine(line):
      if line == "": break # We've been disconnected.
      if line == "\c\L":
        fullyRead = true
        break
      if not parsedStatus:
        # Parse HTTP version info and status code.
        var le = skipIgnoreCase(line, "HTTP/", linei)
        if le <= 0: httpError("invalid http version")
        inc(linei, le)
        le = skipIgnoreCase(line, "1.1", linei)
        if le > 0: result.version = "1.1"
        else:
          le = skipIgnoreCase(line, "1.0", linei)
          if le <= 0: httpError("unsupported http version")
          result.version = "1.0"
        inc(linei, le)
        # Status code
        linei.inc skipWhitespace(line, linei)
        result.status = line[linei .. -1]
        parsedStatus = true
      else:
        # Parse headers
        var name = ""
        var le = parseUntil(line, name, ':', linei)
        if le <= 0: httpError("invalid headers")
        inc(linei, le)
        if line[linei] != ':': httpError("invalid headers")
        inc(linei) # Skip :
        linei += skipWhitespace(line, linei)
        
        result.headers[name] = line[linei.. -1]
  if not fullyRead: httpError("Connection was closed before full request has been made")
  if getBody:
    result.body = parseBody(s, result.headers)
  else:
    result.body = ""

type
  THttpMethod* = enum ## the requested HttpMethod
    httpHEAD,         ## Asks for the response identical to the one that would
                      ## correspond to a GET request, but without the response
                      ## body.
    httpGET,          ## Retrieves the specified resource.
    httpPOST,         ## Submits data to be processed to the identified 
                      ## resource. The data is included in the body of the 
                      ## request.
    httpPUT,          ## Uploads a representation of the specified resource.
    httpDELETE,       ## Deletes the specified resource.
    httpTRACE,        ## Echoes back the received request, so that a client 
                      ## can see what intermediate servers are adding or
                      ## changing in the request.
    httpOPTIONS,      ## Returns the HTTP methods that the server supports 
                      ## for specified address.
    httpCONNECT       ## Converts the request connection to a transparent 
                      ## TCP/IP tunnel, usually used for proxies.

when not defined(ssl):
  type PSSLContext = ref object
  let defaultSSLContext: PSSLContext = nil
else:
  let defaultSSLContext = newContext(verifyMode = CVerifyNone)

proc request*(url: string, httpMethod = httpGET, extraHeaders = "", 
              body = "",
              sslContext: PSSLContext = defaultSSLContext): TResponse =
  ## | Requests ``url`` with the specified ``httpMethod``.
  ## | Extra headers can be specified and must be seperated by ``\c\L``
  var r = parseUrl(url)
  var headers = substr($httpMethod, len("http"))
  headers.add(" /" & r.path & r.query)

  headers.add(" HTTP/1.1\c\L")
  
  add(headers, "Host: " & r.hostname & "\c\L")
  add(headers, extraHeaders)
  add(headers, "\c\L")

  var s = socket()
  var port = TPort(80)
  if r.scheme == "https":
    when defined(ssl):
      sslContext.wrapSocket(s)
    else:
      raise newException(EHttpRequestErr, "SSL support was not compiled in. Cannot connect over SSL.")
    port = TPort(443)
  if r.port != "":
    port = TPort(r.port.parseInt)
  s.connect(r.hostname, port)
  s.send(headers)
  if body != "":
    s.send(body)
  
  result = parseResponse(s, httpMethod != httpHEAD)
  s.close()
  
proc redirection(status: string): bool =
  const redirectionNRs = ["301", "302", "303", "307"]
  for i in items(redirectionNRs):
    if status.startsWith(i):
      return True
  
proc get*(url: string, maxRedirects = 5, sslContext: PSSLContext = defaultSSLContext): TResponse =
  ## | GETs the ``url`` and returns a ``TResponse`` object
  ## | This proc also handles redirection
  result = request(url)
  for i in 1..maxRedirects:
    if result.status.redirection():
      var locationHeader = result.headers["Location"]
      if locationHeader == "": httpError("location header expected")
      result = request(locationHeader, sslContext = sslContext)
      
proc getContent*(url: string, sslContext: PSSLContext = defaultSSLContext): string =
  ## | GETs the body and returns it as a string.
  ## | Raises exceptions for the status codes ``4xx`` and ``5xx``
  var r = get(url, sslContext = sslContext)
  if r.status[0] in {'4','5'}:
    raise newException(EHTTPRequestErr, r.status)
  else:
    return r.body
  
proc post*(url: string, extraHeaders = "", body = "", 
           maxRedirects = 5, sslContext: PSSLContext = defaultSSLContext): TResponse =
  ## | POSTs ``body`` to the ``url`` and returns a ``TResponse`` object.
  ## | This proc adds the necessary Content-Length header.
  ## | This proc also handles redirection.
  var xh = extraHeaders & "Content-Length: " & $len(body) & "\c\L"
  result = request(url, httpPOST, xh, body, sslContext)
  for i in 1..maxRedirects:
    if result.status.redirection():
      var locationHeader = result.headers["Location"]
      if locationHeader == "": httpError("location header expected")
      var meth = if result.status != "307": httpGet else: httpPost
      result = request(locationHeader, meth, xh, body)
  
proc postContent*(url: string, extraHeaders = "", body = "",
                  sslContext: PSSLContext = defaultSSLContext): string =
  ## | POSTs ``body`` to ``url`` and returns the response's body as a string
  ## | Raises exceptions for the status codes ``4xx`` and ``5xx``
  var r = post(url, extraHeaders, body)
  if r.status[0] in {'4','5'}:
    raise newException(EHTTPRequestErr, r.status)
  else:
    return r.body
  
proc downloadFile*(url: string, outputFilename: string,
                   sslContext: PSSLContext = defaultSSLContext) =
  ## Downloads ``url`` and saves it to ``outputFilename``
  var f: TFile
  if open(f, outputFilename, fmWrite):
    f.write(getContent(url, sslContext))
    f.close()
  else:
    fileError("Unable to open file")


when isMainModule:
  #downloadFile("http://force7.de/nimrod/index.html", "nimrodindex.html")
  #downloadFile("http://www.httpwatch.com/", "ChunkTest.html")
  #downloadFile("http://validator.w3.org/check?uri=http%3A%2F%2Fgoogle.com",
  # "validator.html")

  #var r = get("http://validator.w3.org/check?uri=http%3A%2F%2Fgoogle.com&
  #  charset=%28detect+automatically%29&doctype=Inline&group=0")
  
  var headers: string = "Content-Type: multipart/form-data; boundary=xyz\c\L"
  var body: string = "--xyz\c\L"
  # soap 1.2 output
  body.add("Content-Disposition: form-data; name=\"output\"\c\L")
  body.add("\c\Lsoap12\c\L")
  
  # html
  body.add("--xyz\c\L")
  body.add("Content-Disposition: form-data; name=\"uploaded_file\";" &
           " filename=\"test.html\"\c\L")
  body.add("Content-Type: text/html\c\L")
  body.add("\c\L<html><head></head><body><p>test</p></body></html>\c\L")
  body.add("--xyz--")

  echo(postContent("http://validator.w3.org/check", headers, body))
