## - Fetch for the JavaScript target: https://developer.mozilla.org/docs/Web/API/Fetch_API
from asyncjs import PromiseJs
from httpcore import HttpMethod
export PromiseJs, HttpMethod

when not defined(js) and not defined(nimdoc):
  {.fatal: "Module jsfetch is designed to be used with the JavaScript backend.".}
when defined(nodejs):
  {.warning: "By design 'fetch()' is defined on the web browser, but may not be on NodeJS.".}

template method2cstring(metod: HttpMethod): cstring =
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

func fetch*(url: cstring): PromiseJs {.importcpp: "fetch(#)".}
  ## `fetch()` API, Simple GET only (generates `fetch(url)`).
  ##
  ## .. code-block:: nim
  ##   doAssert fetch("https://nim-lang.org") is PromiseJs

func fetch*(url: cstring, httpMethod: static[HttpMethod], body: cstring): PromiseJs {.asmNoStackFrame.} =
  ## `fetch()` API, for any HTTP Method (static overload for optimization).
  ##
  ## .. code-block:: nim
  ##   doAssert fetch("https://my.api.org", HttpPost, "body") is PromiseJs
  # See the generated code if you dont understand why this overload exists.
  assert url.len > 0, "url must not be empty string"
  const x: cstring = method2cstring(httpMethod)
  {.emit: """return fetch(`url`, {method: "`x`", body: `body`});""".}

func fetch*(url: cstring, httpMethod: HttpMethod, body: cstring): PromiseJs {.asmNoStackFrame.} =
  ## .. code-block:: nim
  ##   let mthd = HttpPost
  ##   doAssert fetch("https://my.api.org", mthd, "body") is PromiseJs
  # See the generated code if you dont understand why this overload exists.
  assert url.len > 0, "url must not be empty string"
  let x: cstring = method2cstring(httpMethod)
  {.emit: """return fetch(`url`, {method: `x`, body: `body`});""".}

func fetch*(url: cstring, httpMethod: HttpMethod, body, mode, cache, redirect,
    credentials, referrerPolicy: cstring, keepalive = false, integrity = "".cstring,
    referrer = "client".cstring): PromiseJs {.asmNoStackFrame.} =
  ## `fetch()` API, for any HTTP Method, overload with all arguments supported by fetch API.
  # For Code Reviewers: Why dont use "Enum" for argument flags instead?.
  # Because this is *Low-Level* API,a jshttpclient may stand on top,with Enums,Types,etc
  # See the generated code if you dont understand why this overload exists.
  assert url.len > 0, "url must not be empty string"
  assert referrer.len > 0, "referrer must not be empty string"
  assert redirect in ["follow".cstring, "error".cstring, "manual".cstring]
  assert mode in ["cors".cstring, "no-cors".cstring, "same-origin".cstring]
  assert credentials in ["include".cstring, "same-origin".cstring, "omit".cstring]
  assert cache in ["no-store".cstring, "reload".cstring, "default".cstring, "no-cache".cstring, "force-cache".cstring]
  assert referrerPolicy in ["no-referrer".cstring, "no-referrer-when-downgrade".cstring,
    "origin".cstring, "origin-when-cross-origin".cstring, "unsafe-url".cstring]
  let x: cstring = method2cstring(httpMethod)
  {.emit: """return fetch(`url`, {
      method:         `x`,
      body:           `body`,
      integrity:      (`integrity` || undefined),
      referrer:       `referrer`,
      mode:           `mode`,
      credentials:    `credentials`,
      cache:          `cache`,
      redirect:       `redirect`,
      referrerPolicy: `referrerPolicy`,
      keepalive:      `keepalive`
    });
  """.}
