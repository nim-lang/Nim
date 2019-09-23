#
#
#            Nim's Runtime Library
#        (c) Copyright 2016 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Contains functionality shared between the ``httpclient`` and
## ``asynchttpserver`` modules.

import tables, strutils, parseutils

type
  HeadersImpl = TableRef[string, seq[string]]
  HttpHeaders* = distinct HeadersImpl

  HttpHeaderValues* = distinct seq[string]

  # The range starts at '0' so that we don't have to explicitly initialise
  # it. See: http://irclogs.nim-lang.org/19-09-2016.html#19:48:27 for context.
  HttpCode* = distinct range[0 .. 599]

  HttpVersion* = enum
    HttpVer11,
    HttpVer10

  HttpMethod* = enum  ## the requested HttpMethod
    HttpHead,         ## Asks for the response identical to the one that would
                      ## correspond to a GET request, but without the response
                      ## body.
    HttpGet,          ## Retrieves the specified resource.
    HttpPost,         ## Submits data to be processed to the identified
                      ## resource. The data is included in the body of the
                      ## request.
    HttpPut,          ## Uploads a representation of the specified resource.
    HttpDelete,       ## Deletes the specified resource.
    HttpTrace,        ## Echoes back the received request, so that a client
                      ## can see what intermediate servers are adding or
                      ## changing in the request.
    HttpOptions,      ## Returns the HTTP methods that the server supports
                      ## for specified address.
    HttpConnect,      ## Converts the request connection to a transparent
                      ## TCP/IP tunnel, usually used for proxies.
    HttpPatch         ## Applies partial modifications to a resource.


const
  Http100* = HttpCode(100)
  Http101* = HttpCode(101)
  Http200* = HttpCode(200)
  Http201* = HttpCode(201)
  Http202* = HttpCode(202)
  Http203* = HttpCode(203)
  Http204* = HttpCode(204)
  Http205* = HttpCode(205)
  Http206* = HttpCode(206)
  Http300* = HttpCode(300)
  Http301* = HttpCode(301)
  Http302* = HttpCode(302)
  Http303* = HttpCode(303)
  Http304* = HttpCode(304)
  Http305* = HttpCode(305)
  Http307* = HttpCode(307)
  Http400* = HttpCode(400)
  Http401* = HttpCode(401)
  Http403* = HttpCode(403)
  Http404* = HttpCode(404)
  Http405* = HttpCode(405)
  Http406* = HttpCode(406)
  Http407* = HttpCode(407)
  Http408* = HttpCode(408)
  Http409* = HttpCode(409)
  Http410* = HttpCode(410)
  Http411* = HttpCode(411)
  Http412* = HttpCode(412)
  Http413* = HttpCode(413)
  Http414* = HttpCode(414)
  Http415* = HttpCode(415)
  Http416* = HttpCode(416)
  Http417* = HttpCode(417)
  Http418* = HttpCode(418)
  Http421* = HttpCode(421)
  Http422* = HttpCode(422)
  Http426* = HttpCode(426)
  Http428* = HttpCode(428)
  Http429* = HttpCode(429)
  Http431* = HttpCode(431)
  Http451* = HttpCode(451)
  Http500* = HttpCode(500)
  Http501* = HttpCode(501)
  Http502* = HttpCode(502)
  Http503* = HttpCode(503)
  Http504* = HttpCode(504)
  Http505* = HttpCode(505)

const
  headerLimit* = 10_000 ## The limit of HTTP headers in bytes. This limit
                        ## is not enforced by httpcore but by modules using
                        ## httpcore.
  EmptyHttpHeaders* = HttpHeaders(nil) ## Constant that represents empty
                                       ## http headers.

template table*(x: HttpHeaders): TableRef[string, seq[string]] {.
    deprecated: "use the other accessor procs instead".} =
  TableRef[string, seq[string]](x)

proc newHttpHeaders*(): HttpHeaders =
  result = HttpHeaders newTable[string, seq[string]]()

proc newHttpHeaders*(keyValuePairs:
    openArray[tuple[key: string, val: string]]): HttpHeaders =
  result = HttpHeaders newTable[string, seq[string]]()
  for pair in keyValuePairs:
    HeadersImpl(result)[pair.key.toLowerAscii()] = @[pair.val]

