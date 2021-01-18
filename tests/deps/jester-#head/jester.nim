# Copyright (C) 2015 Dominik Picheta
# MIT License - Look at license.txt for details.
import net, strtabs, re, tables, os, strutils, uri,
       times, mimetypes, asyncnet, asyncdispatch, macros, md5,
       logging, httpcore, asyncfile, macrocache, json, options,
       strformat

import jester/private/[errorpages, utils]
import jester/[request, patterns]

from cgi import decodeData, decodeUrl, CgiError

export request
export strtabs
export tables
export httpcore
export MultiData
export HttpMethod
export asyncdispatch

export SameSite

when useHttpBeast:
  import httpbeast except Settings, Request
  import options
  from nativesockets import close
else:
  import asynchttpserver except Request

type
  MatchProc* = proc (request: Request): Future[ResponseData] {.gcsafe, closure.}
  MatchProcSync* = proc (request: Request): ResponseData{.gcsafe, closure.}

  Matcher = object
    case async: bool
    of false:
      syncProc: MatchProcSync
    of true:
      asyncProc: MatchProc

  ErrorProc* = proc (
    request: Request, error: RouteError
  ): Future[ResponseData] {.gcsafe, closure.}

  Jester* = object
    when not useHttpBeast:
      httpServer*: AsyncHttpServer
    settings: Settings
    matchers: seq[Matcher]
    errorHandlers: seq[ErrorProc]

  MatchType* = enum
    MRegex, MSpecial, MStatic

  RawHeaders* = seq[tuple[key, val: string]]
  ResponseData* = tuple[
    action: CallbackAction,
    code: HttpCode,
    headers: Option[RawHeaders],
    content: string,
    matched: bool
  ]

  CallbackAction* = enum
    TCActionNothing, TCActionSend, TCActionRaw, TCActionPass

  RouteErrorKind* = enum
    RouteException, RouteCode
  RouteError* = object
    case kind*: RouteErrorKind
    of RouteException:
      exc: ref Exception
    of RouteCode:
      data: ResponseData

const jesterVer = "0.4.3"

proc toStr(headers: Option[RawHeaders]): string =
  return $newHttpHeaders(headers.get(@({:})))

proc createHeaders(headers: RawHeaders): string =
  result = ""
  if headers.len > 0:
    for header in headers:
      let (key, value) = header
      result.add(key & ": " & value & "\c\L")

    result = result[0 .. ^3] # Strip trailing \c\L

proc createResponse(status: HttpCode, headers: RawHeaders): string =
  return "HTTP/1.1 " & $status & "\c\L" & createHeaders(headers) & "\c\L\c\L"

proc unsafeSend(request: Request, content: string) =
  when useHttpBeast:
    request.getNativeReq.unsafeSend(content)
  else:
    # TODO: This may cause issues if we send too fast.
    asyncCheck request.getNativeReq.client.send(content)

proc send(
  request: Request, code: HttpCode, headers: Option[RawHeaders], body: string
): Future[void] =
  when useHttpBeast:
    let h =
      if headers.isNone: ""
      else: headers.get().createHeaders
    request.getNativeReq.send(code, body, h)
    var fut = newFuture[void]()
    complete(fut)
    return fut
  else:
    return request.getNativeReq.respond(
      code, body, newHttpHeaders(headers.get(@({:})))
    )

proc statusContent(request: Request, status: HttpCode, content: string,
                   headers: Option[RawHeaders]): Future[void] =
  try:
    result = send(request, status, headers, content)
    when not defined(release):
      logging.debug("  $1 $2" % [$status, toStr(headers)])
  except:
    logging.error("Could not send response: $1" % osErrorMsg(osLastError()))

# TODO: Add support for proper Future Streams instead of this weird raw mode.
template enableRawMode* =
  # TODO: Use the effect system to make this implicit?
  result.action = TCActionRaw

proc send*(request: Request, content: string) =
  ## Sends ``content`` immediately to the client socket.
  ##
  ## Routes using this procedure must enable raw mode.
  unsafeSend(request, content)

proc sendHeaders*(request: Request, status: HttpCode,
                  headers: RawHeaders) =
  ## Sends ``status`` and ``headers`` to the client socket immediately.
  ## The user is then able to send the content immediately to the client on
  ## the fly through the use of ``response.client``.
  let headerData = createResponse(status, headers)
  try:
    request.send(headerData)
    logging.debug("  $1 $2" % [$status, $headers])
  except:
    logging.error("Could not send response: $1" % [osErrorMsg(osLastError())])

proc sendHeaders*(request: Request, status: HttpCode) =
  ## Sends ``status`` and ``Content-Type: text/html`` as the headers to the
  ## client socket immediately.
  let headers = @({"Content-Type": "text/html;charset=utf-8"})
  request.sendHeaders(status, headers)

proc sendHeaders*(request: Request) =
  ## Sends ``Http200`` and ``Content-Type: text/html`` as the headers to the
  ## client socket immediately.
  request.sendHeaders(Http200)

proc send*(request: Request, status: HttpCode, headers: RawHeaders,
           content: string) =
  ## Sends out a HTTP response comprising of the ``status``, ``headers`` and
  ## ``content`` specified.
  var headers = headers & @({"Content-Length": $content.len})
  request.sendHeaders(status, headers)
  request.send(content)

