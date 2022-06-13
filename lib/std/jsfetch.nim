## - Fetch for the JavaScript target: https://developer.mozilla.org/docs/Web/API/Fetch_API
## .. Note:: jsfetch is Experimental.
when not defined(js):
  {.fatal: "Module jsfetch is designed to be used with the JavaScript backend.".}

import std/[asyncjs, jsheaders, jsformdata]
from std/httpcore import HttpMethod
from std/jsffi import JsObject

type
  FetchOptions* = ref object of JsRoot  ## Options for Fetch API.
    keepalive*: bool
    metod* {.importjs: "method".}: cstring
    body*, integrity*, referrer*, mode*, credentials*, cache*, redirect*, referrerPolicy*: cstring

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

  Body* = ref object of JsRoot  ## https://developer.mozilla.org/en-US/docs/Web/API/Body
    bodyUsed*: bool

  Response* = ref object of JsRoot  ## https://developer.mozilla.org/en-US/docs/Web/API/Response
    bodyUsed*, ok*, redirected*: bool
    typ* {.importjs: "type".}: cstring
    url*, statusText*: cstring
    status*: cint
    headers*: Headers
    body*: Body

  Request* = ref object of JsRoot  ## https://developer.mozilla.org/en-US/docs/Web/API/Request
    bodyUsed*, ok*, redirected*: bool
    typ* {.importjs: "type".}: cstring
    url*, statusText*: cstring
    status*: cint
    headers*: Headers
    body*: Body


func newResponse*(body: cstring | FormData): Response {.importjs: "(new Response(#))".}
  ## Constructor for `Response`. This does *not* call `fetch()`. Same as `new Response()`.

func newRequest*(url: cstring): Request {.importjs: "(new Request(#))".}
  ## Constructor for `Request`. This does *not* call `fetch()`. Same as `new Request()`.

func clone*(self: Response | Request): Response {.importjs: "#.$1()".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Response/clone

proc text*(self: Response): Future[cstring] {.importjs: "#.$1()".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Body/text

proc json*(self: Response): Future[JsObject] {.importjs: "#.$1()".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Body/json

proc formData*(self: Body): Future[FormData] {.importjs: "#.$1()".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Body/formData

proc unsafeNewFetchOptions*(metod, body, mode, credentials, cache, referrerPolicy: cstring;
    keepalive: bool; redirect = "follow".cstring; referrer = "client".cstring; integrity = "".cstring): FetchOptions {.importjs:
    "{method: #, body: #, mode: #, credentials: #, cache: #, referrerPolicy: #, keepalive: #, redirect: #, referrer: #, integrity: #}".}
  ## .. warning:: Unsafe `newfetchOptions`.

func newfetchOptions*(metod: HttpMethod; body: cstring;
    mode: FetchModes; credentials: FetchCredentials; cache: FetchCaches; referrerPolicy: FetchReferrerPolicies;
    keepalive: bool; redirect = frFollow; referrer = "client".cstring; integrity = "".cstring): FetchOptions =
  ## Constructor for `FetchOptions`.
  result = FetchOptions(
    body: if metod notin {HttpHead, HttpGet}: body else: nil,
    mode: cstring($mode), credentials: cstring($credentials), cache: cstring($cache), referrerPolicy: cstring($referrerPolicy),
    keepalive: keepalive, redirect: cstring($redirect), referrer: referrer, integrity: integrity,
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

func toCstring*(self: Request | Response | Body | FetchOptions): cstring {.importjs: "JSON.stringify(#)".}

func `$`*(self: Request | Response | Body | FetchOptions): string = $toCstring(self)


runnableExamples("-r:off"):
  import std/[asyncjs, jsconsole, jsheaders, jsformdata]
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
      integrity = "".cstring
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
      integrity = "".cstring
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
        assert response.body is Body

      discard example()

    when defined(nimExperimentalAsyncjsThen):
      block:
        proc example2 {.async.} =
          await fetch("https://api.github.com/users/torvalds".cstring)
            .then((response: Response) => response.json())
            .then((json: JsObject) => console.log(json))
            .catch((err: Error) => console.log("Request Failed", err))

        discard example2()
