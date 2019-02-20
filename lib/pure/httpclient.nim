#
#
#            Nim's Runtime Library
#        (c) Copyright 2016 Dominik Picheta, Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a simple HTTP client that can be used to retrieve
## webpages and other data.
##
## Retrieving a website
## ====================
##
## This example uses HTTP GET to retrieve
## ``http://google.com``:
##
## .. code-block:: Nim
##   import httpClient
##   var client = newHttpClient()
##   echo client.getContent("http://google.com")
##
## The same action can also be performed asynchronously, simply use the
## ``AsyncHttpClient``:
##
## .. code-block:: Nim
##   import httpClient
##   var client = newAsyncHttpClient()
##   echo await client.getContent("http://google.com")
##
## The functionality implemented by ``HttpClient`` and ``AsyncHttpClient``
## is the same, so you can use whichever one suits you best in the examples
## shown here.
##
## **Note:** You will need to run asynchronous examples in an async proc
## otherwise you will get an ``Undeclared identifier: 'await'`` error.
##
## Using HTTP POST
## ===============
##
## This example demonstrates the usage of the W3 HTML Validator, it
## uses ``multipart/form-data`` as the ``Content-Type`` to send the HTML to be
## validated to the server.
##
## .. code-block:: Nim
##   var client = newHttpClient()
##   var data = newMultipartData()
##   data["output"] = "soap12"
##   data["uploaded_file"] = ("test.html", "text/html",
##     "<html><head></head><body><p>test</p></body></html>")
##
##   echo client.postContent("http://validator.w3.org/check", multipart=data)
##
## You can also make post requests with custom headers.
## This example sets ``Content-Type`` to ``application/json``
## and uses a json object for the body
##
## .. code-block:: Nim
##   import httpclient, json
##
##   let client = newHttpClient()
##   client.headers = newHttpHeaders({ "Content-Type": "application/json" })
##   let body = %*{
##       "data": "some text"
##   }
##   let response = client.request("http://some.api", httpMethod = HttpPost, body = $body)
##   echo response.status
##
## Progress reporting
## ==================
##
## You may specify a callback procedure to be called during an HTTP request.
## This callback will be executed every second with information about the
## progress of the HTTP request.
##
## .. code-block:: Nim
##    import asyncdispatch, httpclient
##
##    proc onProgressChanged(total, progress, speed: BiggestInt) {.async.} =
##      echo("Downloaded ", progress, " of ", total)
##      echo("Current rate: ", speed div 1000, "kb/s")
##
##    proc asyncProc() {.async.} =
##      var client = newAsyncHttpClient()
##      client.onProgressChanged = onProgressChanged
##      discard await client.getContent("http://speedtest-ams2.digitalocean.com/100mb.test")
##
##    waitFor asyncProc()
##
## If you would like to remove the callback simply set it to ``nil``.
##
## .. code-block:: Nim
##   client.onProgressChanged = nil
##
## **Warning:** The ``total`` reported by httpclient may be 0 in some cases.
##
##
## SSL/TLS support
## ===============
## This requires the OpenSSL library, fortunately it's widely used and installed
## on many operating systems. httpclient will use SSL automatically if you give
## any of the functions a url with the ``https`` schema, for example:
## ``https://github.com/``.
##
## You will also have to compile with ``ssl`` defined like so:
## ``nim c -d:ssl ...``.
##
## Timeouts
## ========
##
## Currently only the synchronous functions support a timeout.
## The timeout is
## measured in milliseconds, once it is set any call on a socket which may
## block will be susceptible to this timeout.
##
## It may be surprising but the
## function as a whole can take longer than the specified timeout, only
## individual internal calls on the socket are affected. In practice this means
## that as long as the server is sending data an exception will not be raised,
## if however data does not reach the client within the specified timeout a
## ``TimeoutError`` exception will be raised.
##
## Proxy
## =====
##
## A proxy can be specified as a param to any of the procedures defined in
## this module. To do this, use the ``newProxy`` constructor. Unfortunately,
## only basic authentication is supported at the moment.

import net, strutils, uri, parseutils, strtabs, base64, os, mimetypes,
  math, random, httpcore, times, tables, streams
import asyncnet, asyncdispatch, asyncfile
import nativesockets

export httpcore except parseHeader # TODO: The ``except`` doesn't work

type
  Response* = ref object
    version*: string
    status*: string
    headers*: HttpHeaders
    body: string
    bodyStream*: Stream

  AsyncResponse* = ref object
    version*: string
    status*: string
    headers*: HttpHeaders
    body: string
    bodyStream*: FutureStream[string]

proc code*(response: Response | AsyncResponse): HttpCode
           {.raises: [ValueError, OverflowError].} =
  ## Retrieves the specified response's ``HttpCode``.
  ##
  ## Raises a ``ValueError`` if the response's ``status`` does not have a
  ## corresponding ``HttpCode``.
  return response.status[0 .. 2].parseInt.HttpCode