# TODO: Cannot capture 'paths: varargs[string]' here.
proc sendStaticIfExists(
  req: Request, paths: seq[string]
): Future[HttpCode] {.async.} =
  result = Http200
  for p in paths:
    if existsFile(p):

      var fp = getFilePermissions(p)
      if not fp.contains(fpOthersRead):
        return Http403

      let fileSize = getFileSize(p)
      let ext = p.splitFile.ext
      let mimetype = req.settings.mimes.getMimetype(
        if ext.len > 0: ext[1 .. ^1]
        else: ""
      )
      if fileSize < 10_000_000: # 10 mb
        var file = readFile(p)

        var hashed = getMD5(file)

        # If the user has a cached version of this file and it matches our
        # version, let them use it
        if req.headers.hasKey("If-None-Match") and req.headers["If-None-Match"] == hashed:
          await req.statusContent(Http304, "", none[RawHeaders]())
        else:
          await req.statusContent(Http200, file, some(@({
            "Content-Type": mimetype,
            "ETag": hashed
          })))
      else:
        let headers = @({
          "Content-Type": mimetype,
          "Content-Length": $fileSize
        })
        await req.statusContent(Http200, "", some(headers))

        var fileStream = newFutureStream[string]("sendStaticIfExists")
        var file = openAsync(p, fmRead)
        # Let `readToStream` write file data into fileStream in the
        # background.
        asyncCheck file.readToStream(fileStream)
        # The `writeFromStream` proc will complete once all the data in the
        # `bodyStream` has been written to the file.
        while true:
          let (hasValue, value) = await fileStream.read()
          if hasValue:
            req.unsafeSend(value)
          else:
            break
        file.close()

      return

  # If we get to here then no match could be found.
  return Http404

proc close*(request: Request) =
  ## Closes client socket connection.
  ##
  ## Routes using this procedure must enable raw mode.
  let nativeReq = request.getNativeReq()
  when useHttpBeast:
    nativeReq.forget()
  nativeReq.client.close()

proc defaultErrorFilter(error: RouteError): ResponseData =
  case error.kind
  of RouteException:
    let e = error.exc
    let traceback = getStackTrace(e)
    var errorMsg = e.msg
    if errorMsg.len == 0: errorMsg = "(empty)"

    let error = traceback & errorMsg
    logging.error(error)
    result.headers = some(@({
      "Content-Type": "text/html;charset=utf-8"
    }))
    result.content = routeException(
      error.replace("\n", "<br/>\n"),
      jesterVer
    )
    result.code = Http502
    result.matched = true
    result.action = TCActionSend
  of RouteCode:
    result.headers = some(@({
      "Content-Type": "text/html;charset=utf-8"
    }))
    result.content = error(
      $error.data.code,
      jesterVer
    )
    result.code = error.data.code
    result.matched = true
    result.action = TCActionSend

proc initRouteError(exc: ref Exception): RouteError =
  RouteError(
    kind: RouteException,
    exc: exc
  )

proc initRouteError(data: ResponseData): RouteError =
  RouteError(
    kind: RouteCode,
    data: data
  )

proc dispatchError(
  jes: Jester,
  request: Request,
  error: RouteError
): Future[ResponseData] {.async.} =
  for errorProc in jes.errorHandlers:
    let data = await errorProc(request, error)
    if data.matched:
      return data

  return defaultErrorFilter(error)

proc dispatch(
  self: Jester,
  req: Request
): Future[ResponseData] {.async.} =
  for matcher in self.matchers:
    if matcher.async:
      let data = await matcher.asyncProc(req)
      if data.matched:
        return data
    else:
      let data = matcher.syncProc(req)
      if data.matched:
        return data

proc handleFileRequest(
  jes: Jester, req: Request
): Future[ResponseData] {.async.} =
  # Find static file.
  # TODO: Caching.
  let path = normalizedPath(
    jes.settings.staticDir / cgi.decodeUrl(req.pathInfo)
  )

  # Verify that this isn't outside our static dir.
  var status = Http400
  let pathDir = path.splitFile.dir / ""
  let staticDir = jes.settings.staticDir / ""
  if pathDir.startsWith(staticDir):
    if existsDir(path):
      status = await sendStaticIfExists(
        req,
        @[path / "index.html", path / "index.htm"]
      )
    else:
      status = await sendStaticIfExists(req, @[path])

    # Http200 means that the data was sent so there is nothing else to do.
    if status == Http200:
      result[0] = TCActionRaw
      when not defined(release):
        logging.debug("  -> $1" % path)
      return

  return (TCActionSend, status, none[seq[(string, string)]](), "", true)

proc handleRequestSlow(
  jes: Jester,
  req: Request,
  respDataFut: Future[ResponseData] | ResponseData,
  dispatchedError: bool
): Future[void] {.async.} =
  var dispatchedError = dispatchedError
  var respData: ResponseData

  # httpReq.send(Http200, "Hello, World!", "")
  try:
    when respDataFut is Future[ResponseData]:
      respData = await respDataFut
    else:
      respData = respDataFut
  except:
    # Handle any errors by showing them in the browser.
    # TODO: Improve the look of this.
    let exc = getCurrentException()
    respData = await dispatchError(jes, req, initRouteError(exc))
    dispatchedError = true

  # TODO: Put this in a custom matcher?
  if not respData.matched:
    respData = await handleFileRequest(jes, req)

  case respData.action
  of TCActionSend:
    if (respData.code.is4xx or respData.code.is5xx) and
        not dispatchedError and respData.content.len == 0:
      respData = await dispatchError(jes, req, initRouteError(respData))

    await statusContent(
      req,
      respData.code,
      respData.content,
      respData.headers
    )
  else:
    when not defined(release):
      logging.debug("  $1" % [$respData.action])

  # Cannot close the client socket. AsyncHttpServer may be keeping it alive.

