## - Fetch for the JavaScript target: https://developer.mozilla.org/docs/Web/API/Fetch_API
from asyncjs import PromiseJs
from httpcore import HttpMethod
export PromiseJs, HttpMethod

when not defined(js) and not defined(nimdoc):
  {.fatal: "Module jsfetch is designed to be used with the JavaScript backend.".}
when defined(nodejs):
  {.warning: "By design 'fetch()' is defined on the web browser, but may not be on NodeJS.".}

type
  FetchOptions* = ref object
    metod {.importc: "method".}: cstring
    body: cstring
    integrity: cstring
    referrer: cstring
    mode: cstring
    credentials: cstring
    cache: cstring
    redirect: cstring
    referrerPolicy: cstring
    keepalive: bool

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


template fetchMethodToCstring(metod: HttpMethod): cstring =
  ## Template that takes an `HttpMethod` and returns an *Uppercase* `cstring`,
  ## but *only* for the HTTP Methods that are supported by the fetch API.
  ## High performance and minimal code compared to just `$(HttpMethod)`.
  assert metod notin {HttpTrace, HttpOptions, HttpConnect}, "HTTP Method not supported by fetch API"
  case metod
  of HttpHead:   "HEAD".cstring
  of HttpGet:    "GET".cstring
  of HttpPost:   "POST".cstring
  of HttpPut:    "PUT".cstring
  of HttpDelete: "DELETE".cstring
  of HttpPatch:  "PATCH".cstring
  else:          "GET".cstring

template `$`(x: FetchCredentials): cstring =
  case x
  of fcInclude:    "include".cstring
  of fcSameOrigin: "same-origin".cstring
  of fcOmit:       "omit".cstring

template `$`(x: FetchModes): cstring =
  case x
  of fmCors:       "cors".cstring
  of fmNoCors:     "no-cors".cstring
  of fmSameOrigin: "same-origin".cstring

template `$`(x: FetchCaches): cstring =
  case x
  of fchDefault:    "default".cstring
  of fchNoStore:    "no-store".cstring
  of fchReload:     "reload".cstring
  of fchNoCache:    "no-cache".cstring
  of fchForceCache: "force-cache".cstring

template `$`(x: FetchRedirects): cstring =
  case x
  of frFollow: "follow".cstring
  of frError:  "error".cstring
  of frManual: "manual".cstring

template `$`(x: FetchReferrerPolicies): cstring =
  case x
  of frpNoReferrer:              "no-referrer".cstring
  of frpNoReferrerWhenDowngrade: "no-referrer-when-downgrade".cstring
  of frpOrigin:                  "origin".cstring
  of frpOriginWhenCrossOrigin:   "origin-when-cross-origin".cstring
  of frpUnsafeUrl:               "unsafe-url".cstring

func unsafeNewFetchOptions*(metod, body, mode, credentials, cache, referrerPolicy: cstring,
    keepalive: bool, redirect = "follow".cstring, referrer = "client".cstring, integrity = "".cstring): FetchOptions {.importcpp:
    "{method: #, body: #, mode: #, credentials: #, cache: #, referrerPolicy: #, keepalive: #, redirect: #, referrer: #, integrity: #}".}
  ## **Unsafe** `newfetchOptions`. Low-level proc, usage is discouraged, only for optimization purposes.

func newfetchOptions*(metod: HttpMethod, body: cstring,
    mode: FetchModes, credentials: FetchCredentials, cache: FetchCaches, referrerPolicy: FetchReferrerPolicies,
    keepalive: bool, redirect = frFollow, referrer = "client".cstring, integrity = "".cstring): FetchOptions =
  result = FetchOptions(metod: fetchMethodTocstring(metod), body: body, mode: $mode,
    credentials: $credentials, cache: $cache, referrerPolicy: $referrerPolicy,
    keepalive: keepalive, redirect: $redirect , referrer: referrer, integrity: integrity)

func fetch*(url: cstring): PromiseJs {.importcpp: "fetch(#)".}
  ## `fetch()` API, Simple GET only (generates `fetch(url)`).

func fetch*(url: cstring, options: FetchOptions): PromiseJs {.importcpp: "fetch(#, #)".}
  ## `fetch()` API, Simple GET only (generates `fetch(url, options)`).
