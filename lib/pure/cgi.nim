#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements helper procs for CGI applications. Example:
##
## .. code-block:: Nim
##
##    import strtabs, cgi
##
##    # Fill the values when debugging:
##    when debug:
##      setTestData("name", "Klaus", "password", "123456")
##    # read the data into `myData`
##    var myData = readData()
##    # check that the data's variable names are "name" or "password"
##    validateData(myData, "name", "password")
##    # start generating content:
##    writeContentType()
##    # generate content:
##    write(stdout, "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\">\n")
##    write(stdout, "<html><head><title>Test</title></head><body>\n")
##    writeLine(stdout, "your name: " & myData["name"])
##    writeLine(stdout, "your password: " & myData["password"])
##    writeLine(stdout, "</body></html>")

import strutils, os, strtabs, cookies, uri
export uri.encodeUrl, uri.decodeUrl

include includes/decode_helpers

proc addXmlChar(dest: var string, c: char) {.inline.} =
  case c
  of '&': add(dest, "&amp;")
  of '<': add(dest, "&lt;")
  of '>': add(dest, "&gt;")
  of '\"': add(dest, "&quot;")
  else: add(dest, c)

proc xmlEncode*(s: string): string =
  ## Encodes a value to be XML safe:
  ## * ``"`` is replaced by ``&quot;``
  ## * ``<`` is replaced by ``&lt;``
  ## * ``>`` is replaced by ``&gt;``
  ## * ``&`` is replaced by ``&amp;``
  ## * every other character is carried over.
  result = newStringOfCap(s.len + s.len shr 2)
  for i in 0..len(s)-1: addXmlChar(result, s[i])

type
  CgiError* = object of IOError ## exception that is raised if a CGI error occurs
  RequestMethod* = enum ## the used request method
    methodNone,         ## no REQUEST_METHOD environment variable
    methodPost,         ## query uses the POST method
    methodGet           ## query uses the GET method

proc cgiError*(msg: string) {.noreturn.} =
  ## raises an ECgi exception with message `msg`.
  var e: ref CgiError
  new(e)
  e.msg = msg
  raise e

proc getEncodedData(allowedMethods: set[RequestMethod]): string =
  case getEnv("REQUEST_METHOD").string
  of "POST":
    if methodPost notin allowedMethods:
      cgiError("'REQUEST_METHOD' 'POST' is not supported")
    var L = parseInt(getEnv("CONTENT_LENGTH").string)
    if L == 0:
      return ""
    result = newString(L)
    if readBuffer(stdin, addr(result[0]), L) != L:
      cgiError("cannot read from stdin")
  of "GET":
    if methodGet notin allowedMethods:
      cgiError("'REQUEST_METHOD' 'GET' is not supported")
    result = getEnv("QUERY_STRING").string
  else:
    if methodNone notin allowedMethods:
      cgiError("'REQUEST_METHOD' must be 'POST' or 'GET'")

iterator decodeData*(data: string): tuple[key, value: TaintedString] =
  ## Reads and decodes CGI data and yields the (name, value) pairs the
  ## data consists of.
  proc parseData(data: string, i: int, field: var string): int =
    result = i
    while result < data.len:
      case data[result]
      of '%': add(field, decodePercent(data, result))
      of '+': add(field, ' ')
      of '=', '&': break
      else: add(field, data[result])
      inc(result)

  var i = 0
  var name = ""
  var value = ""
  # decode everything in one pass:
  while i < data.len:
    setLen(name, 0) # reuse memory
    i = parseData(data, i, name)
    if i >= data.len or data[i] != '=': cgiError("'=' expected")
    inc(i) # skip '='
    setLen(value, 0) # reuse memory
    i = parseData(data, i, value)
    yield (name.TaintedString, value.TaintedString)
    if i < data.len:
      if data[i] == '&': inc(i)
      else: cgiError("'&' expected")

iterator decodeData*(allowedMethods: set[RequestMethod] =
       {methodNone, methodPost, methodGet}): tuple[key, value: TaintedString] =
  ## Reads and decodes CGI data and yields the (name, value) pairs the
  ## data consists of. If the client does not use a method listed in the
  ## `allowedMethods` set, an `ECgi` exception is raised.
  let data = getEncodedData(allowedMethods)
  for key, value in decodeData(data):
    yield (key, value)