proc handleRequest(jes: Jester, httpReq: NativeRequest): Future[void] =
  var req = initRequest(httpReq, jes.settings)
  try:
    when not defined(release):
      logging.debug("$1 $2" % [$req.reqMethod, req.pathInfo])

    if likely(jes.matchers.len == 1 and not jes.matchers[0].async):
      let respData = jes.matchers[0].syncProc(req)
      if likely(respData.matched):
        return statusContent(
          req,
          respData.code,
          respData.content,
          respData.headers
        )
      else:
        return handleRequestSlow(jes, req, respData, false)
    else:
      return handleRequestSlow(jes, req, dispatch(jes, req), false)
  except:
    let exc = getCurrentException()
    let respDataFut = dispatchError(jes, req, initRouteError(exc))
    return handleRequestSlow(jes, req, respDataFut, true)

  assert(not result.isNil, "Expected handleRequest to return a valid future.")

proc newSettings*(
  port = Port(5000), staticDir = getCurrentDir() / "public",
  appName = "", bindAddr = "", reusePort = false,
  futureErrorHandler: proc (fut: Future[void]) {.closure, gcsafe.} = nil
): Settings =
  result = Settings(
    staticDir: staticDir,
    appName: appName,
    port: port,
    bindAddr: bindAddr,
    reusePort: reusePort,
    futureErrorHandler: futureErrorHandler
  )

proc register*(self: var Jester, matcher: MatchProc) =
  ## Adds the specified matcher procedure to the specified Jester instance.
  self.matchers.add(
    Matcher(
      async: true,
      asyncProc: matcher
    )
  )

proc register*(self: var Jester, matcher: MatchProcSync) =
  ## Adds the specified matcher procedure to the specified Jester instance.
  self.matchers.add(
    Matcher(
      async: false,
      syncProc: matcher
    )
  )

proc register*(self: var Jester, errorHandler: ErrorProc) =
  ## Adds the specified error handler procedure to the specified Jester instance.
  self.errorHandlers.add(errorHandler)

proc initJester*(
  settings: Settings = newSettings()
): Jester =
  result.settings = settings
  result.settings.mimes = newMimetypes()
  result.matchers = @[]
  result.errorHandlers = @[]

proc initJester*(
  matcher: MatchProc,
  settings: Settings = newSettings()
): Jester =
  result = initJester(settings)
  result.register(matcher)

proc initJester*(
  matcher: MatchProcSync, # TODO: Annoying nim bug: `MatchProc | MatchProcSync` doesn't work.
  settings: Settings = newSettings()
): Jester =
  result = initJester(settings)
  result.register(matcher)

proc serve*(
  self: var Jester
) =
  ## Creates a new async http server instance and registers
  ## it with the dispatcher.
  ##
  ## The event loop is executed by this function, so it will block forever.

  # Ensure we have at least one logger enabled, defaulting to console.
  if logging.getHandlers().len == 0:
    addHandler(logging.newConsoleLogger())
    setLogFilter(when defined(release): lvlInfo else: lvlDebug)

  if self.settings.bindAddr.len > 0:
    logging.info("Jester is making jokes at http://$1:$2$3" %
      [
        self.settings.bindAddr, $self.settings.port, self.settings.appName
      ]
    )
  else:
    when defined(windows):
      logging.info("Jester is making jokes at http://127.0.0.1:$1$2 (all interfaces)" %
                   [$self.settings.port, self.settings.appName])
    else:
      logging.info("Jester is making jokes at http://0.0.0.0:$1$2" %
                   [$self.settings.port, self.settings.appName])

  var jes = self
  when useHttpBeast:
    run(
      proc (req: httpbeast.Request): Future[void] =
         {.gcsafe.}:
          result = handleRequest(jes, req),
      httpbeast.initSettings(self.settings.port, self.settings.bindAddr)
    )
  else:
    self.httpServer = newAsyncHttpServer(reusePort=self.settings.reusePort)
    let serveFut = self.httpServer.serve(
      self.settings.port,
      proc (req: asynchttpserver.Request): Future[void] {.gcsafe, closure.} =
        result = handleRequest(jes, req),
      self.settings.bindAddr)
    if not self.settings.futureErrorHandler.isNil:
      serveFut.callback = self.settings.futureErrorHandler
    else:
      asyncCheck serveFut
    runForever()

template setHeader(headers: var Option[RawHeaders], key, value: string): typed =
  bind isNone
  if isNone(headers):
    headers = some(@({key: value}))
  else:
    block outer:
      # Overwrite key if it exists.
      var h = headers.get()
      for i in 0 ..< h.len:
        if h[i][0] == key:
          h[i][1] = value
          headers = some(h)
          break outer

      # Add key if it doesn't exist.
      headers = some(h & @({key: value}))

template resp*(code: HttpCode,
               headers: openarray[tuple[key, val: string]],
               content: string): typed =
  ## Sets ``(code, headers, content)`` as the response.
  bind TCActionSend
  result = (TCActionSend, code, none[RawHeaders](), content, true)
  for header in headers:
    setHeader(result[2], header[0], header[1])
  break route


template resp*(content: string, contentType = "text/html;charset=utf-8"): typed =
  ## Sets ``content`` as the response; ``Http200`` as the status code
  ## and ``contentType`` as the Content-Type.
  bind TCActionSend, newHttpHeaders, strtabs.`[]=`
  result[0] = TCActionSend
  result[1] = Http200
  setHeader(result[2], "Content-Type", contentType)
  result[3] = content
  # This will be set by our macro, so this is here for those not using it.
  result.matched = true
  break route

template resp*(content: JsonNode): typed =
  ## Serializes ``content`` as the response, sets ``Http200`` as status code
  ## and "application/json" Content-Type.
  resp($content, contentType="application/json")

template resp*(code: HttpCode, content: string,
               contentType = "text/html;charset=utf-8"): typed =
  ## Sets ``content`` as the response; ``code`` as the status code
  ## and ``contentType`` as the Content-Type.
  bind TCActionSend, newHttpHeaders
  result[0] = TCActionSend
  result[1] = code
  setHeader(result[2], "Content-Type", contentType)
  result[3] = content
  result.matched = true
  break route

