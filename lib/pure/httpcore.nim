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
  HttpHeaders* = ref object
    table*: TableRef[string, seq[string]]

  HttpHeaderValues* = distinct seq[string]

  HttpCode* = enum
    Http100 = "100 Continue",
    Http101 = "101 Switching Protocols",
    Http200 = "200 OK",
    Http201 = "201 Created",
    Http202 = "202 Accepted",
    Http204 = "204 No Content",
    Http205 = "205 Reset Content",
    Http206 = "206 Partial Content",
    Http300 = "300 Multiple Choices",
    Http301 = "301 Moved Permanently",
    Http302 = "302 Found",
    Http303 = "303 See Other",
    Http304 = "304 Not Modified",
    Http305 = "305 Use Proxy",
    Http307 = "307 Temporary Redirect",
    Http400 = "400 Bad Request",
    Http401 = "401 Unauthorized",
    Http403 = "403 Forbidden",
    Http404 = "404 Not Found",
    Http405 = "405 Method Not Allowed",
    Http406 = "406 Not Acceptable",
    Http407 = "407 Proxy Authentication Required",
    Http408 = "408 Request Timeout",
    Http409 = "409 Conflict",
    Http410 = "410 Gone",
    Http411 = "411 Length Required",
    Http412 = "412 Precondition Failed",
    Http413 = "413 Request Entity Too Large",
    Http414 = "414 Request-URI Too Long",
    Http415 = "415 Unsupported Media Type",
    Http416 = "416 Requested Range Not Satisfiable",
    Http417 = "417 Expectation Failed",
    Http418 = "418 I'm a teapot",
    Http500 = "500 Internal Server Error",
    Http501 = "501 Not Implemented",
    Http502 = "502 Bad Gateway",
    Http503 = "503 Service Unavailable",
    Http504 = "504 Gateway Timeout",
    Http505 = "505 HTTP Version Not Supported"

  HttpVersion* = enum
    HttpVer11,
    HttpVer10

const headerLimit* = 10_000

proc newHttpHeaders*(): HttpHeaders =
  new result
  result.table = newTable[string, seq[string]]()

proc newHttpHeaders*(keyValuePairs:
    openarray[tuple[key: string, val: string]]): HttpHeaders =
  var pairs: seq[tuple[key: string, val: seq[string]]] = @[]
  for pair in keyValuePairs:
    pairs.add((pair.key.toLower(), @[pair.val]))
  new result
  result.table = newTable[string, seq[string]](pairs)

proc clear*(headers: HttpHeaders) =
  headers.table.clear()

proc `[]`*(headers: HttpHeaders, key: string): HttpHeaderValues =
  ## Returns the values associated with the given ``key``. If the returned
  ## values are passed to a procedure expecting a ``string``, the first
  ## value is automatically picked. If there are
  ## no values associated with the key, an exception is raised.
  ##
  ## To access multiple values of a key, use the overloaded ``[]`` below or
  ## to get all of them access the ``table`` field directly.
  return headers.table[key.toLower].HttpHeaderValues

converter toString*(values: HttpHeaderValues): string =
  return seq[string](values)[0]

proc `[]`*(headers: HttpHeaders, key: string, i: int): string =
  ## Returns the ``i``'th value associated with the given key. If there are
  ## no values associated with the key or the ``i``'th value doesn't exist,
  ## an exception is raised.
  return headers.table[key.toLower][i]

proc `[]=`*(headers: HttpHeaders, key, value: string) =
  ## Sets the header entries associated with ``key`` to the specified value.
  ## Replaces any existing values.
  headers.table[key.toLower] = @[value]

proc `[]=`*(headers: HttpHeaders, key: string, value: seq[string]) =
  ## Sets the header entries associated with ``key`` to the specified list of
  ## values.
  ## Replaces any existing values.
  headers.table[key.toLower] = value

proc add*(headers: HttpHeaders, key, value: string) =
  ## Adds the specified value to the specified key. Appends to any existing
  ## values associated with the key.
  if not headers.table.hasKey(key.toLower):
    headers.table[key.toLower] = @[value]
  else:
    headers.table[key.toLower].add(value)

iterator pairs*(headers: HttpHeaders): tuple[key, value: string] =
  ## Yields each key, value pair.
  for k, v in headers.table:
    for value in v:
      yield (k, value)

proc contains*(values: HttpHeaderValues, value: string): bool =
  ## Determines if ``value`` is one of the values inside ``values``. Comparison
  ## is performed without case sensitivity.
  for val in seq[string](values):
    if val.toLower == value.toLower: return true

proc hasKey*(headers: HttpHeaders, key: string): bool =
  return headers.table.hasKey(key.toLower())

proc getOrDefault*(headers: HttpHeaders, key: string,
    default = @[""].HttpHeaderValues): HttpHeaderValues =
  ## Returns the values associated with the given ``key``. If there are no
  ## values associated with the key, then ``default`` is returned.
  if headers.hasKey(key):
    return headers[key]
  else:
    return default

proc len*(headers: HttpHeaders): int = return headers.table.len

proc parseList(line: string, list: var seq[string], start: int): int =
  var i = 0
  var current = ""
  while line[start + i] notin {'\c', '\l', '\0'}:
    i += line.skipWhitespace(start + i)
    i += line.parseUntil(current, {'\c', '\l', ','}, start + i)
    list.add(current)
    if line[start + i] == ',':
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

when isMainModule:
  var test = newHttpHeaders()
  test["Connection"] = @["Upgrade", "Close"]
  doAssert test["Connection", 0] == "Upgrade"
  doAssert test["Connection", 1] == "Close"
  test.add("Connection", "Test")
  doAssert test["Connection", 2] == "Test"
  doAssert "upgrade" in test["Connection"]
