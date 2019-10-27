## Fetch
## =====
##
## - Fetch wrapper for JavaScript target: https://developer.mozilla.org/docs/Web/API/Fetch_API
from asyncjs import PromiseJs
from httpcore import HttpMethod

when not defined(js) and not defined(nimdoc):
  {.fatal: "Module jsfetch is designed to be used with the JavaScript backend.".}

type
  fetchModes* = enum ## JavaScript Fetch API mode options.
    fmCors, fmNoCors, fmSameOrigin
  fetchCredentials* = enum ## JavaScript Fetch API Credential options.
    fcInclude, fcSameOrigin, fcOmit
  fetchCaches* = enum  ## https://developer.mozilla.org/docs/Web/API/Request/cache
    fchDefault, fchNoStore, fchReload, fchNoCache, fchForceCache
  fetchRedirects* = enum ## JavaScript Fetch API Redirects options.
    frFollow, frError, frManual
  fetchReferrerPolicies* = enum ## JavaScript Fetch API Referrer Policy options.
    frpNoReferrer, frpNoReferrerWhenDowngrade, frpOrigin, frpOriginWhenCrossOrigin, frpUnsafeUrl


proc fetch*(url: cstring, httpMethod = HttpGET, body = "".cstring,
  integrity = "".cstring, referrer = "client".cstring, mode = fmNoCors,
  credentials = fcInclude, cache = fchDefault, redirect = frFollow,
  referrerPolicy = frpOrigin, keepalive = false): PromiseJs {.importcpp: """(
  fetch(#, {
    method: ["HEAD", "GET", "POST", "PUT", "DELETE", "GET", "GET", "GET", "PATCH"][#],
    body: (# || undefined),
    integrity: (# || undefined),
    referrer: (# || undefined),
    mode: ["cors", "no-cors", "same-origin"][#],
    credentials: ["include", "same-origin", "omit"][#],
    cache: ["default", "no-store", "reload", "no-cache", "force-cache"][#],
    redirect: ["follow", "error", "manual"][#],
    referrerPolicy: ["no-referrer", "no-referrer-when-downgrade", "origin", "origin-when-cross-origin", "unsafe-url"][#],
    keepalive: #
  }))""".}
  ## https://developer.mozilla.org/docs/Web/API/Fetch_API
  ## Default arguments of the API are also default arguments on this proc.
  ## By default ``fetch`` is defined on the web browser, but not on NodeJS.
  ##
  ## .. code-block:: nim
  ##
  ##   assert fetch("http://nim-lang.org".cstring) is PromiseJs, "asyncjs.PromiseJs"
  ##   let myPromise = fetch("http://example.io".cstring, HttpPost, body = "some data".cstring)
  ##   var anotherPromise = fetch("http://example.io/debts".cstring, HttpDelete)