template resp*(code: HttpCode): typed =
  ## Responds with the specified ``HttpCode``. This ensures that error handlers
  ## are called.
  bind TCActionSend, newHttpHeaders
  result[0] = TCActionSend
  result[1] = code
  result.matched = true
  break route

template redirect*(url: string): typed =
  ## Redirects to ``url``. Returns from this request handler immediately.
  ## Any set response headers are preserved for this request.
  bind TCActionSend, newHttpHeaders
  result[0] = TCActionSend
  result[1] = Http303
  setHeader(result[2], "Location", url)
  result[3] = ""
  result.matched = true
  break route

template pass*(): typed =
  ## Skips this request handler.
  ##
  ## If you want to stop this request from going further use ``halt``.
  result.action = TCActionPass
  break outerRoute

template cond*(condition: bool): typed =
  ## If ``condition`` is ``False`` then ``pass`` will be called,
  ## i.e. this request handler will be skipped.
  if not condition: break outerRoute

template halt*(code: HttpCode,
               headers: openarray[tuple[key, val: string]],
               content: string): typed =
  ## Immediately replies with the specified request. This means any further
  ## code will not be executed after calling this template in the current
  ## route.
  bind TCActionSend, newHttpHeaders
  result[0] = TCActionSend
  result[1] = code
  result[2] = some(@headers)
  result[3] = content
  result.matched = true
  break allRoutes

template halt*(): typed =
  ## Halts the execution of this request immediately. Returns a 404.
  ## All previously set values are **discarded**.
  halt(Http404, {"Content-Type": "text/html;charset=utf-8"}, error($Http404, jesterVer))

template halt*(code: HttpCode): typed =
  halt(code, {"Content-Type": "text/html;charset=utf-8"}, error($code, jesterVer))

template halt*(content: string): typed =
  halt(Http404, {"Content-Type": "text/html;charset=utf-8"}, content)

template halt*(code: HttpCode, content: string): typed =
  halt(code, {"Content-Type": "text/html;charset=utf-8"}, content)

template attachment*(filename = ""): typed =
  ## Instructs the browser that the response should be stored on disk
  ## rather than displayed in the browser.
  var disposition = "attachment"
  if filename != "":
    disposition.add("; filename=\"" & extractFilename(filename) & "\"")
    let ext = splitFile(filename).ext
    let contentTypeSet =
      isSome(result[2]) and result[2].get().toTable.hasKey("Content-Type")
    if not contentTypeSet and ext != "":
      setHeader(result[2], "Content-Type", getMimetype(request.settings.mimes, ext))
  setHeader(result[2], "Content-Disposition", disposition)

template sendFile*(filename: string): typed =
  ## Sends the file at the specified filename as the response.
  result[0] = TCActionRaw
  let sendFut = sendStaticIfExists(request, @[filename])
  yield sendFut
  let status = sendFut.read()
  if status != Http200:
    raise newException(JesterError, "Couldn't send requested file: " & filename)
  # This will be set by our macro, so this is here for those not using it.
  result.matched = true
  break route

template `@`*(s: string): untyped =
  ## Retrieves the parameter ``s`` from ``request.params``. ``""`` will be
  ## returned if parameter doesn't exist.
  if s in params(request):
    # TODO: Why does request.params not work? :(
    # TODO: This is some weird bug with macros/templates, I couldn't
    # TODO: reproduce it easily.
    params(request)[s]
  else:
    ""

proc setStaticDir*(request: Request, dir: string) =
  ## Sets the directory in which Jester will look for static files. It is
  ## ``./public`` by default.
  ##
  ## The files will be served like so:
  ##
  ## ./public/css/style.css ``->`` http://example.com/css/style.css
  ##
  ## (``./public`` is not included in the final URL)
  request.settings.staticDir = dir

proc getStaticDir*(request: Request): string =
  ## Gets the directory in which Jester will look for static files.
  ##
  ## ``./public`` by default.
  return request.settings.staticDir

proc makeUri*(request: Request, address = "", absolute = true,
              addScriptName = true): string =
  ## Creates a URI based on the current request. If ``absolute`` is true it will
  ## add the scheme (Usually 'http://'), `request.host` and `request.port`.
  ## If ``addScriptName`` is true `request.appName` will be prepended before
  ## ``address``.

  # Check if address already starts with scheme://
  var uri = parseUri(address)

  if uri.scheme != "": return address
  uri.path = "/"
  uri.query = ""
  uri.anchor = ""
  if absolute:
    uri.hostname = request.host
    uri.scheme = (if request.secure: "https" else: "http")
    if request.port != (if request.secure: 443 else: 80):
      uri.port = $request.port

  if addScriptName: uri = uri / request.appName
  if address != "":
    uri = uri / address
  else:
    uri = uri / request.pathInfo
  return $uri

template uri*(address = "", absolute = true, addScriptName = true): untyped =
  ## Convenience template which can be used in a route.
  request.makeUri(address, absolute, addScriptName)

proc daysForward*(days: int): DateTime =
  ## Returns a DateTime object referring to the current time plus ``days``.
  return getTime().utc + initTimeInterval(days = days)

template setCookie*(name, value: string, expires="",
                    sameSite: SameSite=Lax, secure = false,
                    httpOnly = false, domain = "", path = "") =
  ## Creates a cookie which stores ``value`` under ``name``.
  ##
  ## The SameSite argument determines the level of CSRF protection that
  ## you wish to adopt for this cookie. It's set to Lax by default which
  ## should protect you from most vulnerabilities. Note that this is only
  ## supported by some browsers:
  ## https://caniuse.com/#feat=same-site-cookie-attribute
  let newCookie = makeCookie(name, value, expires, domain, path, secure, httpOnly, sameSite)
  if isSome(result[2]) and
     (let headers = result[2].get(); headers.toTable.hasKey("Set-Cookie")):
    result[2] = some(headers & @({"Set-Cookie": newCookie}))
  else:
    setHeader(result[2], "Set-Cookie", newCookie)

