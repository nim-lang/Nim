## - Fetch for the JavaScript target: https://developer.mozilla.org/docs/Web/API/Fetch_API
when not defined(js):
  {.fatal: "Module jsfetch is designed to be used with the JavaScript backend.".}

import std/[asyncjs, jsffi, jsheaders, jsformdata]
from std/httpcore import HttpMethod

type
  FetchOptions* = ref object  ## Options for Fetch API.
    keepalive*: bool
    metod* {.importjs: "method".}: cstring
    body*, integrity*, referrer*, mode*, credentials*, cache*, redirect*, referrerPolicy*: cstring

  FetchModes* = enum  ## JavaScript Fetch API mode options.
    fmCors = "cors"
    fmNoCors = "no-cors"
    fmSameOrigin = "same-origin"

  FetchCredentials* = enum  ## JavaScript Fetch API Credential options.
    fcInclude = "include"
    fcSameOrigin = "same-origin"
    fcOmit = "omit"

  FetchCaches* = enum  ## https://developer.mozilla.org/docs/Web/API/Request/cache
    fchDefault = "default"
    fchNoStore = "no-store"
    fchReload = "reload"
    fchNoCache = "no-cache"
    fchForceCache = "force-cache"

  FetchRedirects* = enum  ## JavaScript Fetch API Redirects options.
    frFollow = "follow"
    frError = "error"
    frManual = "manual"

  FetchReferrerPolicies* = enum  ## JavaScript Fetch API Referrer Policy options.
    frpNoReferrer = "no-referrer"
    frpNoReferrerWhenDowngrade = "no-referrer-when-downgrade"
    frpOrigin = "origin"
    frpOriginWhenCrossOrigin = "origin-when-cross-origin"
    frpUnsafeUrl = "unsafe-url"

  Body* = ref object  ## https://developer.mozilla.org/en-US/docs/Web/API/Body
    bodyUsed*: bool

  Response* = ref object  ## https://developer.mozilla.org/en-US/docs/Web/API/Response
    bodyUsed*, ok*, redirected*: bool
    typ* {.importjs: "type".}: cstring
    url*, statusText*: cstring
    status*: cint
    headers*: Headers
    body*: Body


func newResponse*(body: cstring or FormData): Response {.importjs: "(new Response(#))".}
  ## Explicit constructor for a new `Response`. This does *not* call `fetch()`.

func clone*(self: Response): Response {.importjs: "#.$1()".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Response/clone

func error*(self: Response): Response {.importjs: "#.$1()".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Response/error

func redirect*(self: Response; url: cstring; status: 100..599): Response {.importjs: "#.$1(#, #)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Response/redirect

proc text*(self: Body): Future[cstring] {.importjs: "#.$1()".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Body/text

proc json*(self: Body): Future[JsObject] {.importjs: "#.$1()".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Body/json

proc formData*(self: Body): Future[FormData] {.importjs: "#.$1()".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Body/formData

proc unsafeNewFetchOptions*(metod, body, mode, credentials, cache, referrerPolicy: cstring,
    keepalive: bool, redirect = "follow".cstring, referrer = "client".cstring, integrity = "".cstring): FetchOptions {.importjs:
    "{method: #, body: #, mode: #, credentials: #, cache: #, referrerPolicy: #, keepalive: #, redirect: #, referrer: #, integrity: #}".}
  ## **Unsafe** `newfetchOptions`. Low-level proc for optimization.

func newfetchOptions*(metod: HttpMethod, body: cstring,
    mode: FetchModes, credentials: FetchCredentials, cache: FetchCaches, referrerPolicy: FetchReferrerPolicies,
    keepalive: bool, redirect = frFollow, referrer = "client".cstring, integrity = "".cstring): FetchOptions =
  ## Constructor for `FetchOptions`.
  result = FetchOptions(
    body: body, mode: $mode, credentials: $credentials, cache: $cache, referrerPolicy: $referrerPolicy,
    keepalive: keepalive, redirect: $redirect, referrer: referrer, integrity: integrity,
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

proc fetch*(url: cstring): Future[Response] {.importjs: "fetch(#)".}
  ## `fetch()` API, simple `GET` only, returns a `Response`.

proc fetch*(url: cstring, options: FetchOptions): Future[Response] {.importjs: "fetch(#, #)".}
  ## `fetch()` API that takes a `FetchOptions`, returns a `Response`.

func toCstring*(self: FetchOptions or Response or Body): cstring {.importjs: "JSON.stringify(#)".}

func `$`*(self: FetchOptions or Response or Body): string = $toCstring(self)


runnableExamples:
  import std/[httpcore, asyncjs, jsheaders, jsformdata]
  if defined(nimJsFetchTests):

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
      doAssert options0.keepalive == false
      doAssert options0.metod == "POST".cstring
      doAssert options0.body == """{"key": "value"}""".cstring
      doAssert options0.mode == "no-cors".cstring
      doAssert options0.credentials == "omit".cstring
      doAssert options0.cache == "no-cache".cstring
      doAssert options0.referrerPolicy == "no-referrer".cstring
      doAssert options0.redirect == "follow".cstring
      doAssert options0.referrer == "client".cstring
      doAssert options0.integrity == "".cstring

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
      doAssert options1.keepalive == false
      doAssert options1.metod == $HttpPost
      doAssert options1.body == """{"key": "value"}""".cstring
      doAssert options1.mode == $fmNoCors
      doAssert options1.credentials == $fcOmit
      doAssert options1.cache == $fchNoCache
      doAssert options1.referrerPolicy == $frpNoReferrer
      doAssert options1.redirect == $frFollow
      doAssert options1.referrer == "client".cstring
      doAssert options1.integrity == "".cstring

    block:
      let response: Response = newResponse(body = "-. .. --".cstring)
      doAssert response.clone() is Response
      let redirected: Response = response.redirect("http://nim-lang.org".cstring, 307)
      doAssert redirected.url == "http://nim-lang.org".cstring

    if not defined(nodejs):
      proc doFetch(): Future[Response] {.async.} =
        fetch "https://httpbin.org/get"

      proc example() {.async.} =
        let response: Response = await doFetch()
        doAssert response.ok
        doAssert response.status == 200.cint
        doAssert response.headers is Headers
        doAssert response.body is Body
        ## -d:nimExperimentalAsyncjsThen
        when defined(nimExperimentalAsyncjsThen):
          let contents: string = await response.body
            .then((data: cstring) => $data)

      discard example()
