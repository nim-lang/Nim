## - Fetch for the JavaScript target: https://developer.mozilla.org/docs/Web/API/Fetch_API
from httpcore import HttpMethod
export HttpMethod

when not defined(js) and not defined(nimdoc):
  {.fatal: "Module jsfetch is designed to be used with the JavaScript backend.".}
when defined(nodejs):
  {.warning: "By design Fetch is defined on the web browser, but may not be on NodeJS.".}


type
  FetchOptions* = ref object    ## Options for Fetch API.
    keepalive: bool
    metod {.importc: "method".}: cstring
    body, integrity, referrer, mode, credentials, cache, redirect, referrerPolicy: cstring

  FetchModes* = enum            ## JavaScript Fetch API mode options.
    fmCors = "cors".cstring
    fmNoCors = "no-cors".cstring
    fmSameOrigin = "same-origin".cstring

  FetchCredentials* = enum      ## JavaScript Fetch API Credential options.
    fcInclude = "include".cstring
    fcSameOrigin = "same-origin".cstring
    fcOmit = "omit".cstring

  FetchCaches* = enum           ## https://developer.mozilla.org/docs/Web/API/Request/cache
    fchDefault = "default".cstring
    fchNoStore = "no-store".cstring
    fchReload = "reload".cstring
    fchNoCache = "no-cache".cstring
    fchForceCache = "force-cache".cstring

  FetchRedirects* = enum        ## JavaScript Fetch API Redirects options.
    frFollow = "follow".cstring
    frError = "error".cstring
    frManual = "manual".cstring

  FetchReferrerPolicies* = enum ## JavaScript Fetch API Referrer Policy options.
    frpNoReferrer = "no-referrer".cstring
    frpNoReferrerWhenDowngrade = "no-referrer-when-downgrade".cstring
    frpOrigin = "origin".cstring
    frpOriginWhenCrossOrigin = "origin-when-cross-origin".cstring
    frpUnsafeUrl = "unsafe-url".cstring

  Headers* = ref object   ## https://developer.mozilla.org/en-US/docs/Web/API/Headers

  Response* = ref object  ## Response for Fetch API.
    myBodyUsed, ok, redirected: bool
    tipe {.importc: "type".}: cstring
    url, statusText: cstring
    status: cushort
    headers: Headers


func newHeaders*(): Headers {.importcpp: "new Headers()".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers

func append*(this: Headers; name: cstring; value: cstring) {.importcpp: "#.append(#, #)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/append

func delete*(this: Headers; name: cstring) {.importcpp: "#.delete(#)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/delete

func get*(this: Headers; name: cstring): cstring {.importcpp: "#.get(#)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/get

func has*(this: Headers; name: cstring): bool {.importcpp: "#.has(#)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/has

func set*(this: Headers; name: cstring; value: cstring) {.importcpp: "#.set(#, #)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/set

func keys*(this: Headers): seq[cstring] {.importcpp: "Array.from(#.keys())".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/keys

func values*(this: Headers): seq[cstring] {.importcpp: "Array.from(#.values())".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/values

func entries*(this: Headers): seq[array[2, cstring]] {.importcpp: "Array.from(#.entries())".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/entries

template fetchMethodToCstring(metod: HttpMethod): cstring =
  ## Template that takes an `HttpMethod` and returns an *Uppercase* `cstring`,
  ## but *only* for the HTTP Methods that are supported by the fetch API.
  ## High performance and minimal code compared to just `$(HttpMethod)`.
  assert metod notin {HttpTrace, HttpOptions, HttpConnect}, "HTTP Method not supported by Fetch API"
  case metod
  of HttpHead:   "HEAD".cstring
  of HttpGet:    "GET".cstring
  of HttpPost:   "POST".cstring
  of HttpPut:    "PUT".cstring
  of HttpDelete: "DELETE".cstring
  of HttpPatch:  "PATCH".cstring
  else:          "GET".cstring

func unsafeNewFetchOptions*(metod, body, mode, credentials, cache, referrerPolicy: cstring,
    keepalive: bool, redirect = "follow".cstring, referrer = "client".cstring, integrity = "".cstring): FetchOptions {.importcpp:
    "{method: #, body: #, mode: #, credentials: #, cache: #, referrerPolicy: #, keepalive: #, redirect: #, referrer: #, integrity: #}".}
  ## **Unsafe** `newfetchOptions`. Low-level proc for optimization.

func newfetchOptions*(metod: HttpMethod, body: cstring,
    mode: FetchModes, credentials: FetchCredentials, cache: FetchCaches, referrerPolicy: FetchReferrerPolicies,
    keepalive: bool, redirect = frFollow, referrer = "client".cstring, integrity = "".cstring): FetchOptions =
  ## Constructor for `FetchOptions`.
  result = FetchOptions(metod: fetchMethodTocstring(metod), body: body, mode: $mode,
    credentials: $credentials, cache: $cache, referrerPolicy: $referrerPolicy,
    keepalive: keepalive, redirect: $redirect , referrer: referrer, integrity: integrity)

func fetchToCstring*(url: cstring): cstring {.importcpp: "await fetch(#).then(response => response.text()).then(text => text)".}
  ## Convenience proc for `fetch()` API that returns a `cstring` directly.

func fetchToCstring*(url: cstring, options: FetchOptions): cstring {.importcpp: "await fetch(#, #).then(response => response.text()).then(text => text)".}
  ## Convenience proc for `fetch()` API that returns a `cstring` directly.

func fetch*(url: cstring): Response {.importcpp: "await fetch(#).then(response => response)".}
  ## `fetch()` API, simple `GET` only, returns a `Response`.

func fetch*(url: cstring, options: FetchOptions): Response {.importcpp: "await fetch(#, #).then(response => response)".}
  ## `fetch()` API that takes a `FetchOptions`, returns a `Response`.