template setCookie*(name, value: string, expires: DateTime,
                    sameSite: SameSite=Lax, secure = false,
                    httpOnly = false, domain = "", path = "") =
  ## Creates a cookie which stores ``value`` under ``name``.
  setCookie(name, value,
            format(expires.utc, "ddd',' dd MMM yyyy HH:mm:ss 'GMT'"),
            sameSite, secure, httpOnly, domain, path)

proc normalizeUri*(uri: string): string =
  ## Remove any trailing ``/``.
  if uri[uri.len-1] == '/': result = uri[0 .. uri.len-2]
  else: result = uri

# -- Macro

proc checkAction*(respData: var ResponseData): bool =
  case respData.action
  of TCActionSend, TCActionRaw:
    result = true
  of TCActionPass:
    result = false
  of TCActionNothing:
    raise newException(
      ValueError,
      "Missing route action, did you forget to use `resp` in your route?"
    )

proc skipDo(node: NimNode): NimNode {.compiletime.} =
  if node.kind == nnkDo:
    result = node[6]
  else:
    result = node

proc ctParsePattern(pattern, pathPrefix: string): NimNode {.compiletime.} =
  result = newNimNode(nnkPrefix)
  result.add newIdentNode("@")
  result.add newNimNode(nnkBracket)

  proc addPattNode(res: var NimNode, typ, text,
                   optional: NimNode) {.compiletime.} =
    var objConstr = newNimNode(nnkObjConstr)

    objConstr.add bindSym("Node")
    objConstr.add newNimNode(nnkExprColonExpr).add(
        newIdentNode("typ"), typ)
    objConstr.add newNimNode(nnkExprColonExpr).add(
        newIdentNode("text"), text)
    objConstr.add newNimNode(nnkExprColonExpr).add(
        newIdentNode("optional"), optional)

    res[1].add objConstr

  var patt = parsePattern(pattern)
  if pathPrefix.len > 0:
    result.addPattNode(
      bindSym("NodeText"), # Node kind
      newStrLitNode(pathPrefix), # Text
      newIdentNode("false") # Optional?
    )

  for node in patt:
    result.addPattNode(
      case node.typ
      of NodeText: bindSym("NodeText")
      of NodeField: bindSym("NodeField"),
      newStrLitNode(node.text),
      newIdentNode(if node.optional: "true" else: "false"))

template setDefaultResp*() =
  # TODO: bindSym this in the 'routes' macro and put it in each route
  bind TCActionNothing, newHttpHeaders
  result.action = TCActionNothing
  result.code = Http200
  result.content = ""

template declareSettings() {.dirty.} =
  when not declaredInScope(settings):
    var settings = newSettings()

proc createJesterPattern(
  routeNode, patternMatchSym: NimNode,
  pathPrefix: string
): NimNode {.compileTime.} =
  var ctPattern = ctParsePattern(routeNode[1].strVal, pathPrefix)
  # -> let <patternMatchSym> = <ctPattern>.match(request.path)
  return newLetStmt(patternMatchSym,
      newCall(bindSym"match", ctPattern, parseExpr("request.pathInfo")))

proc escapeRegex(s: string): string =
  result = ""
  for i in s:
    case i
    # https://stackoverflow.com/a/400316/492186
    of '.', '^', '$', '*', '+', '?', '(', ')', '[', '{', '\\', '|':
      result.add('\\')
      result.add(i)
    else:
      result.add(i)

proc createRegexPattern(
  routeNode, reMatchesSym, patternMatchSym: NimNode,
  pathPrefix: string
): NimNode {.compileTime.} =
  # -> let <patternMatchSym> = find(request.pathInfo, <pattern>, <reMatches>)
  var strNode = routeNode[1].copyNimTree()
  strNode[1].strVal = escapeRegex(pathPrefix) & strNode[1].strVal
  return newLetStmt(
    patternMatchSym,
    newCall(
      bindSym"find",
      parseExpr("request.pathInfo"),
      strNode,
      reMatchesSym
    )
  )

proc determinePatternType(pattern: NimNode): MatchType {.compileTime.} =
  case pattern.kind
  of nnkStrLit:
    var patt = parsePattern(pattern.strVal)
    if patt.len == 1 and patt[0].typ == NodeText:
      return MStatic
    else:
      return MSpecial
  of nnkCallStrLit:
    expectKind(pattern[0], nnkIdent)
    case ($pattern[0]).normalize
    of "re": return MRegex
    else:
      macros.error("Invalid pattern type: " & $pattern[0])
  else:
    macros.error("Unexpected node kind: " & $pattern.kind)

proc createCheckActionIf(): NimNode =
  var checkActionIf = parseExpr(
    "if checkAction(result): result.matched = true; break routesList"
  )
  checkActionIf[0][0][0] = bindSym"checkAction"
  return checkActionIf

proc createGlobalMetaRoute(routeNode, dest: NimNode) {.compileTime.} =
  ## Creates a ``before`` or ``after`` route with no pattern, i.e. one which
  ## will be always executed.

  # -> block route: <ifStmtBody>
  var innerBlockStmt = newStmtList(
    newNimNode(nnkBlockStmt).add(newIdentNode("route"), routeNode[1].skipDo())
  )

  # -> block outerRoute: <innerBlockStmt>
  var blockStmt = newNimNode(nnkBlockStmt).add(
    newIdentNode("outerRoute"), innerBlockStmt)
  dest.add blockStmt

