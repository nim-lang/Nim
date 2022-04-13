#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements helper procs for parsing Cookies.

import strtabs, times, options


type
  SameSite* {.pure.} = enum ## The SameSite cookie attribute.
                            ## `Default` means that `setCookie`
                            ## proc will not set `SameSite` attribute.
    Default, None, Lax, Strict

proc parseCookies*(s: string): StringTableRef =
  ## Parses cookies into a string table.
  ##
  ## The proc is meant to parse the Cookie header set by a client, not the
  ## "Set-Cookie" header set by servers.
  runnableExamples:
    import std/strtabs
    let cookieJar = parseCookies("a=1; foo=bar")
    assert cookieJar["a"] == "1"
    assert cookieJar["foo"] == "bar"

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
                secure = false, httpOnly = false,
                maxAge = none(int), sameSite = SameSite.Default): string =
  ## Creates a command in the format of
  ## `Set-Cookie: key=value; Domain=...; ...`
  result = ""
  if not noName: result.add("Set-Cookie: ")
  result.add key & "=" & value
  if domain != "": result.add("; Domain=" & domain)
  if path != "": result.add("; Path=" & path)
  if expires != "": result.add("; Expires=" & expires)
  if secure: result.add("; Secure")
  if httpOnly: result.add("; HttpOnly")
  if maxAge.isSome: result.add("; Max-Age=" & $maxAge.unsafeGet)

  if sameSite != SameSite.Default:
    if sameSite == SameSite.None:
      doAssert secure, "Cookies with SameSite=None must specify the Secure attribute!"
    result.add("; SameSite=" & $sameSite)

proc setCookie*(key, value: string, expires: DateTime|Time,
                domain = "", path = "", noName = false,
                secure = false, httpOnly = false,
                maxAge = none(int), sameSite = SameSite.Default): string =
  ## Creates a command in the format of
  ## `Set-Cookie: key=value; Domain=...; ...`
  result = setCookie(key, value, domain, path,
                   format(expires.utc, "ddd',' dd MMM yyyy HH:mm:ss 'GMT'"),
                   noName, secure, httpOnly, maxAge, sameSite)