proc readData*(allowedMethods: set[RequestMethod] =
               {methodNone, methodPost, methodGet}): StringTableRef =
  ## Read CGI data. If the client does not use a method listed in the
  ## `allowedMethods` set, an `ECgi` exception is raised.
  result = newStringTable()
  for name, value in decodeData(allowedMethods):
    result[name.string] = value.string

proc readData*(data: string): StringTableRef =
  ## Read CGI data from a string.
  result = newStringTable()
  for name, value in decodeData(data):
    result[name.string] = value.string

proc validateData*(data: StringTableRef, validKeys: varargs[string]) =
  ## validates data; raises `ECgi` if this fails. This checks that each variable
  ## name of the CGI `data` occurs in the `validKeys` array.
  for key, val in pairs(data):
    if find(validKeys, key) < 0:
      cgiError("unknown variable name: " & key)

proc getContentLength*(): string =
  ## returns contents of the ``CONTENT_LENGTH`` environment variable
  return getEnv("CONTENT_LENGTH").string

proc getContentType*(): string =
  ## returns contents of the ``CONTENT_TYPE`` environment variable
  return getEnv("CONTENT_Type").string

proc getDocumentRoot*(): string =
  ## returns contents of the ``DOCUMENT_ROOT`` environment variable
  return getEnv("DOCUMENT_ROOT").string

proc getGatewayInterface*(): string =
  ## returns contents of the ``GATEWAY_INTERFACE`` environment variable
  return getEnv("GATEWAY_INTERFACE").string

proc getHttpAccept*(): string =
  ## returns contents of the ``HTTP_ACCEPT`` environment variable
  return getEnv("HTTP_ACCEPT").string

proc getHttpAcceptCharset*(): string =
  ## returns contents of the ``HTTP_ACCEPT_CHARSET`` environment variable
  return getEnv("HTTP_ACCEPT_CHARSET").string

proc getHttpAcceptEncoding*(): string =
  ## returns contents of the ``HTTP_ACCEPT_ENCODING`` environment variable
  return getEnv("HTTP_ACCEPT_ENCODING").string

proc getHttpAcceptLanguage*(): string =
  ## returns contents of the ``HTTP_ACCEPT_LANGUAGE`` environment variable
  return getEnv("HTTP_ACCEPT_LANGUAGE").string

proc getHttpConnection*(): string =
  ## returns contents of the ``HTTP_CONNECTION`` environment variable
  return getEnv("HTTP_CONNECTION").string

proc getHttpCookie*(): string =
  ## returns contents of the ``HTTP_COOKIE`` environment variable
  return getEnv("HTTP_COOKIE").string

proc getHttpHost*(): string =
  ## returns contents of the ``HTTP_HOST`` environment variable
  return getEnv("HTTP_HOST").string

proc getHttpReferer*(): string =
  ## returns contents of the ``HTTP_REFERER`` environment variable
  return getEnv("HTTP_REFERER").string

proc getHttpUserAgent*(): string =
  ## returns contents of the ``HTTP_USER_AGENT`` environment variable
  return getEnv("HTTP_USER_AGENT").string

proc getPathInfo*(): string =
  ## returns contents of the ``PATH_INFO`` environment variable
  return getEnv("PATH_INFO").string

proc getPathTranslated*(): string =
  ## returns contents of the ``PATH_TRANSLATED`` environment variable
  return getEnv("PATH_TRANSLATED").string

proc getQueryString*(): string =
  ## returns contents of the ``QUERY_STRING`` environment variable
  return getEnv("QUERY_STRING").string

proc getRemoteAddr*(): string =
  ## returns contents of the ``REMOTE_ADDR`` environment variable
  return getEnv("REMOTE_ADDR").string

proc getRemoteHost*(): string =
  ## returns contents of the ``REMOTE_HOST`` environment variable
  return getEnv("REMOTE_HOST").string

proc getRemoteIdent*(): string =
  ## returns contents of the ``REMOTE_IDENT`` environment variable
  return getEnv("REMOTE_IDENT").string

proc getRemotePort*(): string =
  ## returns contents of the ``REMOTE_PORT`` environment variable
  return getEnv("REMOTE_PORT").string

proc getRemoteUser*(): string =
  ## returns contents of the ``REMOTE_USER`` environment variable
  return getEnv("REMOTE_USER").string