proc createRoute(
  routeNode, dest: NimNode, pathPrefix: string, isMetaRoute: bool = false
) {.compileTime.} =
  ## Creates code which checks whether the current request path
  ## matches a route.
  ##
  ## The `isMetaRoute` parameter determines whether the route to be created is
  ## one of either a ``before`` or an ``after`` route.

  var patternMatchSym = genSym(nskLet, "patternMatchRet")

  # Only used for Regex patterns.
  var reMatchesSym = genSym(nskVar, "reMatches")
  var reMatches = parseExpr("var reMatches: array[20, string]")
  reMatches[0][0] = reMatchesSym
  reMatches[0][1][1] = bindSym("MaxSubpatterns")

  let patternType = determinePatternType(routeNode[1])
  case patternType
  of MStatic:
    discard
  of MSpecial:
    dest.add createJesterPattern(routeNode, patternMatchSym, pathPrefix)
  of MRegex:
    dest.add reMatches
    dest.add createRegexPattern(
      routeNode, reMatchesSym, patternMatchSym, pathPrefix
    )

  var ifStmtBody = newStmtList()
  case patternType
  of MStatic: discard
  of MSpecial:
    # -> setPatternParams(request, ret.params)
    ifStmtBody.add newCall(bindSym"setPatternParams", newIdentNode"request",
                           newDotExpr(patternMatchSym, newIdentNode"params"))
  of MRegex:
    # -> setReMatches(request, <reMatchesSym>)
    ifStmtBody.add newCall(bindSym"setReMatches", newIdentNode"request",
                           reMatchesSym)

  ifStmtBody.add routeNode[2].skipDo()

  let checkActionIf =
    if isMetaRoute:
      parseExpr("break routesList")
    else:
      createCheckActionIf()
  # -> block route: <ifStmtBody>; <checkActionIf>
  var innerBlockStmt = newStmtList(
    newNimNode(nnkBlockStmt).add(newIdentNode("route"), ifStmtBody),
    checkActionIf
  )

  let ifCond =
    case patternType
    of MStatic:
      infix(
        parseExpr("request.pathInfo"),
        "==",
        newStrLitNode(pathPrefix & routeNode[1].strVal)
      )
    of MSpecial:
      newDotExpr(patternMatchSym, newIdentNode("matched"))
    of MRegex:
      infix(patternMatchSym, "!=", newIntLitNode(-1))

  # -> if <patternMatchSym>.matched: <innerBlockStmt>
  var ifStmt = newIfStmt((ifCond, innerBlockStmt))

  # -> block outerRoute: <ifStmt>
  var blockStmt = newNimNode(nnkBlockStmt).add(
    newIdentNode("outerRoute"), ifStmt)
  dest.add blockStmt

proc createError(
  errorNode: NimNode,
  httpCodeBranches,
  exceptionBranches: var seq[tuple[cond, body: NimNode]]
) =
  if errorNode.len != 3:
    error("Missing error condition or body.", errorNode)

  let routeIdent = newIdentNode("route")
  let outerRouteIdent = newIdentNode("outerRoute")
  let checkActionIf = createCheckActionIf()
  let exceptionIdent = newIdentNode("exception")
  let errorIdent = newIdentNode("error") # TODO: Ugh. I shouldn't need these...
  let errorCond = errorNode[1]
  let errorBody = errorNode[2]
  let body = quote do:
    block `outerRouteIdent`:
      block `routeIdent`:
        `errorBody`
      `checkActionIf`

  case errorCond.kind
  of nnkIdent:
    let name = errorCond.strVal
    if name.len == 7 and name.startsWith("Http"):
      # HttpCode.
      httpCodeBranches.add(
        (
          infix(parseExpr("error.data.code"), "==", errorCond),
          body
        )
      )
    else:
      # Exception
      exceptionBranches.add(
        (
          infix(parseExpr("error.exc"), "of", errorCond),
          quote do:
            let `exceptionIdent` = (ref `errorCond`)(`errorIdent`.exc)
            `body`
        )
      )
  of nnkCurly:
    expectKind(errorCond[0], nnkInfix)
    httpCodeBranches.add(
      (
        infix(parseExpr("error.data.code"), "in", errorCond),
        body
      )
    )
  else:
    error("Expected exception type or set[HttpCode].", errorCond)

const definedRoutes = CacheTable"jester.routes"

