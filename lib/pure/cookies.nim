#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements helper procs for parsing Cookies.

import strtabs, times

proc parseCookies*(s: string): StringTableRef =
  ## parses cookies into a string table.
  ##
  ## The proc is meant to parse the Cookie header set by a client, not the
  ## "Set-Cookie" header set by servers.
  ##
  ## Example:
  ##
  ## .. code-block::Nim
  ##     doAssert parseCookies("a=1; foo=bar") == {"a": 1, "foo": "bar"}.newStringTable

  result = newStringTable(modeCaseInsensitive)
  var i = 0
  while true:
    while i < s.len and (s[i] == ' ' or s[i] == '\t'): inc(i)
    var keystart = i
    while i < s.len and s[i] != '=': inc(i)
    var keyend = i-1
    if i >= s.len: break
    inc(i) # skip '='
    var valstart = i
    while i < s.len and s[i] != ';': inc(i)
    result[substr(s, keystart, keyend)] = substr(s, valstart, i-1)
    if i >= s.len: break
    inc(i) # skip ';'

proc setCookie*(key, value: string, domain = "", path = "",
                expires = "", noName = false,
                secure = false, httpOnly = false): string =
  ## Creates a command in the format of
  ## ``Set-Cookie: key=value; Domain=...; ...``
  result = ""
  if not noName: result.add("Set-Cookie: ")
  result.add key & "=" & value
  if domain != "": result.add("; Domain=" & domain)
  if path != "": result.add("; Path=" & path)
  if expires != "": result.add("; Expires=" & expires)
  if secure: result.add("; Secure")
  if httpOnly: result.add("; HttpOnly")

proc setCookie*(key, value: string, expires: DateTime|Time,
                domain = "", path = "", noName = false,
                secure = false, httpOnly = false): string =
  ## Creates a command in the format of
  ## ``Set-Cookie: key=value; Domain=...; ...``
  return setCookie(key, value, domain, path,
                   format(expires.utc, "ddd',' dd MMM yyyy HH:mm:ss 'GMT'"),
                   noname, secure, httpOnly)

when isMainModule:
  let expire = fromUnix(0) + 1.seconds

  let cookies = [
    setCookie("test", "value", expire),
    setCookie("test", "value", expire.local),
    setCookie("test", "value", expire.utc)
  ]
  let expected = "Set-Cookie: test=value; Expires=Thu, 01 Jan 1970 00:00:01 GMT"
  doAssert cookies == [expected, expected, expected]

  let table = parseCookies("uid=1; kp=2")
  doAssert table["uid"] == "1"
  doAssert table["kp"] == "2"
