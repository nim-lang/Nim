# Copyright (C) 2012 Dominik Picheta
# MIT License - Look at license.txt for details.
import parseutils, strtabs, strutils, tables, net, mimetypes, asyncdispatch, os
from cgi import decodeUrl

const
  useHttpBeast* = false # not defined(windows) and not defined(useStdLib)

type
  MultiData* = OrderedTable[string, tuple[fields: StringTableRef, body: string]]

  Settings* = ref object
    staticDir*: string # By default ./public
    appName*: string
    mimes*: MimeDb
    port*: Port
    bindAddr*: string
    reusePort*: bool
    futureErrorHandler*: proc (fut: Future[void]) {.closure, gcsafe.}

  JesterError* = object of Exception

proc parseUrlQuery*(query: string, result: var Table[string, string])
    {.deprecated: "use stdlib cgi/decodeData".} =
  var i = 0
  i = query.skip("?")
  while i < query.len()-1:
    var key = ""
    var val = ""
    i += query.parseUntil(key, '=', i)
    if query[i] != '=':
      raise newException(ValueError, "Expected '=' at " & $i &
                         " but got: " & $query[i])
    inc(i) # Skip =
    i += query.parseUntil(val, '&', i)
    inc(i) # Skip &
    result[decodeUrl(key)] = decodeUrl(val)

template parseContentDisposition(): typed =
  var hCount = 0
  while hCount < hValue.len()-1:
    var key = ""
    hCount += hValue.parseUntil(key, {';', '='}, hCount)
    if hValue[hCount] == '=':
      var value = hvalue.captureBetween('"', start = hCount)
      hCount += value.len+2
      inc(hCount) # Skip ;
      hCount += hValue.skipWhitespace(hCount)
      if key == "name": name = value
      newPart[0][key] = value
    else:
      inc(hCount)
      hCount += hValue.skipWhitespace(hCount)

proc parseMultiPart*(body: string, boundary: string): MultiData =
  result = initOrderedTable[string, tuple[fields: StringTableRef, body: string]]()
  var mboundary = "--" & boundary

  var i = 0
  var partsLeft = true
  while partsLeft:
    var firstBoundary = body.skip(mboundary, i)
    if firstBoundary == 0:
      raise newException(ValueError, "Expected boundary. Got: " & body.substr(i, i+25))
    i += firstBoundary
    i += body.skipWhitespace(i)

    # Headers
    var newPart: tuple[fields: StringTableRef, body: string] = ({:}.newStringTable, "")
    var name = ""
    while true:
      if body[i] == '\c':
        inc(i, 2) # Skip \c\L
        break
      var hName = ""
      i += body.parseUntil(hName, ':', i)
      if body[i] != ':':
        raise newException(ValueError, "Expected : in headers.")
      inc(i) # Skip :
      i += body.skipWhitespace(i)
      var hValue = ""
      i += body.parseUntil(hValue, {'\c', '\L'}, i)
      if toLowerAscii(hName) == "content-disposition":
        parseContentDisposition()
      newPart[0][hName] = hValue
      i += body.skip("\c\L", i) # Skip *one* \c\L

    # Parse body.
    while true:
      if body[i] == '\c' and body[i+1] == '\L' and
         body.skip(mboundary, i+2) != 0:
        if body.skip("--", i+2+mboundary.len) != 0:
          partsLeft = false
          break
        break
      else:
        newPart[1].add(body[i])
      inc(i)
    i += body.skipWhitespace(i)

    result.add(name, newPart)

proc parseMPFD*(contentType: string, body: string): MultiData =
  var boundaryEqIndex = contentType.find("boundary=")+9
  var boundary = contentType.substr(boundaryEqIndex, contentType.len()-1)
  return parseMultiPart(body, boundary)

proc parseCookies*(s: string): Table[string, string] =
  ## parses cookies into a string table.
  ##
  ## The proc is meant to parse the Cookie header set by a client, not the
  ## "Set-Cookie" header set by servers.

  result = initTable[string, string]()
  var i = 0
  while true:
    i += skipWhile(s, {' ', '\t'}, i)
    var keystart = i
    i += skipUntil(s, {'='}, i)
    var keyend = i-1
    if i >= len(s): break
    inc(i) # skip '='
    var valstart = i
    i += skipUntil(s, {';'}, i)
    result[substr(s, keystart, keyend)] = substr(s, valstart, i-1)
    if i >= len(s): break
    inc(i) # skip ';'

type
  SameSite* = enum
    None, Lax, Strict

proc makeCookie*(key, value, expires: string, domain = "", path = "",
                 secure = false, httpOnly = false,
                 sameSite = Lax): string =
  result = ""
  result.add key & "=" & value
  if domain != "": result.add("; Domain=" & domain)
  if path != "": result.add("; Path=" & path)
  if expires != "": result.add("; Expires=" & expires)
  if secure: result.add("; Secure")
  if httpOnly: result.add("; HttpOnly")
  if sameSite != None:
    result.add("; SameSite=" & $sameSite)

when not declared(tables.getOrDefault):
  template getOrDefault*(tab, key): untyped = tab[key]

when not declared(normalizePath) and not declared(normalizedPath):
  proc normalizePath*(path: var string) =
    ## Normalize a path.
    ##
    ## Consecutive directory separators are collapsed, including an initial double slash.
    ##
    ## On relative paths, double dot (..) sequences are collapsed if possible.
    ## On absolute paths they are always collapsed.
    ##
    ## Warning: URL-encoded and Unicode attempts at directory traversal are not detected.
    ## Triple dot is not handled.
    let isAbs = isAbsolute(path)
    var stack: seq[string] = @[]
    for p in split(path, {DirSep}):
      case p
      of "", ".":
        continue
      of "..":
        if stack.len == 0:
          if isAbs:
            discard  # collapse all double dots on absoluta paths
          else:
            stack.add(p)
        elif stack[^1] == "..":
          stack.add(p)
        else:
          discard stack.pop()
      else:
        stack.add(p)

    if isAbs:
      path = DirSep & join(stack, $DirSep)
    elif stack.len > 0:
      path = join(stack, $DirSep)
    else:
      path = "."

  proc normalizedPath*(path: string): string =
    ## Returns a normalized path for the current OS. See `<#normalizePath>`_
    result = path
    normalizePath(result)

when false:
  var r = {:}.newStringTable
  parseUrlQuery("FirstName=Mickey", r)
  echo r