proc processRoutesBody(
  body: NimNode,
  # For HTTP methods.
  caseStmtGetBody,
  caseStmtPostBody,
  caseStmtPutBody,
  caseStmtDeleteBody,
  caseStmtHeadBody,
  caseStmtOptionsBody,
  caseStmtTraceBody,
  caseStmtConnectBody,
  caseStmtPatchBody: var NimNode,
  # For `error`.
  httpCodeBranches,
  exceptionBranches: var seq[tuple[cond, body: NimNode]],
  # For before/after stmts.
  beforeStmts,
  afterStmts: var NimNode,
  # For other statements.
  outsideStmts: var NimNode,
  pathPrefix: string
) =
  for i in 0..<body.len:
    case body[i].kind
    of nnkCall:
      let cmdName = body[i][0].`$`.normalize
      case cmdName
      of "before":
        createGlobalMetaRoute(body[i], beforeStmts)
      of "after":
        createGlobalMetaRoute(body[i], afterStmts)
      else:
        outsideStmts.add(body[i])
    of nnkCommand:
      let cmdName = body[i][0].`$`.normalize
      case cmdName
      # HTTP Methods
      of "get":
        createRoute(body[i], caseStmtGetBody, pathPrefix)
      of "post":
        createRoute(body[i], caseStmtPostBody, pathPrefix)
      of "put":
        createRoute(body[i], caseStmtPutBody, pathPrefix)
      of "delete":
        createRoute(body[i], caseStmtDeleteBody, pathPrefix)
      of "head":
        createRoute(body[i], caseStmtHeadBody, pathPrefix)
      of "options":
        createRoute(body[i], caseStmtOptionsBody, pathPrefix)
      of "trace":
        createRoute(body[i], caseStmtTraceBody, pathPrefix)
      of "connect":
        createRoute(body[i], caseStmtConnectBody, pathPrefix)
      of "patch":
        createRoute(body[i], caseStmtPatchBody, pathPrefix)
      # Other
      of "error":
        createError(body[i], httpCodeBranches, exceptionBranches)
      of "before":
        createRoute(body[i], beforeStmts, pathPrefix, isMetaRoute=true)
      of "after":
        createRoute(body[i], afterStmts, pathPrefix, isMetaRoute=true)
      of "extend":
        # Extend another router.
        let extend = body[i]
        if extend[1].kind != nnkIdent:
          error("Expected identifier.", extend[1])

        let prefix =
          if extend.len > 1:
            extend[2].strVal
          else:
            ""
        if prefix.len != 0 and prefix[0] != '/':
          error("Path prefix for extended route must start with '/'", extend[2])

        processRoutesBody(
          definedRoutes[extend[1].strVal],
          caseStmtGetBody,
          caseStmtPostBody,
          caseStmtPutBody,
          caseStmtDeleteBody,
          caseStmtHeadBody,
          caseStmtOptionsBody,
          caseStmtTraceBody,
          caseStmtConnectBody,
          caseStmtPatchBody,
          httpCodeBranches,
          exceptionBranches,
          beforeStmts,
          afterStmts,
          outsideStmts,
          pathPrefix & prefix
        )
      else:
        outsideStmts.add(body[i])
    of nnkCommentStmt:
      discard
    of nnkPragma:
      if body[i][0].strVal.normalize notin ["async", "sync"]:
        outsideStmts.add(body[i])
    else:
      outsideStmts.add(body[i])

type
  NeedsAsync = enum
    ImplicitTrue, ImplicitFalse, ExplicitTrue, ExplicitFalse
proc needsAsync(node: NimNode): NeedsAsync =
  result = ImplicitFalse
  case node.kind
  of nnkCommand, nnkCall:
    if node[0].kind == nnkIdent:
      case node[0].strVal.normalize
      of "await", "sendfile":
        return ImplicitTrue
      of "resp", "halt", "attachment", "pass", "redirect", "cond", "get",
         "post", "patch", "delete":
        # This is just a simple heuristic. It's by no means meant to be
        # exhaustive.
        discard
      else:
        return ImplicitTrue
  of nnkYieldStmt:
    return ImplicitTrue
  of nnkPragma:
    if node[0].kind == nnkIdent:
      case node[0].strVal.normalize
      of "sync":
        return ExplicitFalse
      of "async":
        return ExplicitTrue
      else: discard
  else: discard

  for c in node:
    let r = needsAsync(c)
    if r in {ImplicitTrue, ExplicitTrue, ExplicitFalse}: return r

