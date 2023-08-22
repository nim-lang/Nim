## - Fetch for the JavaScript target: https://developer.mozilla.org/docs/Web/API/Fetch_API
when not defined(js):
  {.fatal: "Module jsfetch is designed to be used with the JavaScript backend.".}

import std/[asyncjs, jsformdata, jsheaders]
export jsformdata, jsheaders
from std/httpcore import HttpMethod
from std/jsffi import JsObject

type
  FetchOptions* = ref object of JsRoot  ## Options for Fetch API.
    keepalive*: bool
    metod* {.importjs: "method".}: cstring
    body*, integrity*, referrer*, mode*, credentials*, cache*, redirect*, referrerPolicy*: cstring
    headers*: Headers

  FetchModes* = enum  ## Mode options.
    fmCors = "cors"
    fmNoCors = "no-cors"
    fmSameOrigin = "same-origin"

  FetchCredentials* = enum  ## Credential options. See https://developer.mozilla.org/en-US/docs/Web/API/Request/credentials
    fcInclude = "include"
    fcSameOrigin = "same-origin"
    fcOmit = "omit"

  FetchCaches* = enum  ## https://developer.mozilla.org/docs/Web/API/Request/cache
    fchDefault = "default"
    fchNoStore = "no-store"
    fchReload = "reload"
    fchNoCache = "no-cache"
    fchForceCache = "force-cache"

  FetchRedirects* = enum  ## Redirects options.
    frFollow = "follow"
    frError = "error"
    frManual = "manual"

  FetchReferrerPolicies* = enum  ## Referrer Policy options.
    frpNoReferrer = "no-referrer"
    frpNoReferrerWhenDowngrade = "no-referrer-when-downgrade"
    frpOrigin = "origin"
    frpOriginWhenCrossOrigin = "origin-when-cross-origin"
    frpUnsafeUrl = "unsafe-url"

  Response* = ref object of JsRoot  ## https://developer.mozilla.org/en-US/docs/Web/API/Response
    bodyUsed*, ok*, redirected*: bool
    typ* {.importjs: "type".}: cstring
    url*, statusText*: cstring
    status*: cint
    headers*: Headers
    body*: cstring

  Request* = ref object of JsRoot  ## https://developer.mozilla.org/en-US/docs/Web/API/Request
    bodyUsed*, ok*, redirected*: bool
    typ* {.importjs: "type".}: cstring
    url*, statusText*: cstring
    status*: cint
    headers*: Headers
    body*: cstring

func newResponse*(body: cstring | FormData): Response {.importjs: "(new Response(#))".}
  ## Constructor for `Response`. This does *not* call `fetch()`. Same as `new Response()`.

func newRequest*(url: cstring): Request {.importjs: "(new Request(#))".}
  ## Constructor for `Request`. This does *not* call `fetch()`. Same as `new Request()`.

func newRequest*(url: cstring; fetchOptions: FetchOptions): Request {.importjs: "(new Request(#, #))".}
  ## Constructor for `Request` with `fetchOptions`. Same as `fetch(url, fetchOptions)`.