proc contentType*(response: Response | AsyncResponse): string =
  ## Retrieves the specified response's content type.
  ##
  ## This is effectively the value of the "Content-Type" header.
  response.headers.getOrDefault("content-type")

proc contentLength*(response: Response | AsyncResponse): int =
  ## Retrieves the specified response's content length.
  ##
  ## This is effectively the value of the "Content-Length" header.
  ##
  ## A ``ValueError`` exception will be raised if the value is not an integer.
  var contentLengthHeader = response.headers.getOrDefault("Content-Length")
  return contentLengthHeader.parseInt()

proc lastModified*(response: Response | AsyncResponse): DateTime =
  ## Retrieves the specified response's last modified time.
  ##
  ## This is effectively the value of the "Last-Modified" header.
  ##
  ## Raises a ``ValueError`` if the parsing fails or the value is not a correctly
  ## formatted time.
  var lastModifiedHeader = response.headers.getOrDefault("last-modified")
  result = parse(lastModifiedHeader, "dd, dd MMM yyyy HH:mm:ss Z")

proc body*(response: Response): string =
  ## Retrieves the specified response's body.
  ##
  ## The response's body stream is read synchronously.
  if response.body.len == 0:
    response.body = response.bodyStream.readAll()
  return response.body

proc body*(response: AsyncResponse): Future[string] {.async.} =
  ## Reads the response's body and caches it. The read is performed only
  ## once.
  if response.body.len == 0:
    response.body = await readAll(response.bodyStream)
  return response.body

type
  Proxy* = ref object
    url*: Uri
    auth*: string

  MultipartEntries* = openarray[tuple[name, content: string]]
  MultipartData* = ref object
    content: seq[string]

  ProtocolError* = object of IOError   ## exception that is raised when server
                                       ## does not conform to the implemented
                                       ## protocol

  HttpRequestError* = object of IOError ## Thrown in the ``getContent`` proc
                                        ## and ``postContent`` proc,
                                        ## when the server returns an error

const defUserAgent* = "Nim httpclient/" & NimVersion

proc httpError(msg: string) =
  var e: ref ProtocolError
  new(e)
  e.msg = msg
  raise e

proc fileError(msg: string) =
  var e: ref IOError
  new(e)
  e.msg = msg
  raise e

proc parseChunks(s: Socket, timeout: int): string =
  result = ""
  var ri = 0
  while true:
    var chunkSizeStr = ""
    var chunkSize = 0
    s.readLine(chunkSizeStr, timeout)
    var i = 0
    if chunkSizeStr == "":
      httpError("Server terminated connection prematurely")
    while i < chunkSizeStr.len:
      case chunkSizeStr[i]
      of '0'..'9':
        chunkSize = chunkSize shl 4 or (ord(chunkSizeStr[i]) - ord('0'))
      of 'a'..'f':
        chunkSize = chunkSize shl 4 or (ord(chunkSizeStr[i]) - ord('a') + 10)
      of 'A'..'F':
        chunkSize = chunkSize shl 4 or (ord(chunkSizeStr[i]) - ord('A') + 10)
      of ';':
        # http://tools.ietf.org/html/rfc2616#section-3.6.1
        # We don't care about chunk-extensions.
        break
      else:
        httpError("Invalid chunk size: " & chunkSizeStr)
      inc(i)
    if chunkSize <= 0:
      s.skip(2, timeout) # Skip \c\L
      break
    result.setLen(ri+chunkSize)
    var bytesRead = 0
    while bytesRead != chunkSize:
      let ret = recv(s, addr(result[ri]), chunkSize-bytesRead, timeout)
      ri += ret
      bytesRead += ret
    s.skip(2, timeout) # Skip \c\L
    # Trailer headers will only be sent if the request specifies that we want
    # them: http://tools.ietf.org/html/rfc2616#section-3.6.1

proc parseBody(s: Socket, headers: HttpHeaders, httpVersion: string, timeout: int): string =
  result = ""
  if headers.getOrDefault"Transfer-Encoding" == "chunked":
    result = parseChunks(s, timeout)
  else:
    # -REGION- Content-Length
    # (http://tools.ietf.org/html/rfc2616#section-4.4) NR.3
    var contentLengthHeader = headers.getOrDefault"Content-Length"
    if contentLengthHeader != "":
      var length = contentLengthHeader.parseint()
      if length > 0:
        result = newString(length)
        var received = 0
        while true:
          if received >= length: break
          let r = s.recv(addr(result[received]), length-received, timeout)
          if r == 0: break
          received += r
        if received != length:
          httpError("Got invalid content length. Expected: " & $length &
                    " got: " & $received)
    else:
      # (http://tools.ietf.org/html/rfc2616#section-4.4) NR.4 TODO

      # -REGION- Connection: Close
      # (http://tools.ietf.org/html/rfc2616#section-4.4) NR.5
      if headers.getOrDefault"Connection" == "close" or httpVersion == "1.0":
        var buf = ""
        while true:
          buf = newString(4000)
          let r = s.recv(addr(buf[0]), 4000, timeout)
          if r == 0: break
          buf.setLen(r)
          result.add(buf)