proc getRequestMethod*(): string =
  ## returns contents of the ``REQUEST_METHOD`` environment variable
  return getEnv("REQUEST_METHOD").string

proc getRequestURI*(): string =
  ## returns contents of the ``REQUEST_URI`` environment variable
  return getEnv("REQUEST_URI").string

proc getScriptFilename*(): string =
  ## returns contents of the ``SCRIPT_FILENAME`` environment variable
  return getEnv("SCRIPT_FILENAME").string

proc getScriptName*(): string =
  ## returns contents of the ``SCRIPT_NAME`` environment variable
  return getEnv("SCRIPT_NAME").string

proc getServerAddr*(): string =
  ## returns contents of the ``SERVER_ADDR`` environment variable
  return getEnv("SERVER_ADDR").string

proc getServerAdmin*(): string =
  ## returns contents of the ``SERVER_ADMIN`` environment variable
  return getEnv("SERVER_ADMIN").string

proc getServerName*(): string =
  ## returns contents of the ``SERVER_NAME`` environment variable
  return getEnv("SERVER_NAME").string

proc getServerPort*(): string =
  ## returns contents of the ``SERVER_PORT`` environment variable
  return getEnv("SERVER_PORT").string

proc getServerProtocol*(): string =
  ## returns contents of the ``SERVER_PROTOCOL`` environment variable
  return getEnv("SERVER_PROTOCOL").string

proc getServerSignature*(): string =
  ## returns contents of the ``SERVER_SIGNATURE`` environment variable
  return getEnv("SERVER_SIGNATURE").string

proc getServerSoftware*(): string =
  ## returns contents of the ``SERVER_SOFTWARE`` environment variable
  return getEnv("SERVER_SOFTWARE").string

proc setTestData*(keysvalues: varargs[string]) =
  ## fills the appropriate environment variables to test your CGI application.
  ## This can only simulate the 'GET' request method. `keysvalues` should
  ## provide embedded (name, value)-pairs. Example:
  ##
  ## .. code-block:: Nim
  ##    setTestData("name", "Hanz", "password", "12345")
  putEnv("REQUEST_METHOD", "GET")
  var i = 0
  var query = ""
  while i < keysvalues.len:
    add(query, encodeUrl(keysvalues[i]))
    add(query, '=')
    add(query, encodeUrl(keysvalues[i+1]))
    add(query, '&')
    inc(i, 2)
  putEnv("QUERY_STRING", query)

proc writeContentType*() =
  ## call this before starting to send your HTML data to `stdout`. This
  ## implements this part of the CGI protocol:
  ##
  ## .. code-block:: Nim
  ##     write(stdout, "Content-type: text/html\n\n")
  write(stdout, "Content-type: text/html\n\n")

proc resetForStacktrace() =
  stdout.write """<!--: spam
Content-Type: text/html

<body bgcolor=#f0f0f8><font color=#f0f0f8 size=-5> -->
<body bgcolor=#f0f0f8><font color=#f0f0f8 size=-5> --> -->
</font> </font> </font> </script> </object> </blockquote> </pre>
</table> </table> </table> </table> </table> </font> </font> </font>
"""

proc writeErrorMessage*(data: string) =
  ## Tries to reset browser state and writes `data` to stdout in
  ## <plaintext> tag.
  resetForStacktrace()
  # We use <plaintext> here, instead of escaping, so stacktrace can
  # be understood by human looking at source.
  stdout.write("<plaintext>\n")
  stdout.write(data)

proc setStackTraceStdout*() =
  ## Makes Nim output stacktraces to stdout, instead of server log.
  errorMessageWriter = writeErrorMessage

proc setCookie*(name, value: string) =
  ## Sets a cookie.
  write(stdout, "Set-Cookie: ", name, "=", value, "\n")

var
  gcookies {.threadvar.}: StringTableRef

proc getCookie*(name: string): TaintedString =
  ## Gets a cookie. If no cookie of `name` exists, "" is returned.
  if gcookies == nil: gcookies = parseCookies(getHttpCookie())
  result = TaintedString(gcookies.getOrDefault(name))

proc existsCookie*(name: string): bool =
  ## Checks if a cookie of `name` exists.
  if gcookies == nil: gcookies = parseCookies(getHttpCookie())
  result = hasKey(gcookies, name)