proc routesEx(name: string, body: NimNode): NimNode =
  # echo(treeRepr(body))
  # echo(treeRepr(name))

  # Save this route's body so that it can be incorporated into another route.
  definedRoutes[name] = body.copyNimTree

  result = newStmtList()

  # -> declareSettings()
  result.add newCall(bindSym"declareSettings")

  var outsideStmts = newStmtList()

  var matchBody = newNimNode(nnkStmtList)
  let setDefaultRespIdent = bindSym"setDefaultResp"
  matchBody.add newCall(setDefaultRespIdent)
  # TODO: This diminishes the performance. Would be nice to only include it
  # TODO: when setPatternParams or setReMatches is used.
  matchBody.add parseExpr("var request = request")

  # HTTP router case statement nodes:
  var caseStmt = newNimNode(nnkCaseStmt)
  caseStmt.add parseExpr("request.reqMethod")

  var caseStmtGetBody = newNimNode(nnkStmtList)
  var caseStmtPostBody = newNimNode(nnkStmtList)
  var caseStmtPutBody = newNimNode(nnkStmtList)
  var caseStmtDeleteBody = newNimNode(nnkStmtList)
  var caseStmtHeadBody = newNimNode(nnkStmtList)
  var caseStmtOptionsBody = newNimNode(nnkStmtList)
  var caseStmtTraceBody = newNimNode(nnkStmtList)
  var caseStmtConnectBody = newNimNode(nnkStmtList)
  var caseStmtPatchBody = newNimNode(nnkStmtList)

  # Error handler nodes:
  var httpCodeBranches: seq[tuple[cond, body: NimNode]] = @[]
  var exceptionBranches: seq[tuple[cond, body: NimNode]] = @[]

  # Before/After nodes:
  var beforeRoutes = newStmtList()
  var afterRoutes = newStmtList()

  processRoutesBody(
    body,
    caseStmtGetBody,
    caseStmtPostBody,
    caseStmtPutBody,
    caseStmtDeleteBody,
    caseStmtHeadBody,
    caseStmtOptionsBody,
    caseStmtTraceBody,
    caseStmtConnectBody,
    caseStmtPatchBody,
    httpCodeBranches,
    exceptionBranches,
    beforeRoutes,
    afterRoutes,
    outsideStmts,
    ""
  )

  var ofBranchGet = newNimNode(nnkOfBranch)
  ofBranchGet.add newIdentNode("HttpGet")
  ofBranchGet.add caseStmtGetBody
  caseStmt.add ofBranchGet

  var ofBranchPost = newNimNode(nnkOfBranch)
  ofBranchPost.add newIdentNode("HttpPost")
  ofBranchPost.add caseStmtPostBody
  caseStmt.add ofBranchPost

  var ofBranchPut = newNimNode(nnkOfBranch)
  ofBranchPut.add newIdentNode("HttpPut")
  ofBranchPut.add caseStmtPutBody
  caseStmt.add ofBranchPut

  var ofBranchDelete = newNimNode(nnkOfBranch)
  ofBranchDelete.add newIdentNode("HttpDelete")
  ofBranchDelete.add caseStmtDeleteBody
  caseStmt.add ofBranchDelete

  var ofBranchHead = newNimNode(nnkOfBranch)
  ofBranchHead.add newIdentNode("HttpHead")
  ofBranchHead.add caseStmtHeadBody
  caseStmt.add ofBranchHead

  var ofBranchOptions = newNimNode(nnkOfBranch)
  ofBranchOptions.add newIdentNode("HttpOptions")
  ofBranchOptions.add caseStmtOptionsBody
  caseStmt.add ofBranchOptions

  var ofBranchTrace = newNimNode(nnkOfBranch)
  ofBranchTrace.add newIdentNode("HttpTrace")
  ofBranchTrace.add caseStmtTraceBody
  caseStmt.add ofBranchTrace

  var ofBranchConnect = newNimNode(nnkOfBranch)
  ofBranchConnect.add newIdentNode("HttpConnect")
  ofBranchConnect.add caseStmtConnectBody
  caseStmt.add ofBranchConnect

  var ofBranchPatch = newNimNode(nnkOfBranch)
  ofBranchPatch.add newIdentNode("HttpPatch")
  ofBranchPatch.add caseStmtPatchBody
  caseStmt.add ofBranchPatch

  # Wrap the routes inside ``routesList`` blocks accordingly, and add them to
  # the `match` procedure body.
  let routesListIdent = newIdentNode("routesList")
  matchBody.add(
    quote do:
      block `routesListIdent`:
        `beforeRoutes`
  )

  matchBody.add(
    quote do:
      block `routesListIdent`:
        `caseStmt`
  )

  matchBody.add(
    quote do:
      block `routesListIdent`:
        `afterRoutes`
  )

  let matchIdent = newIdentNode(name)
  let reqIdent = newIdentNode("request")
  let needsAsync = needsAsync(body)
  case needsAsync
  of ImplicitFalse, ExplicitFalse:
    hint(fmt"Synchronous route `{name}` has been optimised. Use `{{.async.}}` to change.")
  of ImplicitTrue, ExplicitTrue:
    hint(fmt"Asynchronous route: {name}.")
  var matchProc =
    if needsAsync in {ImplicitTrue, ExplicitTrue}:
      quote do:
        proc `matchIdent`(
          `reqIdent`: Request
        ): Future[ResponseData] {.async, gcsafe.} =
          discard
    else:
      quote do:
        proc `matchIdent`(
          `reqIdent`: Request
        ): ResponseData {.gcsafe.} =
          discard

  # The following `block` is for `halt`. (`return` didn't work :/)
  let allRoutesBlock = newTree(
    nnkBlockStmt,
    newIdentNode("allRoutes"),
    matchBody
  )
  matchProc[6] = newTree(nnkStmtList, allRoutesBlock)
  result.add(outsideStmts)
  result.add(matchProc)

  # Error handler proc
  let errorHandlerIdent = newIdentNode(name & "ErrorHandler")
  let errorIdent = newIdentNode("error")
  let exceptionIdent = newIdentNode("exception")
  let resultIdent = newIdentNode("result")
  var errorHandlerProc = quote do:
    proc `errorHandlerIdent`(
      `reqIdent`: Request, `errorIdent`: RouteError
    ): Future[ResponseData] {.gcsafe, async.} =
      block `routesListIdent`:
        `setDefaultRespIdent`()
        case `errorIdent`.kind
        of RouteException:
          discard
        of RouteCode:
          discard
  if exceptionBranches.len != 0:
    var stmts = newStmtList()
    for branch in exceptionBranches:
      stmts.add(newIfStmt(branch))
    errorHandlerProc[6][0][1][^1][1][1][0] = stmts
  if httpCodeBranches.len != 0:
    var stmts = newStmtList()
    for branch in httpCodeBranches:
      stmts.add(newIfStmt(branch))
    errorHandlerProc[6][0][1][^1][2][1][0] = stmts
  result.add(errorHandlerProc)

  # TODO: Replace `body`, `headers`, `code` in routes with `result[i]` to
  # get these shortcuts back without sacrificing usability.
  # TODO2: Make sure you replace what `guessAction` used to do for this.

  # echo toStrLit(result)
  # echo treeRepr(result)

macro routes*(body: untyped) =
  result = routesEx("match", body)
  let jesIdent = genSym(nskVar, "jes")
  let matchIdent = newIdentNode("match")
  let errorHandlerIdent = newIdentNode("matchErrorHandler")
  let settingsIdent = newIdentNode("settings")
  result.add(
    quote do:
      var `jesIdent` = initJester(`matchIdent`, `settingsIdent`)
      `jesIdent`.register(`errorHandlerIdent`)
  )
  result.add(
    quote do:
      serve(`jesIdent`)
  )

macro router*(name: untyped, body: untyped) =
  if name.kind != nnkIdent:
    error("Need an ident.", name)

  routesEx(strVal(name), body)

macro settings*(body: untyped) =
  #echo(treeRepr(body))
  expectKind(body, nnkStmtList)

  result = newStmtList()

  # var settings = newSettings()
  let settingsIdent = newIdentNode("settings")
  result.add newVarStmt(settingsIdent, newCall("newSettings"))

  for asgn in body.children:
    expectKind(asgn, nnkAsgn)
    result.add newAssignment(newDotExpr(settingsIdent, asgn[0]), asgn[1])