proc parseResponse(s: Socket, getBody: bool, timeout: int): Response =
  new result
  var parsedStatus = false
  var linei = 0
  var fullyRead = false
  var line = ""
  result.headers = newHttpHeaders()
  while true:
    line = ""
    linei = 0
    s.readLine(line, timeout)
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
      result.status = line[linei .. ^1]
      parsedStatus = true
    else:
      # Parse headers
      var name = ""
      var le = parseUntil(line, name, ':', linei)
      if le <= 0: httpError("invalid headers")
      inc(linei, le)
      if line[linei] != ':': httpError("invalid headers")
      inc(linei) # Skip :

      result.headers.add(name, line[linei.. ^1].strip())
      # Ensure the server isn't trying to DoS us.
      if result.headers.len > headerLimit:
        httpError("too many headers")

  if not fullyRead:
    httpError("Connection was closed before full request has been made")
  if getBody:
    result.body = parseBody(s, result.headers, result.version, timeout)
  else:
    result.body = ""

when not defined(ssl):
  type SSLContext = ref object
var defaultSSLContext {.threadvar.}: SSLContext

proc getDefaultSSL(): SSLContext =
  result = defaultSslContext
  when defined(ssl):
    if result == nil:
      defaultSSLContext = newContext(verifyMode = CVerifyNone)
      result = defaultSSLContext
      doAssert result != nil, "failure to initialize the SSL context"

proc newProxy*(url: string, auth = ""): Proxy =
  ## Constructs a new ``TProxy`` object.
  result = Proxy(url: parseUri(url), auth: auth)

proc newMultipartData*: MultipartData =
  ## Constructs a new ``MultipartData`` object.
  MultipartData(content: @[])

proc add*(p: var MultipartData, name, content: string, filename: string = "",
          contentType: string = "") =
  ## Add a value to the multipart data. Raises a `ValueError` exception if
  ## `name`, `filename` or `contentType` contain newline characters.

  if {'\c','\L'} in name:
    raise newException(ValueError, "name contains a newline character")
  if {'\c','\L'} in filename:
    raise newException(ValueError, "filename contains a newline character")
  if {'\c','\L'} in contentType:
    raise newException(ValueError, "contentType contains a newline character")

  var str = "Content-Disposition: form-data; name=\"" & name & "\""
  if filename.len > 0:
    str.add("; filename=\"" & filename & "\"")
  str.add("\c\L")
  if contentType.len > 0:
    str.add("Content-Type: " & contentType & "\c\L")
  str.add("\c\L" & content & "\c\L")

  p.content.add(str)

proc add*(p: var MultipartData, xs: MultipartEntries): MultipartData
         {.discardable.} =
  ## Add a list of multipart entries to the multipart data `p`. All values are
  ## added without a filename and without a content type.
  ##
  ## .. code-block:: Nim
  ##   data.add({"action": "login", "format": "json"})
  for name, content in xs.items:
    p.add(name, content)
  result = p

proc newMultipartData*(xs: MultipartEntries): MultipartData =
  ## Create a new multipart data object and fill it with the entries `xs`
  ## directly.
  ##
  ## .. code-block:: Nim
  ##   var data = newMultipartData({"action": "login", "format": "json"})
  result = MultipartData(content: @[])
  result.add(xs)

proc addFiles*(p: var MultipartData, xs: openarray[tuple[name, file: string]]):
              MultipartData {.discardable.} =
  ## Add files to a multipart data object. The file will be opened from your
  ## disk, read and sent with the automatically determined MIME type. Raises an
  ## `IOError` if the file cannot be opened or reading fails. To manually
  ## specify file content, filename and MIME type, use `[]=` instead.
  ##
  ## .. code-block:: Nim
  ##   data.addFiles({"uploaded_file": "public/test.html"})
  var m = newMimetypes()
  for name, file in xs.items:
    var contentType: string
    let (_, fName, ext) = splitFile(file)
    if ext.len > 0:
      contentType = m.getMimetype(ext[1..ext.high], "")
    p.add(name, readFile(file), fName & ext, contentType)
  result = p

proc `[]=`*(p: var MultipartData, name, content: string) =
  ## Add a multipart entry to the multipart data `p`. The value is added
  ## without a filename and without a content type.
  ##
  ## .. code-block:: Nim
  ##   data["username"] = "NimUser"
  p.add(name, content)

proc `[]=`*(p: var MultipartData, name: string,
            file: tuple[name, contentType, content: string]) =
  ## Add a file to the multipart data `p`, specifying filename, contentType and
  ## content manually.
  ##
  ## .. code-block:: Nim
  ##   data["uploaded_file"] = ("test.html", "text/html",
  ##     "<html><head></head><body><p>test</p></body></html>")
  p.add(name, file.content, file.name, file.contentType)