proc `$`*(headers: HttpHeaders): string = $(HeadersImpl(headers))

proc isEmpty*(a: HttpHeaders): bool = HeadersImpl(a) == nil

proc clear*(headers: HttpHeaders) =
  HeadersImpl(headers).clear()

proc `[]`*(headers: HttpHeaders, key: string): HttpHeaderValues =
  ## Returns the values associated with the given ``key``. If the returned
  ## values are passed to a procedure expecting a ``string``, the first
  ## value is automatically picked. If there are
  ## no values associated with the key, an exception is raised.
  ##
  ## To access multiple values of a key, use the overloaded ``[]`` below or
  ## to get all of them access the ``table`` field directly.
  result = HeadersImpl(headers)[key.toLowerAscii].HttpHeaderValues

converter toString*(values: HttpHeaderValues): string =
  result = seq[string](values)[0]

proc `[]`*(headers: HttpHeaders, key: string, i: int): string =
  ## Returns the ``i``'th value associated with the given key. If there are
  ## no values associated with the key or the ``i``'th value doesn't exist,
  ## an exception is raised.
  result = HeadersImpl(headers)[key.toLowerAscii][i]

proc `[]=`*(headers: HttpHeaders, key, value: string) =
  ## Sets the header entries associated with ``key`` to the specified value.
  ## Replaces any existing values.
  HeadersImpl(headers)[key.toLowerAscii] = @[value]

proc `[]=`*(headers: HttpHeaders, key: string, value: seq[string]) =
  ## Sets the header entries associated with ``key`` to the specified list of
  ## values.
  ## Replaces any existing values.
  HeadersImpl(headers)[key.toLowerAscii] = value

proc add*(headers: HttpHeaders, key, value: string) =
  ## Adds the specified value to the specified key. Appends to any existing
  ## values associated with the key.
  let k = key.toLowerAscii
  if not HeadersImpl(headers).hasKey(k):
    HeadersImpl(headers)[k] = @[value]
  else:
    HeadersImpl(headers)[k].add(value)

proc del*(headers: HttpHeaders, key: string) =
  ## Delete the header entries associated with ``key``
  HeadersImpl(headers).del(key.toLowerAscii)

iterator pairs*(headers: HttpHeaders): tuple[key, value: string] =
  ## Yields each key, value pair.
  for k, v in HeadersImpl(headers):
    for value in v:
      yield (k, value)

proc contains*(values: HttpHeaderValues, value: string): bool =
  ## Determines if ``value`` is one of the values inside ``values``. Comparison
  ## is performed without case sensitivity.
  for val in seq[string](values):
    if val.toLowerAscii == value.toLowerAscii: return true

proc hasKey*(headers: HttpHeaders, key: string): bool =
  result = HeadersImpl(headers).hasKey(key.toLowerAscii())

proc getOrDefault*(headers: HttpHeaders, key: string,
    default = @[""].HttpHeaderValues): HttpHeaderValues =
  ## Returns the values associated with the given ``key``. If there are no
  ## values associated with the key, then ``default`` is returned.
  result = HttpHeaderValues(HeadersImpl(headers).getOrDefault(key.toLowerAscii, seq[string](default)))

proc len*(headers: HttpHeaders): int = result = HeadersImpl(headers).len

proc parseList(line: string, list: var seq[string], start: int): int =
  var i = 0
  var current = ""
  while start+i < line.len and line[start + i] notin {'\c', '\l'}:
    i += line.skipWhitespace(start + i)
    i += line.parseUntil(current, {'\c', '\l', ','}, start + i)
    list.add(current)
    if start+i < line.len and line[start + i] == ',':
      i.inc # Skip ,
    current.setLen(0)

proc parseHeader*(line: string): tuple[key: string, value: seq[string]] =
  ## Parses a single raw header HTTP line into key value pairs.
  ##
  ## Used by ``asynchttpserver`` and ``httpclient`` internally and should not
  ## be used by you.
  result.value = @[]
  var i = 0
  i = line.parseUntil(result.key, ':')
  inc(i) # skip :
  if i < len(line):
    i += parseList(line, result.value, i)
  elif result.key.len > 0:
    result.value = @[""]
  else:
    result.value = @[]