func clone*(self: Response | Request): Response {.importjs: "#.$1()".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Response/clone

proc text*(self: Response): Future[cstring] {.importjs: "#.$1()".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Response/text

proc json*(self: Response): Future[JsObject] {.importjs: "#.$1()".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Response/json

proc formData*(self: Response): Future[FormData] {.importjs: "#.$1()".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Response/formData

proc unsafeNewFetchOptions*(metod, body, mode, credentials, cache, referrerPolicy: cstring;
    keepalive: bool; redirect = "follow".cstring; referrer = "client".cstring; integrity = "".cstring; headers: Headers = newHeaders()): FetchOptions {.importjs:
    "{method: #, body: #, mode: #, credentials: #, cache: #, referrerPolicy: #, keepalive: #, redirect: #, referrer: #, integrity: #, headers: #}".}
  ## .. warning:: Unsafe `newfetchOptions`.

func newfetchOptions*(metod = HttpGet; body: cstring = nil;
    mode = fmCors; credentials = fcSameOrigin; cache = fchDefault; referrerPolicy = frpNoReferrerWhenDowngrade;
    keepalive = false; redirect = frFollow; referrer = "client".cstring; integrity = "".cstring,
    headers: Headers = newHeaders()): FetchOptions =
  ## Constructor for `FetchOptions`.
  result = FetchOptions(
    body: if metod notin {HttpHead, HttpGet}: body else: nil, 
    mode: cstring($mode), credentials: cstring($credentials), cache: cstring($cache), referrerPolicy: cstring($referrerPolicy),
    keepalive: keepalive, redirect: cstring($redirect), referrer: referrer, integrity: integrity, headers: headers,
    metod: (case metod
      of HttpHead:   "HEAD".cstring
      of HttpGet:    "GET".cstring
      of HttpPost:   "POST".cstring
      of HttpPut:    "PUT".cstring
      of HttpDelete: "DELETE".cstring
      of HttpPatch:  "PATCH".cstring
      else:          "GET".cstring
    )
  )

proc fetch*(url: cstring | Request): Future[Response] {.importjs: "$1(#)".}
  ## `fetch()` API, simple `GET` only, returns a `Future[Response]`.

proc fetch*(url: cstring | Request; options: FetchOptions): Future[Response] {.importjs: "$1(#, #)".}
  ## `fetch()` API that takes a `FetchOptions`, returns a `Future[Response]`.

func toCstring*(self: Request | Response | FetchOptions): cstring {.importjs: "JSON.stringify(#)".}

func `$`*(self: Request | Response | FetchOptions): string = $toCstring(self)


runnableExamples("-r:off"):
  import std/[asyncjs, jsconsole, jsformdata, jsheaders]
  from std/httpcore import HttpMethod
  from std/jsffi import JsObject
  from std/sugar import `=>`

  block:
    let options0: FetchOptions = unsafeNewFetchOptions(
      metod = "POST".cstring,
      body = """{"key": "value"}""".cstring,
      mode = "no-cors".cstring,
      credentials = "omit".cstring,
      cache = "no-cache".cstring,
      referrerPolicy = "no-referrer".cstring,
      keepalive = false,
      redirect = "follow".cstring,
      referrer = "client".cstring,
      integrity = "".cstring,
      headers = newHeaders()
    )
    assert options0.keepalive == false
    assert options0.metod == "POST".cstring
    assert options0.body == """{"key": "value"}""".cstring
    assert options0.mode == "no-cors".cstring
    assert options0.credentials == "omit".cstring
    assert options0.cache == "no-cache".cstring
    assert options0.referrerPolicy == "no-referrer".cstring
    assert options0.redirect == "follow".cstring
    assert options0.referrer == "client".cstring
    assert options0.integrity == "".cstring
    assert options0.headers.len == 0

  block:
    let options1: FetchOptions = newFetchOptions(
      metod =  HttpPost,
      body = """{"key": "value"}""".cstring,
      mode = fmNoCors,
      credentials = fcOmit,
      cache = fchNoCache,
      referrerPolicy = frpNoReferrer,
      keepalive = false,
      redirect = frFollow,
      referrer = "client".cstring,
      integrity = "".cstring,
      headers = newHeaders()
    )
    assert options1.keepalive == false
    assert options1.metod == $HttpPost
    assert options1.body == """{"key": "value"}""".cstring
    assert options1.mode == $fmNoCors
    assert options1.credentials == $fcOmit
    assert options1.cache == $fchNoCache
    assert options1.referrerPolicy == $frpNoReferrer
    assert options1.redirect == $frFollow
    assert options1.referrer == "client".cstring
    assert options1.integrity == "".cstring
    assert options1.headers.len == 0

  block:
    let response: Response = newResponse(body = "-. .. --".cstring)
    let request: Request = newRequest(url = "http://nim-lang.org".cstring)

  if not defined(nodejs):
    block:
      proc doFetch(): Future[Response] {.async.} =
        fetch "https://httpbin.org/get".cstring

      proc example() {.async.} =
        let response: Response = await doFetch()
        assert response.ok
        assert response.status == 200.cint
        assert response.headers is Headers
        assert response.body is cstring

      discard example()

    block:
      proc example2 {.async.} =
        await fetch("https://api.github.com/users/torvalds".cstring)
          .then((response: Response) => response.json())
          .then((json: JsObject) => console.log(json))
          .catch((err: Error) => console.log("Request Failed", err))

      discard example2()