proc format(p: MultipartData): tuple[contentType, body: string] =
  if p == nil or p.content.len == 0:
    return ("", "")

  # Create boundary that is not in the data to be formatted
  var bound: string
  while true:
    bound = $random(int.high)
    var found = false
    for s in p.content:
      if bound in s:
        found = true
    if not found:
      break

  result.contentType = "multipart/form-data; boundary=" & bound
  result.body = ""
  for s in p.content:
    result.body.add("--" & bound & "\c\L" & s)
  result.body.add("--" & bound & "--\c\L")

proc redirection(status: string): bool =
  const redirectionNRs = ["301", "302", "303", "307"]
  for i in items(redirectionNRs):
    if status.startsWith(i):
      return true

proc getNewLocation(lastURL: string, headers: HttpHeaders): string =
  result = headers.getOrDefault"Location"
  if result == "": httpError("location header expected")
  # Relative URLs. (Not part of the spec, but soon will be.)
  let r = parseUri(result)
  if r.hostname == "" and r.path != "":
    var parsed = parseUri(lastURL)
    parsed.path = r.path
    parsed.query = r.query
    parsed.anchor = r.anchor
    result = $parsed

proc generateHeaders(requestUrl: Uri, httpMethod: string,
                     headers: HttpHeaders, body: string, proxy: Proxy): string =
  # GET
  let upperMethod = httpMethod.toUpperAscii()
  result = upperMethod
  result.add ' '

  if proxy.isNil or requestUrl.scheme == "https":
    # /path?query
    if not requestUrl.path.startsWith("/"): result.add '/'
    result.add(requestUrl.path)
    if requestUrl.query.len > 0:
      result.add("?" & requestUrl.query)
  else:
    # Remove the 'http://' from the URL for CONNECT requests for TLS connections.
    var modifiedUrl = requestUrl
    if requestUrl.scheme == "https": modifiedUrl.scheme = ""
    result.add($modifiedUrl)

  # HTTP/1.1\c\l
  result.add(" HTTP/1.1\c\L")

  # Host header.
  if requestUrl.port == "":
    add(result, "Host: " & requestUrl.hostname & "\c\L")
  else:
    add(result, "Host: " & requestUrl.hostname & ":" & requestUrl.port & "\c\L")

  # Connection header.
  if not headers.hasKey("Connection"):
    add(result, "Connection: Keep-Alive\c\L")

  # Content length header.
  const requiresBody = ["POST", "PUT", "PATCH"]
  let needsContentLength = body.len > 0 or upperMethod in requiresBody
  if needsContentLength and not headers.hasKey("Content-Length"):
    add(result, "Content-Length: " & $body.len & "\c\L")

  # Proxy auth header.
  if not proxy.isNil and proxy.auth != "":
    let auth = base64.encode(proxy.auth, newline = "")
    add(result, "Proxy-Authorization: basic " & auth & "\c\L")

  for key, val in headers:
    add(result, key & ": " & val & "\c\L")

  add(result, "\c\L")

type
  ProgressChangedProc*[ReturnType] =
    proc (total, progress, speed: BiggestInt):
      ReturnType {.closure, gcsafe.}

  HttpClientBase*[SocketType] = ref object
    socket: SocketType
    connected: bool
    currentURL: Uri ## Where we are currently connected.
    headers*: HttpHeaders ## Headers to send in requests.
    maxRedirects: int
    userAgent: string
    timeout*: int ## Only used for blocking HttpClient for now.
    proxy: Proxy
    ## ``nil`` or the callback to call when request progress changes.
    when SocketType is Socket:
      onProgressChanged*: ProgressChangedProc[void]
    else:
      onProgressChanged*: ProgressChangedProc[Future[void]]
    when defined(ssl):
      sslContext: net.SslContext
    contentTotal: BiggestInt
    contentProgress: BiggestInt
    oneSecondProgress: BiggestInt
    lastProgressReport: float
    when SocketType is AsyncSocket:
      bodyStream: FutureStream[string]
      parseBodyFut: Future[void]
    else:
      bodyStream: Stream
    getBody: bool ## When `false`, the body is never read in requestAux.

type
  HttpClient* = HttpClientBase[Socket]

proc newHttpClient*(userAgent = defUserAgent,
    maxRedirects = 5, sslContext = getDefaultSSL(), proxy: Proxy = nil,
    timeout = -1): HttpClient =
  ## Creates a new HttpClient instance.
  ##
  ## ``userAgent`` specifies the user agent that will be used when making
  ## requests.
  ##
  ## ``maxRedirects`` specifies the maximum amount of redirects to follow,
  ## default is 5.
  ##
  ## ``sslContext`` specifies the SSL context to use for HTTPS requests.
  ##
  ## ``proxy`` specifies an HTTP proxy to use for this HTTP client's
  ## connections.
  ##
  ## ``timeout`` specifies the number of milliseconds to allow before a
  ## ``TimeoutError`` is raised.
  new result
  result.headers = newHttpHeaders()
  result.userAgent = userAgent
  result.maxRedirects = maxRedirects
  result.proxy = proxy
  result.timeout = timeout
  result.onProgressChanged = nil
  result.bodyStream = newStringStream()
  result.getBody = true
  when defined(ssl):
    result.sslContext = sslContext