proc `==`*(protocol: tuple[orig: string, major, minor: int],
           ver: HttpVersion): bool =
  let major =
    case ver
    of HttpVer11, HttpVer10: 1
  let minor =
    case ver
    of HttpVer11: 1
    of HttpVer10: 0
  result = protocol.major == major and protocol.minor == minor

proc contains*(methods: set[HttpMethod], x: string): bool =
  result = parseEnum[HttpMethod](x) in methods

proc `$`*(code: HttpCode): string =
  ## Converts the specified ``HttpCode`` into a HTTP status.
  ##
  ## For example:
  ##
  ##   .. code-block:: nim
  ##       doAssert($Http404 == "404 Not Found")
  case code.int
  of 100: "100 Continue"
  of 101: "101 Switching Protocols"
  of 200: "200 OK"
  of 201: "201 Created"
  of 202: "202 Accepted"
  of 203: "203 Non-Authoritative Information"
  of 204: "204 No Content"
  of 205: "205 Reset Content"
  of 206: "206 Partial Content"
  of 300: "300 Multiple Choices"
  of 301: "301 Moved Permanently"
  of 302: "302 Found"
  of 303: "303 See Other"
  of 304: "304 Not Modified"
  of 305: "305 Use Proxy"
  of 307: "307 Temporary Redirect"
  of 400: "400 Bad Request"
  of 401: "401 Unauthorized"
  of 403: "403 Forbidden"
  of 404: "404 Not Found"
  of 405: "405 Method Not Allowed"
  of 406: "406 Not Acceptable"
  of 407: "407 Proxy Authentication Required"
  of 408: "408 Request Timeout"
  of 409: "409 Conflict"
  of 410: "410 Gone"
  of 411: "411 Length Required"
  of 412: "412 Precondition Failed"
  of 413: "413 Request Entity Too Large"
  of 414: "414 Request-URI Too Long"
  of 415: "415 Unsupported Media Type"
  of 416: "416 Requested Range Not Satisfiable"
  of 417: "417 Expectation Failed"
  of 418: "418 I'm a teapot"
  of 421: "421 Misdirected Request"
  of 422: "422 Unprocessable Entity"
  of 426: "426 Upgrade Required"
  of 428: "428 Precondition Required"
  of 429: "429 Too Many Requests"
  of 431: "431 Request Header Fields Too Large"
  of 451: "451 Unavailable For Legal Reasons"
  of 500: "500 Internal Server Error"
  of 501: "501 Not Implemented"
  of 502: "502 Bad Gateway"
  of 503: "503 Service Unavailable"
  of 504: "504 Gateway Timeout"
  of 505: "505 HTTP Version Not Supported"
  else: $(int(code))

proc `==`*(a, b: HttpCode): bool {.borrow.}

proc `==`*(rawCode: string, code: HttpCode): bool =
  result = cmpIgnoreCase(rawCode, $code) == 0

proc is2xx*(code: HttpCode): bool =
  ## Determines whether ``code`` is a 2xx HTTP status code.
  result = code.int in {200 .. 299}

proc is3xx*(code: HttpCode): bool =
  ## Determines whether ``code`` is a 3xx HTTP status code.
  result = code.int in {300 .. 399}

proc is4xx*(code: HttpCode): bool =
  ## Determines whether ``code`` is a 4xx HTTP status code.
  result = code.int in {400 .. 499}

proc is5xx*(code: HttpCode): bool =
  ## Determines whether ``code`` is a 5xx HTTP status code.
  result = code.int in {500 .. 599}

proc `$`*(httpMethod: HttpMethod): string =
  result = (system.`$`(httpMethod))[4 .. ^1].toUpperAscii()

when isMainModule:
  var test = newHttpHeaders()
  test["Connection"] = @["Upgrade", "Close"]
  doAssert test["Connection", 0] == "Upgrade"
  doAssert test["Connection", 1] == "Close"
  test.add("Connection", "Test")
  doAssert test["Connection", 2] == "Test"
  doAssert "upgrade" in test["Connection"]

  # Bug #5344.
  doAssert parseHeader("foobar: ") == ("foobar", @[""])
  let (key, value) = parseHeader("foobar: ")
  test = newHttpHeaders()
  test[key] = value
  doAssert test["foobar"] == ""

  doAssert parseHeader("foobar:") == ("foobar", @[""])