type
  AsyncHttpClient* = HttpClientBase[AsyncSocket]

proc newAsyncHttpClient*(userAgent = defUserAgent,
    maxRedirects = 5, sslContext = getDefaultSSL(),
    proxy: Proxy = nil): AsyncHttpClient =
  ## Creates a new AsyncHttpClient instance.
  ##
  ## ``userAgent`` specifies the user agent that will be used when making
  ## requests.
  ##
  ## ``maxRedirects`` specifies the maximum amount of redirects to follow,
  ## default is 5.
  ##
  ## ``sslContext`` specifies the SSL context to use for HTTPS requests.
  ##
  ## ``proxy`` specifies an HTTP proxy to use for this HTTP client's
  ## connections.
  new result
  result.headers = newHttpHeaders()
  result.userAgent = userAgent
  result.maxRedirects = maxRedirects
  result.proxy = proxy
  result.timeout = -1 # TODO
  result.onProgressChanged = nil
  result.bodyStream = newFutureStream[string]("newAsyncHttpClient")
  result.getBody = true
  when defined(ssl):
    result.sslContext = sslContext

proc close*(client: HttpClient | AsyncHttpClient) =
  ## Closes any connections held by the HTTP client.
  if client.connected:
    client.socket.close()
    client.connected = false

proc reportProgress(client: HttpClient | AsyncHttpClient,
                    progress: BiggestInt) {.multisync.} =
  client.contentProgress += progress
  client.oneSecondProgress += progress
  if epochTime() - client.lastProgressReport >= 1.0:
    if not client.onProgressChanged.isNil:
      await client.onProgressChanged(client.contentTotal,
                                     client.contentProgress,
                                     client.oneSecondProgress)
      client.oneSecondProgress = 0
      client.lastProgressReport = epochTime()

proc recvFull(client: HttpClient | AsyncHttpClient, size: int, timeout: int,
              keep: bool): Future[int] {.multisync.} =
  ## Ensures that all the data requested is read and returned.
  var readLen = 0
  while true:
    if size == readLen: break

    let remainingSize = size - readLen
    let sizeToRecv = min(remainingSize, net.BufferSize)

    when client.socket is Socket:
      let data = client.socket.recv(sizeToRecv, timeout)
    else:
      let data = await client.socket.recv(sizeToRecv)
    if data == "":
      client.close()
      break # We've been disconnected.

    readLen.inc(data.len)
    if keep:
      await client.bodyStream.write(data)

    await reportProgress(client, data.len)

  return readLen

proc parseChunks(client: HttpClient | AsyncHttpClient): Future[void]
                 {.multisync.} =
  while true:
    var chunkSize = 0
    var chunkSizeStr = await client.socket.recvLine()
    var i = 0
    if chunkSizeStr == "":
      httpError("Server terminated connection prematurely")
    while i < chunkSizeStr.len:
      case chunkSizeStr[i]
      of '0'..'9':
        chunkSize = chunkSize shl 4 or (ord(chunkSizeStr[i]) - ord('0'))
      of 'a'..'f':
        chunkSize = chunkSize shl 4 or (ord(chunkSizeStr[i]) - ord('a') + 10)
      of 'A'..'F':
        chunkSize = chunkSize shl 4 or (ord(chunkSizeStr[i]) - ord('A') + 10)
      of ';':
        # http://tools.ietf.org/html/rfc2616#section-3.6.1
        # We don't care about chunk-extensions.
        break
      else:
        httpError("Invalid chunk size: " & chunkSizeStr)
      inc(i)
    if chunkSize <= 0:
      discard await recvFull(client, 2, client.timeout, false) # Skip \c\L
      break
    var bytesRead = await recvFull(client, chunkSize, client.timeout, true)
    if bytesRead != chunkSize:
      httpError("Server terminated connection prematurely")

    bytesRead = await recvFull(client, 2, client.timeout, false) # Skip \c\L
    if bytesRead != 2:
      httpError("Server terminated connection prematurely")

    # Trailer headers will only be sent if the request specifies that we want
    # them: http://tools.ietf.org/html/rfc2616#section-3.6.1

proc parseBody(client: HttpClient | AsyncHttpClient,
               headers: HttpHeaders,
               httpVersion: string): Future[void] {.multisync.} =
  # Reset progress from previous requests.
  client.contentTotal = 0
  client.contentProgress = 0
  client.oneSecondProgress = 0
  client.lastProgressReport = 0

  when client is AsyncHttpClient:
    assert(not client.bodyStream.finished)

  if headers.getOrDefault"Transfer-Encoding" == "chunked":
    await parseChunks(client)
  else:
    # -REGION- Content-Length
    # (http://tools.ietf.org/html/rfc2616#section-4.4) NR.3
    var contentLengthHeader = headers.getOrDefault"Content-Length"
    if contentLengthHeader != "":
      var length = contentLengthHeader.parseint()
      client.contentTotal = length
      if length > 0:
        let recvLen = await client.recvFull(length, client.timeout, true)
        if recvLen == 0:
          client.close()
          httpError("Got disconnected while trying to read body.")
        if recvLen != length:
          httpError("Received length doesn't match expected length. Wanted " &
                    $length & " got " & $recvLen)
    else:
      # (http://tools.ietf.org/html/rfc2616#section-4.4) NR.4 TODO

      # -REGION- Connection: Close
      # (http://tools.ietf.org/html/rfc2616#section-4.4) NR.5
      if headers.getOrDefault"Connection" == "close" or httpVersion == "1.0":
        while true:
          let recvLen = await client.recvFull(4000, client.timeout, true)
          if recvLen != 4000:
            client.close()
            break

  when client is AsyncHttpClient:
    client.bodyStream.complete()
  else:
    client.bodyStream.setPosition(0)

  # If the server will close our connection, then no matter the method of
  # reading the body, we need to close our socket.
  if headers.getOrDefault"Connection" == "close":
    client.close()

proc parseResponse(client: HttpClient | AsyncHttpClient,
                   getBody: bool): Future[Response | AsyncResponse]
                   {.multisync.} =
  new result
  var parsedStatus = false
  var linei = 0
  var fullyRead = false
  var line = ""
  result.headers = newHttpHeaders()
  while true:
    linei = 0
    when client is HttpClient:
      line = await client.socket.recvLine(client.timeout)
    else:
      line = await client.socket.recvLine()
    if line == "":
      # We've been disconnected.
      client.close()
      break
    if line == "\c\L":
      fullyRead = true
      break
    if not parsedStatus:
      # Parse HTTP version info and status code.
      var le = skipIgnoreCase(line, "HTTP/", linei)
      if le <= 0:
        httpError("invalid http version, " & line.repr)
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
      result.status = line[linei .. ^1]
      parsedStatus = true
    else:
      # Parse headers
      var name = ""
      var le = parseUntil(line, name, ':', linei)
      if le <= 0: httpError("invalid headers")
      inc(linei, le)
      if line[linei] != ':': httpError("invalid headers")
      inc(linei) # Skip :

      result.headers.add(name, line[linei.. ^1].strip())
      if result.headers.len > headerLimit:
        httpError("too many headers")

  if not fullyRead:
    httpError("Connection was closed before full request has been made")

  if getBody:
    when client is HttpClient:
      client.bodyStream = newStringStream()
      result.bodyStream = client.bodyStream
      parseBody(client, result.headers, result.version)
    else:
      client.bodyStream = newFutureStream[string]("parseResponse")
      result.bodyStream = client.bodyStream
      assert(client.parseBodyFut.isNil or client.parseBodyFut.finished)
      client.parseBodyFut = parseBody(client, result.headers, result.version)
        # do not wait here for the body request to complete

proc newConnection(client: HttpClient | AsyncHttpClient,
                   url: Uri) {.multisync.} =
  if client.currentURL.hostname != url.hostname or
      client.currentURL.scheme != url.scheme or
      client.currentURL.port != url.port or
      (not client.connected):
    # Connect to proxy if specified
    let connectionUrl =
      if client.proxy.isNil: url else: client.proxy.url

    let isSsl = connectionUrl.scheme.toLowerAscii() == "https"

    if isSsl and not defined(ssl):
      raise newException(HttpRequestError,
        "SSL support is not available. Cannot connect over SSL. Compile with -d:ssl to enable.")

    if client.connected:
      client.close()
      client.connected = false

    # TODO: I should be able to write 'net.Port' here...
    let port =
      if connectionUrl.port == "":
        if isSsl:
          nativesockets.Port(443)
        else:
          nativesockets.Port(80)
      else: nativesockets.Port(connectionUrl.port.parseInt)

    when client is HttpClient:
      client.socket = await net.dial(connectionUrl.hostname, port)
    elif client is AsyncHttpClient:
      client.socket = await asyncnet.dial(connectionUrl.hostname, port)
    else: {.fatal: "Unsupported client type".}

    when defined(ssl):
      if isSsl:
        try:
          client.sslContext.wrapConnectedSocket(
            client.socket, handshakeAsClient, connectionUrl.hostname)
        except:
          client.socket.close()
          raise getCurrentException()

    # If need to CONNECT through proxy
    if url.scheme == "https" and not client.proxy.isNil:
      when defined(ssl):
        # Pass only host:port for CONNECT
        var connectUrl = initUri()
        connectUrl.hostname = url.hostname
        connectUrl.port = if url.port != "": url.port else: "443"

        let proxyHeaderString = generateHeaders(connectUrl, $HttpConnect, newHttpHeaders(), "", client.proxy)
        await client.socket.send(proxyHeaderString)
        let proxyResp = await parseResponse(client, false)

        if not proxyResp.status.startsWith("200"):
          raise newException(HttpRequestError,
                            "The proxy server rejected a CONNECT request, " &
                            "so a secure connection could not be established.")
        client.sslContext.wrapConnectedSocket(
          client.socket, handshakeAsClient, url.hostname)
      else:
        raise newException(HttpRequestError,
        "SSL support is not available. Cannot connect over SSL. Compile with -d:ssl to enable.")

    # May be connected through proxy but remember actual URL being accessed
    client.currentURL = url
    client.connected = true

proc override(fallback, override: HttpHeaders): HttpHeaders =
  # Right-biased map union for `HttpHeaders`
  if override.isNil:
    return fallback

  result = newHttpHeaders()
  # Copy by value
  result.table[] = fallback.table[]
  for k, vs in override.table:
    result[k] = vs

proc requestAux(client: HttpClient | AsyncHttpClient, url: string,
                httpMethod: string, body = "",
                headers: HttpHeaders = nil): Future[Response | AsyncResponse]
                {.multisync.} =
  # Helper that actually makes the request. Does not handle redirects.
  let requestUrl = parseUri(url)

  if requestUrl.scheme == "":
    raise newException(ValueError, "No uri scheme supplied.")

  when client is AsyncHttpClient:
    if not client.parseBodyFut.isNil:
      # let the current operation finish before making another request
      await client.parseBodyFut
      client.parseBodyFut = nil

  await newConnection(client, requestUrl)

  let effectiveHeaders = client.headers.override(headers)

  if not effectiveHeaders.hasKey("user-agent") and client.userAgent != "":
    effectiveHeaders["User-Agent"] = client.userAgent

  var headersString = generateHeaders(requestUrl, httpMethod,
                                      effectiveHeaders, body, client.proxy)

  await client.socket.send(headersString)
  if body != "":
    await client.socket.send(body)

  let getBody = httpMethod.toLowerAscii() notin ["head", "connect"] and
                client.getBody
  result = await parseResponse(client, getBody)

proc request*(client: HttpClient | AsyncHttpClient, url: string,
              httpMethod: string, body = "",
              headers: HttpHeaders = nil): Future[Response | AsyncResponse]
              {.multisync.} =
  ## Connects to the hostname specified by the URL and performs a request
  ## using the custom method string specified by ``httpMethod``.
  ##
  ## Connection will be kept alive. Further requests on the same ``client`` to
  ## the same hostname will not require a new connection to be made. The
  ## connection can be closed by using the ``close`` procedure.
  ##
  ## This procedure will follow redirects up to a maximum number of redirects
  ## specified in ``client.maxRedirects``.
  result = await client.requestAux(url, httpMethod, body, headers)

  var lastURL = url
  for i in 1..client.maxRedirects:
    if result.status.redirection():
      let redirectTo = getNewLocation(lastURL, result.headers)
      # Guarantee method for HTTP 307: see https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/307
      var meth = if result.status == "307": httpMethod else: "GET"
      result = await client.requestAux(redirectTo, meth, body, headers)
      lastURL = redirectTo


proc request*(client: HttpClient | AsyncHttpClient, url: string,
              httpMethod = HttpGET, body = "",
              headers: HttpHeaders = nil): Future[Response | AsyncResponse]
              {.multisync.} =
  ## Connects to the hostname specified by the URL and performs a request
  ## using the method specified.
  ##
  ## Connection will be kept alive. Further requests on the same ``client`` to
  ## the same hostname will not require a new connection to be made. The
  ## connection can be closed by using the ``close`` procedure.
  ##
  ## When a request is made to a different hostname, the current connection will
  ## be closed.
  result = await request(client, url, $httpMethod, body, headers)

proc responseContent(resp: Response | AsyncResponse): Future[string] {.multisync.} =
  ## Returns the content of a response as a string.
  ##
  ## A ``HttpRequestError`` will be raised if the server responds with a
  ## client error (status code 4xx) or a server error (status code 5xx).
  if resp.code.is4xx or resp.code.is5xx:
    raise newException(HttpRequestError, resp.status)
  else:
    return await resp.bodyStream.readAll()

proc head*(client: HttpClient | AsyncHttpClient,
          url: string): Future[Response | AsyncResponse] {.multisync.} =
  ## Connects to the hostname specified by the URL and performs a HEAD request.
  ##
  ## This procedure uses httpClient values such as ``client.maxRedirects``.
  result = await client.request(url, HttpHEAD)

proc get*(client: HttpClient | AsyncHttpClient,
          url: string): Future[Response | AsyncResponse] {.multisync.} =
  ## Connects to the hostname specified by the URL and performs a GET request.
  ##
  ## This procedure uses httpClient values such as ``client.maxRedirects``.
  result = await client.request(url, HttpGET)

proc getContent*(client: HttpClient | AsyncHttpClient,
                 url: string): Future[string] {.multisync.} =
  ## Connects to the hostname specified by the URL and returns the content of a GET request.
  let resp = await get(client, url)
  return await responseContent(resp)

proc delete*(client: HttpClient | AsyncHttpClient,
          url: string): Future[Response | AsyncResponse] {.multisync.} =
  ## Connects to the hostname specified by the URL and performs a DELETE request.
  ## This procedure uses httpClient values such as ``client.maxRedirects``.
  result = await client.request(url, HttpDELETE)

proc deleteContent*(client: HttpClient | AsyncHttpClient,
                 url: string): Future[string] {.multisync.} =
  ## Connects to the hostname specified by the URL and returns the content of a DELETE request.
  let resp = await delete(client, url)
  return await responseContent(resp)

proc makeRequestContent(body = "", multipart: MultipartData = nil): (string, HttpHeaders) =
  let (mpContentType, mpBody) = format(multipart)
  # TODO: Support FutureStream for `body` parameter.
  template withNewLine(x): untyped =
    if x.len > 0 and not x.endsWith("\c\L"):
      x & "\c\L"
    else:
      x
  var xb = mpBody.withNewLine() & body
  var headers = newHttpHeaders()
  if multipart != nil:
    headers["Content-Type"] = mpContentType
  headers["Content-Length"] = $len(xb)
  return (xb, headers)

proc post*(client: HttpClient | AsyncHttpClient, url: string, body = "",
           multipart: MultipartData = nil): Future[Response | AsyncResponse]
           {.multisync.} =
  ## Connects to the hostname specified by the URL and performs a POST request.
  ## This procedure uses httpClient values such as ``client.maxRedirects``.
  var (xb, headers) = makeRequestContent(body, multipart)
  result = await client.request(url, $HttpPOST, xb, headers)

proc postContent*(client: HttpClient | AsyncHttpClient, url: string,
                  body = "",
                  multipart: MultipartData = nil): Future[string]
                  {.multisync.} =
  ## Connects to the hostname specified by the URL and returns the content of a POST request.
  let resp = await post(client, url, body, multipart)
  return await responseContent(resp)

proc put*(client: HttpClient | AsyncHttpClient, url: string, body = "",
           multipart: MultipartData = nil): Future[Response | AsyncResponse]
           {.multisync.} =
  ## Connects to the hostname specified by the URL and performs a PUT request.
  ## This procedure uses httpClient values such as ``client.maxRedirects``.
  var (xb, headers) = makeRequestContent(body, multipart)
  result = await client.request(url, $HttpPUT, xb, headers)

proc putContent*(client: HttpClient | AsyncHttpClient, url: string,
                  body = "",
                  multipart: MultipartData = nil): Future[string]
                  {.multisync.} =
  ## Connects to the hostname specified by the URL andreturns the content of a PUT request.
  let resp = await put(client, url, body, multipart)
  return await responseContent(resp)

proc patch*(client: HttpClient | AsyncHttpClient, url: string, body = "",
           multipart: MultipartData = nil): Future[Response | AsyncResponse]
           {.multisync.} =
  ## Connects to the hostname specified by the URL and performs a PATCH request.
  ## This procedure uses httpClient values such as ``client.maxRedirects``.
  var (xb, headers) = makeRequestContent(body, multipart)
  result = await client.request(url, $HttpPATCH, xb, headers)

proc patchContent*(client: HttpClient | AsyncHttpClient, url: string,
                  body = "",
                  multipart: MultipartData = nil): Future[string]
                  {.multisync.} =
  ## Connects to the hostname specified by the URL and returns the content of a PATCH request.
  let resp = await patch(client, url, body, multipart)
  return await responseContent(resp)

proc downloadFile*(client: HttpClient, url: string, filename: string) =
  ## Downloads ``url`` and saves it to ``filename``.
  client.getBody = false
  defer:
    client.getBody = true
  let resp = client.get(url)

  client.bodyStream = newFileStream(filename, fmWrite)
  if client.bodyStream.isNil:
    fileError("Unable to open file")
  parseBody(client, resp.headers, resp.version)
  client.bodyStream.close()

  if resp.code.is4xx or resp.code.is5xx:
    raise newException(HttpRequestError, resp.status)

proc downloadFile*(client: AsyncHttpClient, url: string,
                   filename: string): Future[void] =
  proc downloadFileEx(client: AsyncHttpClient,
                      url, filename: string): Future[void] {.async.} =
    ## Downloads ``url`` and saves it to ``filename``.
    client.getBody = false
    let resp = await client.get(url)

    client.bodyStream = newFutureStream[string]("downloadFile")
    var file = openAsync(filename, fmWrite)
    # Let `parseBody` write response data into client.bodyStream in the
    # background.
    asyncCheck parseBody(client, resp.headers, resp.version)
    # The `writeFromStream` proc will complete once all the data in the
    # `bodyStream` has been written to the file.
    await file.writeFromStream(client.bodyStream)
    file.close()

    if resp.code.is4xx or resp.code.is5xx:
      raise newException(HttpRequestError, resp.status)

  result = newFuture[void]("downloadFile")
  try:
    result = downloadFileEx(client, url, filename)
  except Exception as exc:
    result.fail(exc)
  finally:
    result.addCallback(
      proc () = client.getBody = true
    )
